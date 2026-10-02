# Launcher Myrtille City

Launcher du serveur Minecraft semi-RP **Myrtille City** (Java Edition, Windows, macOS et Linux).
Il installe Java, Fabric et les mods du serveur (dont Simple Voice Chat), garde le pack à jour et
connecte directement le joueur au serveur, avec son compte Microsoft.

> NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.

Ce dépôt est un fork de [Helios Launcher](https://github.com/dscalzi/HeliosLauncher) de Daniel
Scalzi, sous licence MIT (voir `LICENSE.txt`, à conserver). La documentation d'origine, en anglais,
est dans [`docs/HELIOS_README.md`](docs/HELIOS_README.md).

**Ce dépôt est public** (GitHub impose qu'un fork d'un dépôt public le reste). Il ne doit contenir
ni secret, ni adresse IP, ni information sur le serveur maison. Le code du serveur vit dans le
dépôt privé `minecraft-mod-semirp`.

## Développer

Node.js 22 est nécessaire.

```bash
npm ci          # installe les dépendances
npm start       # lance le launcher en mode développement
npm run dist    # construit l'installateur du système courant dans dist/
```

## Ce qui reste à faire avant la première version

Tant que ces deux valeurs restent des valeurs d'attente, le launcher démarre mais ne peut ni
charger le pack ni connecter un compte :

| Valeur | Fichier | Quoi mettre |
|---|---|---|
| `AZURE_CLIENT_ID` | `app/assets/js/ipcconstants.js` | l'identifiant de notre application Azure, dès sa création (la connexion marche après l'approbation de Mojang) |
| `REMOTE_DISTRO_URL` | `app/assets/js/distromanager.js` | l'adresse publique du `distribution.json`, derrière le tunnel Cloudflare |

La marche à suivre complète (application Azure, pack Fabric avec Nebula, publication, signature)
est dans [`docs/MYRTILLE_CITY.md`](docs/MYRTILLE_CITY.md).

## Règles

- Jamais de push sur `master` : une branche et une pull request relue.
- Aucun secret dans le dépôt. Le jeton de publication est le `GITHUB_TOKEN` fourni par Actions ;
  les certificats de signature vont dans les secrets du dépôt, jamais dans un fichier.
- Textes affichés en français (`app/assets/lang/fr_FR.toml` et `_custom.toml`), code en anglais.
- Le launcher ne donne aucun avantage en jeu : il installe le même pack pour tout le monde.
