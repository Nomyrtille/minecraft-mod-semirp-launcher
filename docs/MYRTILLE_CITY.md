# Mettre le launcher en service pour Myrtille City

Ce document liste ce qu'il faut faire, dans l'ordre, pour passer du fork personnalisé à un
launcher que les joueurs installent. Les étapes 1 et 4 ne peuvent être faites que par le
propriétaire du compte (Microsoft, Apple, achat de certificat).

| Étape | Qui | Bloque |
|---|---|---|
| 1. Application Azure + approbation Mojang | propriétaire | la connexion des comptes |
| 2. Pack Fabric et `distribution.json` (Nebula) | équipe | le téléchargement du jeu |
| 3. Hébergement du pack derrière le tunnel Cloudflare | propriétaire du serveur maison | le téléchargement du jeu |
| 4. Signature de code (Windows, macOS) | propriétaire | les alertes « application inconnue » |
| 5. Publication d'une version | équipe | la distribution aux joueurs |

## 1. Application Azure et approbation Mojang

Le launcher connecte les joueurs avec leur compte Microsoft. Il lui faut **sa propre** application
Azure : l'identifiant de Helios appartient à son auteur et ne doit pas être diffusé sous notre nom.

1. Créer l'application en suivant [`MicrosoftAuth.md`](MicrosoftAuth.md) : comptes de tout
   annuaire **et** comptes Microsoft personnels, plateforme « Mobile and desktop applications »
   avec l'URI de redirection `https://login.microsoftonline.com/common/oauth2/nativeclient`, et un
   secret client (exigé par Microsoft, mais jamais utilisé ni copié).
2. Mettre l'« Application (client) ID » dans `AZURE_CLIENT_ID`
   (`app/assets/js/ipcconstants.js`) : c'est fait, `9d60b95b-110e-446c-85fe-d6d85b9a1852`. Cet
   identifiant n'est pas un secret : il est lisible dans tout launcher distribué.
3. Lancer `npm start` et **tenter une connexion** : elle échoue, c'est normal, mais Microsoft
   exige cette activité avant d'étudier la demande.
4. Remplir le [formulaire de Mojang](https://aka.ms/mce-reviewappid) avec l'identifiant client et
   l'identifiant de tenant (page « Overview » du portail Azure). Après l'approbation, compter
   jusqu'à 24 h avant que la connexion fonctionne.

## 2. Le pack client et son `distribution.json`

Le `distribution.json` décrit le serveur et tous les fichiers à installer. On le produit avec
[Nebula](https://github.com/dscalzi/Nebula) (MIT), qui calcule les tailles et les empreintes.

Contenu du pack :

| Élément | Type de module | Remarque |
|---|---|---|
| Fabric Loader pour Minecraft 26.2 | `Fabric` | Nebula génère aussi son `VersionManifest` |
| Fabric API | `FabricMod` (obligatoire) | dépendance de Simple Voice Chat |
| Simple Voice Chat | `FabricMod` (obligatoire) | même version majeure que le plugin du serveur |
| Un mod d'optimisation (Sodium) | `FabricMod` (facultatif) | le joueur peut le désactiver |
| Resource pack Myrtille City | `File` | vers `resourcepacks/` |

Points à ne pas manquer dans l'entrée du serveur :

- **Java 25.** Minecraft 26.x exige Java 25, mais le launcher choisit Java 21 par défaut pour
  toute version postérieure à 1.20.5. Il faut donc l'indiquer :
  ```json
  "javaOptions": { "supported": ">=25.x", "suggestedMajor": 25 }
  ```
- `"minecraftVersion": "26.2"`, `"mainServer": true`, `"autoconnect": true`.
- `"address"` : l'adresse publique du serveur Minecraft. Elle figure dans le `distribution.json`
  servi aux joueurs, pas dans ce dépôt.
- Le champ `discord` (Rich Presence) est facultatif : il faut une application Discord dédiée.

Exemple de la partie propre au serveur (les modules sont générés par Nebula) :

```json
{
  "version": "1.0.0",
  "rss": "",
  "servers": [
    {
      "id": "myrtille-city-s1",
      "name": "Myrtille City",
      "description": "Serveur semi-RP : civil, police ou mafia. Saison 1.",
      "icon": "https://<hôte-du-pack>/files/icon.png",
      "version": "1.0.0",
      "address": "<adresse-publique>:25565",
      "minecraftVersion": "26.2",
      "mainServer": true,
      "autoconnect": true,
      "javaOptions": { "supported": ">=25.x", "suggestedMajor": 25 },
      "modules": []
    }
  ]
}
```

### Construire le pack en une commande

La liste des mods est versionnée dans [`pack/mods.tsv`](../pack/mods.tsv) : un changement de pack
passe par une PR. [`tools/build-pack.sh`](../tools/build-pack.sh) fait le reste : il clone Nebula,
crée le serveur Fabric, télécharge depuis Modrinth la dernière version publiée de chaque mod pour
Minecraft 26.2, ajoute le resource pack et l'icône, remplit `servermeta.json`, génère le
`distribution.json` et y ajoute Java 25.

```bash
ROOT=~/myrtille-pack BASE_URL=https://pack.<ton-domaine>/ SERVER_ADDRESS=<adresse-publique>:25565 \
RESOURCE_PACK=~/MyrtilleCity-resourcepack.zip PACK_VERSION=1.0.0 ./tools/build-pack.sh
```

Prérequis : Node.js 22, Java 17 ou plus, git, curl et jq. Le script s'arrête si un mod n'a pas
encore de version pour Minecraft 26.2 : on ne monte pas de version tant que le pack n'est pas
complet.

Le dossier `ROOT` (les fichiers du pack) se range sur le serveur maison, pas dans ce dépôt public.
À chaque changement du pack, relancer le script avec un `PACK_VERSION` plus grand : le launcher
revérifie alors tous les fichiers.

## Images du launcher

Le logo (une grappe de myrtilles), les icônes, l'écran de chargement et les fonds (la ville la nuit)
sont dessinés par [`tools/branding.py`](../tools/branding.py), sans asset extérieur :
`pip install pillow && python tools/branding.py`. Pour passer aux visuels définitifs, remplacer les
fichiers en gardant leurs noms (`app/assets/images/`, `build/icon.png`).

## 3. Héberger le pack

Le `distribution.json` et les fichiers du pack sont servis en HTTPS par le serveur maison, derrière
le tunnel Cloudflare déjà prévu pour le site (aucun port ouvert sur la box). Un simple serveur de
fichiers statiques suffit (Caddy ou nginx dans Docker).

Le pack est publié sur `https://pack.nomyrtille.com/distribution.json`, l'adresse inscrite dans
`app/assets/js/distromanager.js` (`REMOTE_DISTRO_URL`). Le launcher garde une copie locale du dernier index : un
joueur déjà installé peut lancer le jeu même si l'hébergement du pack est coupé, mais pas un
nouveau joueur.

## 4. Signature de code

Sans signature, Windows SmartScreen affiche « Windows a protégé votre ordinateur » et macOS refuse
d'ouvrir l'application sans clic droit → Ouvrir.

- **Windows** : un certificat de signature de code (ou Azure Trusted Signing). À fournir à
  electron-builder par les secrets du dépôt `CSC_LINK` et `CSC_KEY_PASSWORD`.
- **macOS** : un compte Apple Developer (payant, par an) pour signer et notariser. Secrets
  `CSC_LINK`, `CSC_KEY_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`.
- **Linux** : l'AppImage n'a pas besoin de signature.

Pour le test fermé, on peut s'en passer et expliquer la manipulation aux testeurs.

## 5. Publier une version

Le workflow `.github/workflows/build.yml` construit les installateurs Windows, macOS (Intel et
Apple Silicon) et Linux :

- **à chaque push** sur une branche, ou lancé à la main (Actions → Build → Run workflow) : les
  installateurs sont gardés 7 jours en artefacts du run, pour tester. Rien n'est publié ;
- **sur un tag `vX.Y.Z`** : ils sont publiés dans la release GitHub du tag. Le tag doit
  correspondre à `version` dans `package.json`, sinon le build s'arrête.

Les fichiers portent toujours le même nom (`MyrtilleCity-Setup.exe`, `MyrtilleCity-arm64.dmg`,
`MyrtilleCity-x64.dmg`, `MyrtilleCity.AppImage`). La page de téléchargement pointe donc vers
`releases/latest/download/<nom>` et sert toujours la dernière version.

1. Sur une branche, augmenter `version` dans `package.json` (ex. `0.1.0` → `0.2.0`), puis faire
   relire et fusionner la PR.
2. C'est tout : le serveur maison voit la nouvelle version, pousse le tag `v0.2.0`, et le build
   publie la release. Le résultat est annoncé dans `#logs` sur Discord. Un tag poussé à la main
   (`git tag v0.2.0 && git push origin v0.2.0`) marche aussi.
3. La release est publique dès la fin du build. Les launchers Windows et Linux déjà installés se mettent à jour
   seuls ; sous macOS, le launcher propose de télécharger le nouveau dmg.

Le dépôt étant public, les minutes de GitHub Actions sont gratuites.

## 6. Page de téléchargement

Les joueurs passent par l'assistant d'installation du site : https://myrtillecity.nomyrtille.com/jouer/
(dépôt `myrtille-city-site`, fichier `src/pages/jouer.astro`). Il pointe vers
`releases/latest/download/<nom>` : rien à changer à chaque version.

## Récupérer les correctifs de Helios

```bash
git remote add upstream https://github.com/dscalzi/HeliosLauncher.git   # une fois
git fetch upstream
git checkout -b chore/sync-upstream
git merge upstream/master
```

Conflits attendus : `package.json`, `electron-builder.yml` et `app/assets/lang/_custom.toml`.
Garder nos valeurs, puis reporter dans `fr_FR.toml` les clés ajoutées à `en_US.toml`.
