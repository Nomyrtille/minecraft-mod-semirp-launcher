# Consignes pour Claude

Fork public de Helios Launcher (Electron, Node.js 22) pour le serveur semi-RP Myrtille City. Lire
`README.md` puis `docs/MYRTILLE_CITY.md`.

- Réponses et documentation en français ; code, identifiants et messages de commit en anglais.
- Textes affichés aux joueurs : `app/assets/lang/fr_FR.toml` (traduction de `en_US.toml`, qui sert
  de repli) et `app/assets/lang/_custom.toml` (textes propres à Myrtille City). Toute nouvelle clé
  ajoutée à `en_US.toml` doit aussi l'être à `fr_FR.toml`.
- Dépôt **public** : aucun secret, aucune adresse IP, aucun nom d'hôte interne, aucune donnée de
  joueur.
- Jamais de push sur `master`.
- Conserver `LICENSE.txt` et la mention du copyright de Daniel Scalzi.
- Rester proche de l'amont pour pouvoir récupérer ses correctifs : modifier le moins de fichiers
  possible, préférer la configuration (`_custom.toml`, `distribution.json`) au code.
- Les fichiers d'origine sont en CRLF pour certains (`package.json`, `_custom.toml`) : garder leurs
  fins de ligne.
- Vérifier avant de pousser : `npm ci`, puis
  `npx eslint --rule '@stylistic/linebreak-style: off' .` (la règle CRLF échoue déjà sur tout le
  code amont extrait en LF).
