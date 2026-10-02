#!/usr/bin/env bash
# Construit le pack client et son distribution.json avec Nebula, prêt à servir en fichiers statiques.
#
#   ROOT=~/myrtille-pack BASE_URL=https://pack.exemple.fr/ SERVER_ADDRESS=jeu.exemple.fr:25565 \
#   RESOURCE_PACK=~/MyrtilleCity-resourcepack.zip ./tools/build-pack.sh
#
# Prérequis : Node.js 22, Java 17+, git, curl, jq. Réseau : github.com, api.modrinth.com,
# cdn.modrinth.com, meta.fabricmc.net, maven.fabricmc.net, piston-meta.mojang.com.
# Le dossier ROOT se publie tel quel derrière le tunnel Cloudflare (BASE_URL pointe dessus).
set -euo pipefail
cd "$(dirname "$0")/.."

: "${ROOT:?ROOT : dossier de sortie du pack}"
: "${BASE_URL:?BASE_URL : adresse publique de ROOT, terminée par /}"
: "${SERVER_ADDRESS:?SERVER_ADDRESS : adresse du serveur Minecraft, ex. jeu.exemple.fr:25565}"
MC_VERSION="${MC_VERSION:-26.2}"
SERVER_ID="${SERVER_ID:-myrtille-city}"
PACK_VERSION="${PACK_VERSION:-1.0.0}"
NEBULA_REF="${NEBULA_REF:-master}"
JAVA_EXECUTABLE="${JAVA_EXECUTABLE:-$(command -v java)}"

for tool in node npm git curl jq; do
    command -v "$tool" >/dev/null || { echo "Outil manquant : $tool" >&2; exit 1; }
done

NEBULA=".cache/Nebula"
if [ ! -d "$NEBULA" ]; then
    git clone --depth 1 --branch "$NEBULA_REF" https://github.com/dscalzi/Nebula.git "$NEBULA"
fi
mkdir -p "$ROOT"
ROOT="$(cd "$ROOT" && pwd)"
cat > "$NEBULA/.env" <<ENV
JAVA_EXECUTABLE=$JAVA_EXECUTABLE
ROOT=$ROOT
BASE_URL=$BASE_URL
HELIOS_DATA_FOLDER=$ROOT/.helios
ENV
nebula() { (cd "$NEBULA" && npm run --silent faststart -- "$@"); }
(cd "$NEBULA" && npm ci --silent && npm run --silent build)

SERVER_DIR="$ROOT/servers/$SERVER_ID-$MC_VERSION"
if [ ! -d "$ROOT/servers" ]; then
    nebula init root
fi
if [ ! -d "$SERVER_DIR" ]; then
    nebula generate server "$SERVER_ID" "$MC_VERSION" --fabric latest
fi

echo "==> Mods ($MC_VERSION, Fabric) depuis Modrinth"
for folder in required optionalon optionaloff; do
    mkdir -p "$SERVER_DIR/fabricmods/$folder"
    rm -f "$SERVER_DIR/fabricmods/$folder"/*.jar
done
grep -v '^#' pack/mods.tsv | while IFS=$'\t' read -r slug folder _; do
    [ -n "$slug" ] || continue
    versions=$(curl -sfG "https://api.modrinth.com/v2/project/$slug/version" \
        --data-urlencode "game_versions=[\"$MC_VERSION\"]" --data-urlencode 'loaders=["fabric"]')
    file=$(jq -c 'first(.[] | select(.version_type == "release")) // {files: []}
                  | first(.files[] | select(.primary)) // .files[0] // {}' <<<"${versions:-[]}")
    url=$(jq -r '.url // empty' <<<"$file")
    # Le nom vient de Modrinth et pas de l'URL : l'URL est encodée (« + » → « %2B ») et Nebula
    # publierait alors un lien vers un fichier introuvable.
    name=$(jq -r '.filename // empty' <<<"$file")
    if [ -z "$url" ]; then
        echo "Pas de version publiée de $slug pour Fabric $MC_VERSION : on ne monte pas de version tant que le pack n'est pas complet." >&2
        exit 1
    fi
    echo "  $slug → $folder"
    curl -sfL "$url" -o "$SERVER_DIR/fabricmods/$folder/${name:-$(basename "$url")}"
done

if [ -n "${RESOURCE_PACK:-}" ]; then
    mkdir -p "$SERVER_DIR/files/resourcepacks"
    cp "$RESOURCE_PACK" "$SERVER_DIR/files/resourcepacks/MyrtilleCity.zip"
fi
if [ -f build/icon.png ]; then
    cp build/icon.png "$SERVER_DIR/$SERVER_ID.png"
fi

echo "==> Métadonnées du serveur"
meta="$SERVER_DIR/servermeta.json"
jq --arg v "$PACK_VERSION" --arg addr "$SERVER_ADDRESS" '
    .meta.version = $v
  | .meta.name = "Myrtille City"
  | .meta.description = "Serveur semi-RP : civil, police ou mafia."
  | .meta.address = $addr
  | .meta.mainServer = true
  | .meta.autoconnect = true
  | .meta.discord = { shortId: "Myrtille City", largeImageText: "Myrtille City", largeImageKey: "seal-circle" }' \
    "$meta" > "$meta.tmp" && mv "$meta.tmp" "$meta"

echo "==> distribution.json"
nebula generate distro
# Minecraft 26.x exige Java 25 : le launcher choisirait Java 21 par défaut.
jq '(.servers[] | .javaOptions) = { supported: ">=25.x", suggestedMajor: 25 }' "$ROOT/distribution.json" \
    > "$ROOT/distribution.json.tmp" && mv "$ROOT/distribution.json.tmp" "$ROOT/distribution.json"

echo "Pack prêt dans $ROOT. À servir à l'adresse $BASE_URL (distribution.json : ${BASE_URL}distribution.json)."
