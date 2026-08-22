# Page d'accès au compte — `auth.kidsrelay.fr`

Page web qui termine les deux parcours ouverts depuis un email
Supabase : **mot de passe oublié** (`type=recovery`) et **confirmation
de compte** (`type=signup`).

Elle existe parce que les liens pointaient auparavant vers
`kidsrelay://auth-callback`, un schéma que seul un appareil avec
l'application installée sait ouvrir. Un parent relevant ses mails sur
un ordinateur restait bloqué hors de son compte, sans recours.

## Ce qui est déployé

Le contenu de `public/ouvrir-lien-email/` — **deux fichiers**, rien
d'autre :

| Fichier | Rôle |
|---|---|
| `index.html` | Page, styles, et câblage de l'affichage |
| `auth-lien.js` | Logique : lecture du lien, appels à l'API, messages |

Adresse publique : `https://auth.kidsrelay.fr/ouvrir-lien-email/`

Le reste de ce dossier (`test/`, `package.json`,
`verifier-deploiement.mjs`) **ne se dépose pas** sur l'hébergement.

## Hébergement

Hébergement mutualisé OVH, offre Perso, serveurs en France, associé à
`kidsrelay.fr`. Sous-domaine `auth.kidsrelay.fr` créé via l'onglet
**Multisite**, dossier racine `auth`, certificat Let's Encrypt.

Les fichiers vont donc dans `www/auth/ouvrir-lien-email/`.

Pas d'Edge Function : la page n'a besoin d'aucun traitement serveur.
Tout se joue dans le navigateur, contre l'API Auth du projet Supabase
(`eu-central-1`), qui autorise les appels depuis n'importe quelle
origine (`Access-Control-Allow-Origin: *`).

## Déposer une nouvelle version

1. Se connecter en **SFTP** (FileZilla, port 22) avec les identifiants
   de l'onglet **FTP-SSH** de l'hébergement.
2. Régler le type de transfert sur **binaire**, pour ne pas altérer les
   fins de ligne.
3. Remplacer les deux fichiers dans `www/auth/ouvrir-lien-email/`.
4. **Vérifier** (voir ci-dessous). Ce n'est pas facultatif : rien
   d'autre ne garantit que la version en ligne est celle du dépôt.

## Vérifier que la page en ligne est bien celle du dépôt

```
node web_auth/verifier-deploiement.mjs
```

Compare l'empreinte SHA-256 des fichiers servis avec ceux du dépôt, et
sort en code 1 si un fichier diffère ou manque. Les fins de ligne sont
normalisées avant comparaison : un dépôt FTP en mode ASCII réécrit les
CRLF et déclencherait sinon une fausse alerte.

Pour contrôler une autre adresse (préproduction, serveur local) :

```
node web_auth/verifier-deploiement.mjs http://127.0.0.1:8099/ouvrir-lien-email/
```

La page porte aussi un commentaire de version en tête de
`index.html` : « afficher le code source » depuis n'importe quel
navigateur suffit à voir quelle version est en ligne, sans outil.

## Tests

```
cd web_auth && npm test
```

Aucune dépendance, aucune installation : le lanceur intégré de Node
(`node --test`). Les tests couvrent la lecture du lien, les règles du
mot de passe, la traduction des erreurs de l'API, les deux parcours de
bout en bout, et l'étanchéité du jeton.

Ce qui n'est **pas** couvert : le câblage DOM de `index.html`
(affichage/masquage des sections, bascule de l'icône œil). Il est
volontairement mince — toute décision est prise dans `auth-lien.js`,
qui rend une « vue » que la page se contente d'afficher.

## Contraintes tenues

- Aucune donnée d'enfant, aucune donnée de santé, aucun listing de
  comptes.
- Aucun script tiers, aucun CDN, aucun cookie, aucune mesure
  d'audience. Deux `fetch` vers l'API du projet, rien d'autre.
- Le jeton voyage **dans le fragment** de l'URL (`#token_hash=…`), qui
  n'est jamais transmis à un serveur : il ne peut apparaître dans aucun
  journal d'hébergement. Il est retiré de la barre d'adresse dès sa
  lecture (`history.replaceState`).
- Restylage : toute l'identité visuelle tient dans les variables CSS de
  `:root`. La changer ne demande pas de retoucher le balisage.

## Modèles d'email Supabase

Les deux modèles pointent **directement** sur cette page, et non via
`redirect_to` : `supabase_flutter` utilise PKCE par défaut, dont
l'échange exige un `code_verifier` propre à l'appareil qui a fait la
demande. Une redirection classique échouerait donc précisément dans le
cas qu'on veut couvrir — l'ouverture depuis un autre appareil.

Le `#` avant `token_hash` est le point critique. Le remplacer par `?`
ferait passer le jeton dans les journaux du serveur.
