# Page publique d'une fiche partagée — `fiche.kidsrelay.fr`

Page web qu'ouvre la personne à qui un parent envoie un lien de
partage : accompagnant, enseignant, grand-parent. Elle n'a pas de
compte KidsRelay et n'en aura pas.

## Pourquoi elle n'est pas servie par Supabase

Elle l'était, par l'Edge Function `voir-partage`, et **elle ne
s'affichait pas** : la passerelle des Edge Functions réécrit toute
réponse HTML en `text/plain`, y ajoute `nosniff` et un CSP
`default-src 'none'; sandbox`. Le navigateur montrait le code source au
lieu de la page.

Constaté le 27/08/2026 en interrogeant les deux fonctions :

| Fonction | Ce que le code déclare | Ce qui arrive au navigateur |
|---|---|---|
| `consulter-partage` | `application/json` | `application/json` — intact |
| `voir-partage` | `text/html; charset=utf-8` | **`text/plain`** + `sandbox` |

La réécriture ne vise que le HTML, et elle vient de la plateforme. Même
avec le bon en-tête dans le code, cette page ne pouvait pas s'afficher
depuis un domaine `*.supabase.co`.

## Adresse

`https://fiche.kidsrelay.fr/#jeton=<token>`

**Ne plus la changer.** Des liens sont envoyés à des accompagnants et
vivent parfois un an ; une adresse qui bouge casse des liens déjà
distribués. Elle est écrite dans
[`lib/config/supabase_config.dart`](../lib/config/supabase_config.dart).

Le jeton passe **après le `#`**. Le fragment n'est pas transmis au
serveur : le jeton n'apparaît donc dans aucun journal d'accès OVH.
Même choix que pour `auth.kidsrelay.fr`.

## Ce qui est déposé

| Fichier | Rôle |
|---|---|
| `index.html` | la page entière — styles et script compris |
| `robots.txt` | interdit l'indexation, en plus de la balise `robots` de la page |

Ces deux fichiers sont **générés**, jamais écrits à la main :

```
node web_partage/generer.mjs
```

La source de vérité reste
[`supabase/functions/_logique/page_partage.mts`](../supabase/functions/_logique/page_partage.mts),
que 21 tests protègent. Le fichier déposé en est le rendu.

## Hébergement

Hébergement mutualisé OVH, offre Perso, serveurs en France, associé à
`kidsrelay.fr`. Sous-domaine `fiche.kidsrelay.fr` créé via l'onglet
**Multisite**, dossier racine `fiche`, certificat Let's Encrypt.

**Les fichiers vont dans `/home/izfeflh/fiche/`**, et non dans
`www/fiche/` comme cette page l'annonçait d'abord. Le champ « dossier
racine » de Multisite est relatif à la racine du compte, pas à `www` :
`fiche` donne donc un dossier **à côté** de `www`, qui est lui-même
`/home/izfeflh/www`. Corrigé le 27/08/2026 après le dépôt réel — le
précédent chemin était faux.

## Déposer une nouvelle version

1. `node web_partage/generer.mjs`
2. SFTP (FileZilla, port 22), identifiants de l'onglet **FTP-SSH**.
3. Type de transfert **binaire**.
4. Remplacer les deux fichiers dans `/home/izfeflh/fiche/`.
5. Vérifier (ci-dessous).

## Vérifier

```
curl -sI https://fiche.kidsrelay.fr/ | findstr /i "content-type"
```

Attendu : **`text/html`**. Si c'est `text/plain`, la page ne s'affichera
pas — c'est exactement le défaut qui a motivé ce déplacement.

## Ce qui ne transite pas

- **Aucun traceur, aucun service tiers, aucun CDN, aucune police
  distante.** La page n'émet qu'un seul appel réseau : vers
  `consulter-partage`, pour les données de la fiche.
- **Aucun cookie.** Le seul élément stocké est le secret du verrou, dans
  `localStorage`, et c'est une valeur que nous fabriquons — rien n'est
  lu sur l'appareil.
- **Aucune donnée dans l'URL** au-delà du jeton, et il est dans le
  fragment.
- **Pas d'indexation** : balise `robots` dans la page, et `robots.txt`.
- **Le minimum affiché** : le contenu est réduit côté serveur selon le
  type de fiche, avant d'être envoyé (voir `fiche_partagee.mts`).
