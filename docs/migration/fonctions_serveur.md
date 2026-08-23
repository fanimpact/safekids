# Les six fonctions serveur

État des lieux et conditions de déplacement. Document factuel : il ne
recommande aucun hébergeur et ne décrit aucune migration.

---

> ## ⚠️ Le dépôt ne correspond plus à la production
>
> **Depuis le 23/08/2026**, les fonctions ont été réorganisées dans ce
> dépôt : la logique métier est sortie des fichiers déployés. Une
> sixième, `confirmer-suppression-compte`, s'est ajoutée le
> 24/08/2026. **Aucune n'a été redéployée.** Les fonctions en ligne tournent
> encore la version d'avant cette date.
>
> Ce décalage est assumé et n'a aucun effet sur la production tant
> qu'aucun déploiement n'est lancé. Mais il faut le savoir : contrairement
> à la page `auth.kidsrelay.fr`, il n'existe **aucun vérificateur**
> capable de comparer ce qui tourne à ce qui est versionné.
>
> Les six commandes, à lancer depuis la racine du dépôt, dans cet
> ordre indifférent — **les drapeaux ne sont pas interchangeables** :
>
> ```
> supabase functions deploy envoyer-code-verification
> supabase functions deploy verifier-code
> supabase functions deploy notifier-note-ajoutee
> supabase functions deploy confirmer-suppression-compte
> supabase functions deploy consulter-partage --no-verify-jwt
> supabase functions deploy voir-partage --no-verify-jwt
> ```
>
> `--no-verify-jwt` sur les deux dernières : elles sont ouvertes à un
> accompagnant qui n'est pas connecté. L'oublier rendrait tout lien de
> partage inutilisable. À l'inverse, l'ajouter sur les quatre premières
> ouvrirait à n'importe qui des fonctions qui écrivent en base.
>
> **Point non vérifiable en local** : les fonctions importent
> maintenant des modules de `supabase/functions/_enveloppe/` et
> `_logique/`. C'est la convention documentée pour le code partagé, et
> la CLI est censée les inclure au bundle — mais Docker n'est pas
> installé sur ce poste, donc `supabase functions serve` est hors de
> portée. La preuve viendra au premier redéploiement. À faire d'abord
> sur `consulter-partage`, la moins risquée à casser.

---

## Comment c'est organisé

Trois dossiers, dont deux préfixés par `_` — la CLI ne les prend pas
pour des fonctions à déployer, mais les inclut dans le bundle de celles
qui les importent.

| Dossier | Contenu | Lié à l'hébergeur ? |
|---|---|---|
| `_logique/` | ce que font vraiment les fonctions | **non** |
| `_enveloppe/` | SDK, variables, jeton, dépôts | **oui** |
| `_tests/` | tests de `_logique/`, lancés par Node | non |

`_logique/` ne contient aucun `import` réseau, aucun appel à `Deno.*`,
aucun accès base direct, aucun `fetch` direct et aucune lecture de
l'horloge. Les accès base entrent par des interfaces (`DepotCodes`,
`DepotNotifications`, `DepotPartages`), l'envoi d'email et `fetch` sont
passés en paramètre, la date courante aussi.

C'est ce qui rend ces modules exécutables sans base ni réseau :

```
node --test supabase/functions/_tests/*.test.mjs
```

**99 tests** au 24/08/2026. Ils ne remplacent pas les tests Flutter,
qui ne couvrent rien de ce qui se passe côté serveur.

---

## Fonction par fonction

### `envoyer-code-verification`

**Ce qu'elle fait.** Appelée par l'application juste après qu'un mot de
passe a été validé, quand l'appareil n'est pas dans
`appareils_reconnus`. Génère un code à 6 chiffres, le stocke **haché**
dans `codes_verification` avec une expiration à 10 minutes, et l'envoie
par email.

**Appelée par** `lib/auth/account_service.dart:184`.

| Besoin | Détail |
|---|---|
| Authentification | oui — JWT vérifié par la plateforme |
| Secrets | `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME`, `BREVO_REPLY_TO_EMAIL` |
| Variables injectées | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` |
| Accès base | écriture `codes_verification` (contourne le RLS) |
| Appels externes | `api.brevo.com` |
| Primitives | `crypto.getRandomValues`, `crypto.subtle.digest` (SHA-256) |

**À changer hors de Supabase** : les trois variables injectées
deviennent des secrets à fournir explicitement ; l'import du SDK depuis
`esm.sh` devient l'équivalent du moteur retenu ; la vérification du JWT
n'est plus faite par la plateforme et doit être assurée par la couche
de déploiement. `crypto.subtle` est un standard du Web, disponible dans
Node et Deno — rien à changer.

### `verifier-code`

**Ce qu'elle fait.** Vérifie le code, puis enregistre l'appareil dans
`appareils_reconnus`. Refuse au-delà de 5 tentatives, ou passé
l'expiration.

**Appelée par** `lib/auth/account_service.dart:203`.

| Besoin | Détail |
|---|---|
| Authentification | oui — JWT vérifié par la plateforme |
| Secrets | aucun |
| Variables injectées | les trois mêmes |
| Accès base | lecture/écriture `codes_verification`, écriture `appareils_reconnus` |
| Appels externes | aucun |

**À changer hors de Supabase** : identique à la précédente, sans le
volet Brevo.

### `notifier-note-ajoutee`

**Ce qu'elle fait.** Point d'entrée unique de toute notification
parent. Vérifie que l'enfant fait partie de l'activité et que l'appelant
est membre actif de l'établissement propriétaire, crée une ligne dans
`evenements_notification_parent`, envoie l'email, puis met à jour cette
ligne. Le prénom de l'enfant, le nom de l'établissement et l'email du
parent sont retrouvés côté serveur — **jamais transmis par le client**.

**Appelée par** `lib/professional/establishment_activity_service.dart:223`.

| Besoin | Détail |
|---|---|
| Authentification | oui — JWT vérifié par la plateforme |
| Secrets | les quatre `BREVO_*` |
| Variables injectées | les trois mêmes |
| Accès base | lecture `activites_preparees`, `membres_etablissement`, `enfants`, `etablissements`, `comptes_parents` ; écriture `evenements_notification_parent` |
| Appels externes | `api.brevo.com` |

**À changer hors de Supabase** : idem. **Attention particulière** : la
clé de service contourne le RLS, donc les contrôles de droit sont
refaits dans le code. Ils sont dans `_logique/notification_note.mts` et
suivront le déplacement — mais un futur moteur qui n'aurait pas de RLS
du tout ne changerait rien à leur nécessité.

Le canal push, prévu au moment de la publication sur les stores, lira
et écrira sur `evenements_notification_parent` plutôt que de dupliquer
cette logique.

### `confirmer-suppression-compte`

**Ce qu'elle fait.** Envoie au parent l'email qui rappelle la date
d'effacement définitif de son compte et la façon d'annuler. Ajoutée le
24/08/2026 avec le délai de grâce.

**Ne décide rien et n'écrit rien** : la demande est déjà enregistrée en
base par `demander_suppression_compte()`, qui a posé les dates et rendu
le compte inaccessible. C'est pour cela que son échec n'annule pas la
demande côté application.

**Appelée par** `lib/suppression/suppression_compte_service.dart`.

| Besoin | Détail |
|---|---|
| Authentification | oui — JWT vérifié par la plateforme |
| Secrets | les quatre `BREVO_*` |
| Variables injectées | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Accès base | aucun |
| Appels externes | `api.brevo.com` |

**À changer hors de Supabase** : rien de particulier au-delà de ce qui
vaut pour les autres. Elle ne touche pas à la base.

L'email ne contient **aucun lien cliquable** : l'annulation se fait
dans l'application, où le parent est déjà authentifié. Un lien
d'annulation dans un email serait un moyen supplémentaire de détourner
un compte.

### `consulter-partage`

**Ce qu'elle fait.** Renvoie les données de l'enfant lié à un token de
partage. **Accessible sans authentification** : c'est tout l'intérêt du
lien. L'identifiant de l'enfant n'est jamais lu depuis la requête, il
vient de la ligne `partages` trouvée par le token.

**Appelée par** le navigateur, depuis la page servie par `voir-partage`.

| Besoin | Détail |
|---|---|
| Authentification | **non** — déployée `--no-verify-jwt` |
| Secrets | aucun |
| Variables injectées | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| Accès base | lecture `partages`, `enfants`, `profils_sante`, `profils_activites` ; écriture de la date de consultation sur `partages` |
| Appels externes | aucun |

**À changer hors de Supabase** : les deux variables injectées
deviennent des secrets. Surtout, **c'est la seule porte ouverte sans
authentification vers des données de santé d'enfant** : la couche de
déploiement doit garantir qu'elle reste publique (sinon les liens
cessent de fonctionner) sans exposer autre chose au même endroit.

Le token voyage dans la chaîne de requête, donc dans les journaux du
serveur. C'est une différence assumée avec `auth.kidsrelay.fr`, où le
jeton passe par le fragment et n'atteint jamais un serveur. Tout
hébergeur retenu doit être compatible avec cette exposition, ou la
faire disparaître.

### `voir-partage`

**Ce qu'elle fait.** Sert une page HTML statique. Le navigateur y lit le
token, appelle `consulter-partage`, et affiche la fiche. Lecture seule :
aucun formulaire, aucune écriture.

**Adresse partagée** construite par `lib/sharing/share_link_service.dart:67`.

| Besoin | Détail |
|---|---|
| Authentification | **non** — déployée `--no-verify-jwt` |
| Secrets | aucun |
| Variables injectées | **aucune** |
| Accès base | aucun |
| Appels externes | aucun |

**À changer hors de Supabase** : presque rien. C'est la fonction la plus
facile à déplacer — elle n'a besoin de rien. Un seul point : la page
appelle `consulter-partage` à l'adresse
`/functions/v1/consulter-partage`, imposée par Supabase. C'est le
paramètre `cheminApi` de `construirePage()`, dont la valeur par défaut
est celle d'aujourd'hui ; le changer suffit.

À noter qu'une page statique n'a pas besoin d'une fonction serveur pour
être servie. Elle pourrait tenir sur l'hébergement OVH déjà en place, à
côté de `auth.kidsrelay.fr` — ce qui changerait aussi l'adresse des
liens de partage, aujourd'hui en `xcugfdjaifdibwowlrpi.supabase.co`.
Point à trancher séparément.

---

## Ce qui est commun aux cinq

**Trois variables injectées automatiquement.** `SUPABASE_URL`,
`SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY` n'apparaissent nulle
part dans la configuration du projet : la plateforme les fournit à
l'exécution. Ailleurs, elles deviennent des secrets à déclarer, et la
clé de service devient un secret à protéger comme tel — elle contourne
tous les contrôles d'accès de la base.

**La vérification du jeton est faite par la plateforme**, avant que le
code de la fonction ne s'exécute. C'est ce que porte le drapeau
`--no-verify-jwt`, ou son absence. Hors de Supabase, cette vérification
n'existe plus gratuitement : elle doit être assurée par la couche de
déploiement, ou refaite dans l'enveloppe.

**Le SDK vient d'`esm.sh`**, la CDN utilisée par Deno. Un seul fichier
l'importe : `_enveloppe/supabase.mts`.

**Le format de requête et de réponse ne change pas.** Chemins, corps,
codes de statut et messages d'erreur sont identiques à ce qui tournait
avant le 23/08/2026 — quatre d'entre eux sont figés par du code Dart
qui les appelle.

---

## Brevo

Brevo n'est **pas** une dépendance à Supabase : ces emails partiraient
par Brevo quel que soit l'hébergeur. Ce qui a changé, c'est qu'il est
maintenant derrière une interface (`_logique/emails.mts`), pour pouvoir
en changer sans toucher au contenu des messages.

Ce dont il a besoin :

- une clé API valide, dans `BREVO_API_KEY` ;
- une adresse expéditeur **vérifiée** dans Brevo, dans
  `BREVO_SENDER_EMAIL` ;
- **SPF, DKIM et DMARC configurés sur `kidsrelay.fr`** — toujours à
  faire. Sans cela, les emails partent mais tombent en indésirables
  chez une partie des destinataires. Indépendant de tout choix
  d'hébergeur : c'est de la configuration DNS du domaine.

Contrainte de contenu tenue par les deux messages, et vérifiée par les
tests : jamais de donnée de santé, jamais de nom de famille d'enfant,
jamais le texte d'une note. La fonction qui compose l'email de note ne
**reçoit** pas le texte de la note — c'est une garantie de structure,
pas une convention de rédaction.

---

## Ce que ce chantier n'a pas fait

- Aucun redéploiement.
- Aucune modification de la base, ni du schéma, ni des politiques RLS.
- Aucun changement de comportement observable.
- Aucun choix d'hébergeur, aucune migration.
