# Où nous en sommes — point de reprise

**Dernière mise à jour : 26/08/2026**

Document de reprise : à lire en premier au début d'une session pour
savoir ce qui est fait, ce qui attend, et ce qui bloque. À tenir à jour
plutôt qu'à laisser vieillir.

---

> ## ✅ Les six fonctions serveur sont déployées
>
> **Le 25/08/2026**, les six Edge Functions ont été redéployées depuis
> le dépôt. Le bundling des modules partagés `_enveloppe/` et
> `_logique/` — seul point du chantier qui n'avait jamais pu être
> vérifié faute de Docker sur ce poste — a fonctionné.
>
> `schema_conformite_rgpd.sql` (24/08) et
> `schema_journal_ouvertures_partage.sql` (25/08) sont exécutés.
> **Le dépôt et la production correspondent.**
>
> À savoir pour la suite : contrairement à `auth.kidsrelay.fr`, **aucun
> vérificateur** ne peut comparer ce qui tourne à ce qui est versionné.
> Toute modification d'une fonction doit être redéployée à la main :
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
> Les drapeaux ne sont pas interchangeables : `--no-verify-jwt` sur les
> deux dernières seulement, qui sont ouvertes à un accompagnant non
> connecté. L'oublier casserait tous les liens de partage ; l'ajouter
> aux quatre premières ouvrirait à n'importe qui des fonctions qui
> écrivent en base.

---


## En une phrase

Le socle technique est **prêt à être quitté** : le schéma est figé et
versionné, les prérequis d'une base cible sont documentés,
l'authentification est isolée derrière une interface unique, et la
logique des six fonctions serveur ne dépend plus de l'environnement
Supabase. Les quatre décisions RGPD prises le 24/08/2026 sont en
place, en attente de l'exécution de leur fichier SQL.

**Rien ne bouge tant que Clever Cloud n'a pas répondu sur l'hébergement
HDS.**

---

## Ce qui est acquis

### 1. Le schéma est figé et versionné

Les 17 fichiers `supabase/*.sql` sont appliqués à la main depuis le
début du projet, sans système de migration. Rien ne garantissait que la
base leur corresponde.

**C'est vérifié : elle correspond.** 16 tables, 150 colonnes, 40
politiques RLS, 18 fonctions, 26 index — aucun objet créé à la main
sans équivalent versionné, aucune divergence de définition.

Deux instantanés datés du 23/08/2026 vivent dans `supabase/_snapshot/`,
et ils ne servent pas à la même chose :

| Fichier | Nature | Sert à |
|---|---|---|
| `schema_reel_2026-08-23.sql` | reconstruction depuis les catalogues | **comparer** avec les 17 fichiers |
| `schema_dump_2026-08-23.sql` | vrai `pg_dump --schema-only` | **recréer** la structure ailleurs |

Rapport : [`ecart_schema.md`](ecart_schema.md).

Une incohérence a été corrigée au passage : `partages_geres_par_le_parent`
était déclarée deux fois, avec deux définitions divergentes. La base
portait la bonne, mais lire `schema.sql` seul menait à la conclusion
inverse.

**Les deux tâches `pg_cron` sont vérifiées actives** (23/08/2026, depuis
le SQL Editor). Celle qui purge le journal des consultations à 12 mois
est une pièce du dossier RGPD :
[`retention_journal_consultations.md`](retention_journal_consultations.md).

### 2. Les prérequis d'une base cible sont documentés

[`../migration/prerequis_base_cible.md`](../migration/prerequis_base_cible.md)
liste ce qu'une base PostgreSQL non-Supabase devrait fournir. Établi en
rejouant réellement le dump sur un PostgreSQL vierge : **178 erreurs,
14 tables créées sur 16**.

Ce que ce travail a appris, et qui contredit l'intuition :

- **Les 3 rôles pèsent 108 des 178 erreurs, mais aucune politique RLS
  ne les utilise.** Toutes s'appliquent à `PUBLIC`. Le cloisonnement ne
  repose jamais sur le rôle PostgreSQL, uniquement sur `auth.uid()`.
- **Sur les 5 extensions déclarées, 2 seulement servent** : `pgcrypto`
  et `pg_cron`. `uuid-ossp`, `supabase_vault` et la publication
  `supabase_realtime` sont de l'héritage sans usage.
- **Le poids n'est pas dans le schéma, il est dans l'authentification.**
  Rôles, extensions et schémas se recréent en quelques instructions.
  `auth.uid()` (33 expressions de politiques) et `auth.users` (19 clés
  étrangères), non.

**Aucun hébergeur n'y est nommé** : c'est une liste de prérequis, pas
un plan de migration.

### 3. L'authentification est isolée

Chantier du 23/08/2026, 7 commits. Les 30 appels au SDK dispersés dans
12 fichiers passent maintenant par `lib/auth/auth_provider.dart`, dont
`SupabaseAuthProvider` est la seule implémentation.

**L'import `supabase_flutter` est passé de 19 à 11 fichiers** — les 10
services et l'implémentation. Plus un seul écran, ni `main.dart`, ni un
utilitaire ne connaît Supabase.

Trois types applicatifs remplacent ceux du SDK qui fuyaient :
`AuthSessionEvent`, `AuthErrorCode`/`AuthFailure`, et `ServiceException`
pour les refus de la base.

`test/supabase_isolation_test.dart` verrouille cette frontière : il
échoue dès qu'un fichier la franchit, et nomme le fautif. Vérifié en
injectant une violation.

**Le câblage est couvert par 39 tests depuis le 23/08/2026** : les deux
tables de correspondance écrites à la main (filtre d'évènements, codes
d'erreur), la réaction de l'app à un évènement de session, et le garde
de `createSeparateAccount`. Chacun a été vérifié en cassant
volontairement le code qu'il protège. Un double `FakeAuthProvider` vit
dans `test/support/`.

---

### 4. Les fonctions serveur sont isolées de l'hébergeur

Même principe que pour l'authentification, appliqué aux cinq Edge
Functions. La logique métier vit dans `supabase/functions/_logique/` :
aucun import réseau, aucun appel à `Deno.*`, aucun accès base direct,
aucun `fetch` direct, aucune lecture de l'horloge. Les accès base
entrent par des interfaces, l'email et la date courante sont passés en
paramètre.

Ce qui est propre à Supabase est rassemblé dans `_enveloppe/` : import
du SDK depuis `esm.sh`, variables injectées à l'exécution, jeton
d'appel, branchement des dépôts. Un déplacement se réduit à réécrire
`environnement.mts` et `supabase.mts`.

**85 tests**, lancés par `node --test supabase/functions/_tests/*.test.mjs`.
Ils couvrent l'envoi et la vérification d'un code, la notification
d'une note ajoutée, la consultation d'un partage et le rendu de la page
publique — ce dernier en exécutant le script réel de la page dans un
faux DOM, donc exactement ce qui sera servi. C'était le seul rendu de
données de santé d'enfant qui échappait complètement à Flutter.

Rien n'est redéployé : voir l'avertissement en tête de ce document.
État des lieux complet dans
[`../migration/fonctions_serveur.md`](../migration/fonctions_serveur.md).

---

### 5. Le droit d'accès RGPD est outillé

Un parent récupère seul, depuis **Paramètres → Mes données**, une copie
de tout ce que l'application détient sur lui et sur ses enfants :
compte, profils de santé et d'activités, partages, rattachements aux
établissements, notes ajoutées par un professionnel, journal des
consultations, personnes de confiance, activités préparées.

Deux fichiers partent ensemble : un **PDF** lisible, destiné à être
remis à un médecin ou à un établissement, et un **`.json`**
réutilisable, versionné et accompagné d'un `_lisez_moi` en français.

Trois règles tiennent le tout :

- **Un enfant n'est exporté que par son parent.** La table `enfants`
  renvoie aussi, par le RLS, les enfants sur lesquels le compte est
  personne de confiance : l'export refiltre sur `parent_id`. Les tests
  vérifient qu'aucune donnée d'un enfant d'autrui n'est même *lue*.
- **Les jetons de partage sont retirés des deux fichiers.** Ce sont
  des clés d'accès aux fiches, et ces fichiers sont faits pour être
  transmis. Les partages eux-mêmes (date, destinataire, expiration,
  consultations) restent présents.
- **Un export est complet ou n'est pas.** Une lecture qui échoue fait
  échouer l'export entier, avec un message clair.

**69 tests.** Le contenu du PDF est décidé et vérifié en texte
(`export_contenu.dart`), séparément de sa mise en page : le texte d'un
PDF y est écrit en identifiants de glyphes, un test qui tenterait de
le relire passerait toujours.

Reste à vérifier à l'œil : voir
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md), section
« Export Mes données » — dont la relecture du contenu par Fanny, la
seule vérification qui puisse confirmer que l'export est réellement
complet.

Non traité, et noté dans
[`corrections_a_faire.md`](corrections_a_faire.md) : le droit d'accès
d'une **personne de confiance** sur ses propres données.

---

### 6. Quatre décisions RGPD sont en place

Délai de grâce de 7 jours à la suppression du compte, consentement
explicite aux données de santé, compteurs d'usage anonymisés, adresse
email de secours.

**Le fichier SQL a été appliqué le 24/08/2026**, sans erreur
(`supabase/schema_conformite_rgpd.sql`). Colonnes, fonctions et
politiques modifiées sont en place.

**Les quatre tâches automatiques sont en place**, vérifiées le
24/08/2026 : `jobid` 2 à 5, correspondant exactement aux quatre que
définit le dépôt.

| `jobid` | Nom | Fichier | Fréquence |
|---|---|---|---|
| 2 | `supprimer-partages-expires` | `partages_liens.sql` | 3h |
| 3 | `purge-journal-consultations-fiche` | `schema_espace_professionnel_fiches.sql` | 3h |
| 4 | `effacer-comptes-supprimes` | `schema_conformite_rgpd.sql` | 4h |
| 5 | `consolider-compteurs-usage` | `schema_conformite_rgpd.sql` | 4h30, le 1er du mois |

Aucun doublon. Le `jobid` 1 a été consommé par une tâche supprimée
autrefois — `pg_cron` ne réutilise pas ses identifiants, donc la
numérotation commence à 2 et cela n'indique rien d'anormal.

Ce qui compte le plus, dans l'ordre :

- **Le blocage d'un compte en suppression tient en base**, par le RLS,
  et pas seulement dans l'application. L'écran double le blocage pour
  que le parent comprenne ce qu'il voit ; c'est le RLS qui protège.
- **Le mois en cours des compteurs est pseudonyme, pas anonyme.**
  Compter des familles distinctes l'impose. La consolidation mensuelle
  détruit les empreintes et le sel, et ne laisse qu'un entier : c'est
  elle qui rend l'historique anonyme.
- **Un compteur ne retarde jamais une action.** Le Mode Urgence en
  particulier : l'appel n'est pas attendu et ses erreurs sont avalées.
- **L'export RGPD a été étendu** à `comptes_parents` : sans cela il
  aurait cessé d'être complet le jour où les trois nouvelles colonnes
  ont été ajoutées.

**86 tests** ajoutés (Flutter et JavaScript). État des lieux complet
dans [`../migration/conformite_rgpd.md`](../migration/conformite_rgpd.md),
vérifications à l'œil dans
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md).

Non traité, et noté : la procédure d'usage de l'adresse de secours
n'existe pas encore — le champ est un prérequis, pas une fonctionnalité
complète.

### Le questionnaire commencé n'est plus perdu — 25/08/2026

Jusqu'à ce jour, **rien n'était écrit avant la dernière page** : le
profil de santé après le sixième écran, le profil Activités après le
onzième. Un parent interrompu au milieu — un appel, une batterie vide,
l'application balayée hors des récentes — perdait tout et recommençait.

Le brouillon est désormais écrit **à chaque écran validé**, sur
l'appareil (`SharedPreferences`), et nulle part ailleurs.

Ce qui a été décidé, et pourquoi :

- **Sur l'appareil, pas en base.** Écrire un brouillon en base aurait
  voulu dire créer une ligne `enfants` incomplète, et donc apprendre à
  toute l'application — jusqu'au Mode Urgence — à distinguer un enfant
  d'un brouillon. Un enfant à moitié saisi apparaissant dans le Mode
  Urgence avec « Aucune consigne particulière » aurait été un mauvais
  échange. **Ce que cela coûte** : le brouillon meurt avec l'appareil
  (réinstallation, téléphone perdu, second appareil). Une table de
  brouillons en base réglerait cela ; elle attend qu'un besoin réel se
  manifeste.
- **La reprise repart du premier écran**, réponses pré-remplies. Plus
  simple, et cela laisse au parent l'occasion de relire ce qu'il avait
  saisi trois semaines plus tôt.
- **Le parent est prévenu, jamais de reprise silencieuse.** « Mes
  enfants » affiche « Reprendre le profil de Théo, commencé le 25/08 ».
- **Le brouillon est jeté à la validation finale, et au bout de 30
  jours s'il dort.** Il contient des pathologies, des allergies et des
  traitements : il n'a pas à rester indéfiniment sur un téléphone. La
  purge a lieu **à la lecture** et est réécrite aussitôt — un brouillon
  périmé ne survit pas parce que personne n'est repassé derrière.

Un défaut introduit puis corrigé, à ne pas réintroduire :
**l'écriture du brouillon n'est jamais attendue avant de naviguer.**
Le premier câblage attendait `SharedPreferences` avant
`Navigator.push` ; quatorze tests sont tombés, et surtout un parent
dont le stockage aurait toussé serait resté bloqué au milieu de son
questionnaire — exactement le problème qu'on cherchait à résoudre. Les
trois fonctions de `lib/brouillons/enregistrement_brouillon.dart`
avalent leurs erreurs, et les écrans les appellent sans `await`. Un
test de câblage le verrouille.

**41 tests** ajoutés : conversions aller-retour, règle des 30 jours aux
bornes, tolérance à un stockage abîmé, effacement réel du disque, et
lecture des sources des dix-sept écrans. Vérifié en cassant
volontairement le code protégé — le câblage retiré d'un écran et la
durée de vie portée à dix ans font tomber les tests concernés.

Trois vérifications à l'œil ajoutées : points 68, 69 et 70 de
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md).

---

## Ce qui bloque

**En attente d'une réponse de Clever Cloud sur l'hébergement HDS.**

Aucune décision d'hébergement n'est prise. Tant que cette réponse n'est
pas arrivée, **ne pas engager de migration** : ni réécriture de la
couche de données, ni création de comptes ailleurs, ni modification des
17 fichiers SQL.

Le travail fait jusqu'ici est délibérément **réversible et neutre** :
il rend une migration possible sans en présumer la destination. Si la
réponse est négative, rien n'est perdu — le code est simplement mieux
rangé.

---

## Ce qui attend, sans être bloqué

### Vérifications manuelles, prioritaires

Des 9 points du chantier d'authentification, **6 ont été couverts par
des tests le 23/08/2026** (39 tests). Il en reste **6** dans
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md) — certains sont
des restes partiels des neuf d'origine — et tous exigent un vrai
appareil, un vrai serveur ou un second compte.

Les deux prioritaires : le lien « mot de passe oublié » ouvert depuis un
vrai mobile (la chaîne email → système → SDK reste hors de portée d'un
test), et la création d'un compte professionnel confirmée contre la
vraie base — le scénario qui avait fait perdre l'accès à Théo et Noé.

### Chantier « périmètre C », non décidé

Abstraire l'accès aux données comme l'authentification l'a été ferait
passer les 11 fichiers restants à 2. Écarté pour l'instant :
**61 appels à réécrire**, sur une application où une erreur de filtre
expose les données d'un autre enfant, et sans test d'intégration contre
une vraie base. À rouvrir seulement si une migration est décidée.

### Déjà fait — à ne pas redemander

Deux chantiers ont été redemandés en session alors qu'ils étaient
faits. Vérifier ici avant de coder.

**Consentement à l'enregistrement des données de santé — fait le
24/08/2026.**

Écran dédié [`consentement_sante_page.dart`](../../lib/consentement/consentement_sante_page.dart),
posé sur les **deux** chemins de création d'enfant, jamais affiché en
modification. Case décochée par défaut, bouton désactivé tant qu'elle
n'est pas cochée, ligne grise en dessous. La date du geste part dans
`enfants.consentement_sante_le` (`timestamptz`, nullable) — et rien
d'autre : ni adresse IP, ni identifiant d'appareil. Migration
[`schema_conformite_rgpd.sql:41`](../../supabase/schema_conformite_rgpd.sql),
**appliquée en production**. Les fiches antérieures ont la colonne à
`null` et fonctionnent normalement. 12 tests.

*Décision tenue, et renforcée depuis :* la case est **avant** le
questionnaire et non sur le dernier écran. Un consentement doit être un
acte distinct — et depuis le chantier du brouillon, les réponses sont
écrites sur l'appareil dès le premier écran validé. La placer à la fin
reviendrait à stocker six écrans de données de santé, puis à demander
l'autorisation de les stocker. Proposition de déplacement examinée puis
écartée le 27/08/2026, par Fanny.

**Délai de grâce de 7 jours à la suppression du compte — fait le
24/08/2026.**

- `demander_suppression_compte()` pose `suppression_demandee_le = now()`
  et `suppression_effective_le = now() + interval '7 days'` ;
- `annuler_suppression_compte()` rend l'accès immédiatement ;
- `suppression_en_cours()` laisse le parent bloqué lire **cette
  date-là et rien d'autre** ;
- le blocage tient **par le RLS** (`compte_en_suppression()` dans les
  policies), pas seulement dans l'application ;
- la tâche `effacer-comptes-supprimes` (jobid 4, `0 4 * * *`) est
  **active en production** — vérifié le 27/08/2026.

Côté application : [`lib/suppression/`](../../lib/suppression/) —
garde, service, section des réglages, écran d'attente, et
`joursRestants` compté en **jours entamés** (à 23 h de l'échéance il
reste « 1 jour », jamais « 0 »). 27 tests.

Ce qui reste sur ce sujet est **uniquement** la vérification à l'œil du
point 62 : l'effacement réel au passage de la tâche de 4 h, sur un
compte de test, jamais sur Théo ou Noé.

**Compteurs de familles actives par mois et par fonctionnalité — fait
le 24/08/2026.**

Trois tables, vérifiées présentes en production le 27/08/2026 :
`marqueurs_usage` (mois, fonctionnalité, empreinte), `sels_usage`
(mois, sel), `compteurs_usage` (mois, fonctionnalité,
`nombre_familles`, `consolide_le`). Deux fonctions,
`enregistrer_usage` et `consolider_compteurs_usage`. Tâche
`consolider-compteurs-usage` (jobid 5, `30 4 1 * *`) **active**.

Quatre fonctionnalités comptées, liste fermée côté base :
`activite_preparee`, `fiche_secours_generee`, `mode_urgence_ouvert`,
`lien_partage_cree` — voir
[`lib/usage/compteur_usage.dart`](../../lib/usage/compteur_usage.dart).

**Jamais quoi ni pour qui** : aucun identifiant d'enfant, aucun
contenu. La consolidation ne garde qu'un entier par mois et par
fonctionnalité, puis supprime les empreintes et le sel. 9 tests.

*Réserve déjà actée, à redire telle quelle :* le **mois en cours est
pseudonyme, pas anonyme** — compter des familles distinctes l'impose.
C'est la consolidation qui rend l'historique anonyme.

**Adresse email de secours — faite le 24/08/2026.**

Colonne `comptes_parents.email_secours`, vérifiée présente en
production. Validation pure dans
[`lib/settings/email_secours.dart`](../../lib/settings/email_secours.dart),
section dédiée dans les réglages, 22 tests. Volontairement permissive :
nous n'envoyons rien à cette adresse, donc refuser une adresse valide
mais inhabituelle serait plus gênant qu'accepter une faute de frappe.

*Réserve, toujours vraie :* l'adresse est stockée, mais **aucune
procédure ne dit comment on s'en sert** quand un parent perd son accès.
Le champ est un prérequis, pas une fonctionnalité complète. Noté dans
`corrections_a_faire.md`.

**Pas fait, et pas faisable en l'état — conservation 3 mois après fin
d'abonnement.** Constaté le 27/08/2026 : `comptes_parents` porte un
`abonnement_actif boolean not null default false`, **sans date de début
ni de fin**, qu'aucun code n'écrit — la policy réserve son passage à
`true` à « un futur backend de facturation » qui n'existe pas. Aucune
tâche planifiée ne le regarde. En production : 2 comptes, 0 abonné.
Une règle « 3 mois après la fin » n'a rien sur quoi se déclencher tant
qu'une date de fin n'existe pas. **Décision préalable requise**, pas un
chantier à lancer.

### Ce qui reste, au soir du 26/08/2026

Par ordre de ce qui bloque le plus la suite.

**1. La session de test sur un vrai Android.** 70 points dans
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md), qui ne peuvent
pas être couverts autrement : reprise d'un questionnaire après
l'application tuée, lisibilité du texte sur vert pin et sur ambre,
parcours du co-parent et de la gestion d'équipe (deux comptes), longueur
des écrans. Fanny prévoit d'acheter un appareil d'occasion. Le
document dit en tête ce qu'il faut préparer à l'avance. **Rien d'autre
n'est bloqué par ce point, mais rien ne le remplace non plus.**

**2. SPF / DKIM / DMARC de `kidsrelay.fr` dans Brevo — FAIT.**
Vérifié le 28/08/2026 directement dans le DNS public : DKIM en
place (deux clés Brevo, `brevo1` et `brevo2._domainkey`, signature
sur `kidsrelay.fr`), DMARC présent, domaine et expéditeur
`contact@kidsrelay.fr` authentifiés côté Brevo. **Ce point est
clos.** Deux remarques sans urgence sont notées dans
`corrections_a_faire.md` : la politique DMARC est `p=none`, et le
SPF du domaine n'inclut pas Brevo — ce qui ne gêne pas l'envoi,
l'alignement passant par DKIM.

**3. Les deux modèles d'email Supabase.** À coller dans le tableau de
bord pour que les liens pointent vers `auth.kidsrelay.fr`. Contenu
exact fourni en session, non appliqué au 26/08/2026.

**4. La suite de la couche explicative — deux écrans identifiés,
non traités.** Le point 3 du chantier a bien avancé : la note
d'activité est faite, et de bout en bout (comportement corrigé, écran
parent construit, fonction du professionnel). Restent les deux autres
de la priorité haute, tous deux dus à un **écart entre ce que l'écran
laisse croire et ce qu'il fait** :

- [`claim_attachment_page.dart`](../../lib/professional/claim_attachment_page.dart)
  — « Rattacher un enfant ». L'écran ne dit pas que l'accès **expire à
  une date choisie par le parent**, qu'il est **révocable à tout
  instant**, ni que **chaque ouverture de fiche est journalisée** et
  visible du parent. Un professionnel qui ignore ce qu'il obtient ne
  sait pas non plus ce qu'il n'a pas le droit de faire. **Textes à
  proposer, Fanny valide avant intégration.**
- [`consultation_journal_page.dart`](../../lib/sharing/consultation_journal_page.dart)
  — « Journal de consultation ». Sa phrase d'accueil dit « Chaque fois
  qu'un **établissement rattaché** ouvre une fiche… » alors que le
  journal enregistre **aussi les ouvertures de liens de partage**, par
  des gens non identifiés. Et rien ne dit que tout s'efface à 12 mois.
  **Même méthode.**

L'inventaire complet, avec la priorité moyenne et basse (recommandations,
rattachements, gestion d'équipe, Mode Urgence, les deux fiches,
trombinoscope, création d'activité), est dans
[`../mode_emploi/inventaire_ecrans.md`](../mode_emploi/inventaire_ecrans.md).

**Décidé et non fait, sans urgence** : la reprise automatique des
notifications en échec — écartée le 26/08 avec ses raisons écrites,
voir [`../migration/notifications_non_parties.md`](../migration/notifications_non_parties.md).
À rouvrir seulement si des `echoue` s'accumulent.

### Reste ouvert depuis les sessions précédentes

- **Modèles d'email Supabase** — à coller dans le tableau de bord pour
  que les liens pointent vers `auth.kidsrelay.fr` (contenu exact fourni
  en session, non encore appliqué au 23/08/2026).
- **Doublon d'affichage de l'équipement** sur la fiche d'activité (bloc
  de situation + récapitulatif « Matériel à prévoir »). Comportement
  existant, signalé, jugé volontaire — à confirmer.

---

## Pièges de l'outillage, appris à la dure

**`git checkout -- <fichier>` restaure depuis HEAD, donc efface tout ce
qui n'est pas commité.** Deux fois dans la session du 25/08/2026, il a
fait reperdre des modifications en cours : une fois sur
`medical_events_page.dart`, une fois sur
`establishment_onboarding_page.dart`. Les deux fois, il fallait tout
rejouer.

Les deux fois, le geste venait du même besoin : **casser volontairement
le code pour vérifier qu'un test tombe**, puis remettre en état. C'est
une bonne pratique, gardée — mais elle demande un ordre précis.

> **La règle : commiter d'abord, falsifier ensuite.**
>
> Le commit est le filet. `git checkout --` redevient alors sûr, parce
> qu'il restaure exactement ce qui vient d'être commité, et non un état
> antérieur au chantier.

Corollaire, quand on ne veut pas encore commiter : copier le fichier
(`cp x /tmp/x.bak`) avant de le casser, et restaurer par `cp` et non
par `git`. C'est ce qui a été fait pour les scripts SQL, qui n'étaient
pas suivis par git au moment de la vérification.

**Autre piège du même ordre : le délimiteur de `perl -pe`.** `s|...|...|`
casse sur toute expression contenant un `|` — un `||` de condition
Dart, une table markdown. La substitution échoue en silence, ou pire,
réussit à moitié. Utiliser `s{...}{...}`, et vérifier que la
substitution a bien eu lieu (`die unless $n == 1`).

Et jamais `\x{...}` au-dessus de 255 dans un remplacement perl : cela
force la sémantique caractère et double-encode les fichiers UTF-8.
Erreur commise deux fois, réparée deux fois par `git checkout --`.


## Chantier notifications — où il en est au 28/08/2026, 23h50

La chaîne d'envoi **existe et fonctionne**. Vérifiée de bout en bout :
une notification écrite en base part par Brevo et arrive.

### Ce qui est en place et déployé

| | |
|---|---|
| `envoyer-notifications-parent` | le filet, appelé par OVH toutes les heures |
| `envoyer-notifications-maintenant` | l'envoi immédiat demandé par l'application |
| `envoyer-code-verification` | redéployée, porte la consigne « domaine jeune » |
| Tâche OVH | `taches/tache_notifications.php`, `18 * * * *`, PHP 8.2, active |
| SPF / DKIM / DMARC | corrects, **ne pas y toucher** |

### Ce qui reste à faire

**1. Le vrai test de délivrabilité.** Celui de ce soir ne prouve
rien : Fanny avait marqué l'expéditeur comme légitime, le message ne
pouvait qu'arriver. Il faut **créer une adresse neuve, de préférence
Gmail**, qui n'a jamais rien reçu de `kidsrelay.fr`, et y envoyer un
message. Google est le fournisseur le plus répandu chez les parents et
se comporte autrement que Microsoft.

**2. LA TÂCHE OVH N'A PAS ÉCRIT SON JOURNAL — à reprendre en premier.**

Constat à **23h55** le 28/08 : `/home/izfeflh/taches/` ne contient que
`tache_notifications.php`. Pas de `dernier_passage.txt`, alors que le
passage de 23h18 aurait dû avoir lieu.

Deux possibilités : la tâche n'a pas tourné, ou elle a tourné sans
écrire.

**Et elle est muette, par ma faute.** J'ai fait décocher l'email de
compte-rendu pour ne pas noyer Fanny sous 24 messages par jour. C'était
juste sur le principe, mais ça prive du seul canal qui dirait pourquoi
ça échoue.

*Les pistes, de la plus probable à la moins probable :*

1. **La tâche n'était pas encore active.** OVH met parfois un certain
   temps à prendre en compte une tâche nouvellement créée. **Vérifier
   d'abord si le fichier est apparu depuis** — si oui, il n'y a rien à
   faire.
2. **Le chemin n'est pas celui qu'OVH attend.** `taches/tache_notifications.php`
   part de la racine de l'espace de stockage. Si OVH le résout à partir
   de `www/`, il ne trouve rien et échoue en silence.
3. **Réactiver temporairement l'email de compte-rendu**, laisser passer
   une heure, lire l'erreur, puis le redécocher. C'est le moyen le plus
   direct d'avoir la réponse.
4. Regarder dans l'espace client OVH si la tâche affiche une **date de
   dernière exécution** et un état.
5. `curl` absent ou désactivé dans le PHP du mutualisé — peu probable,
   mais ça se voit tout de suite avec le compte-rendu.

**Ce que ça bloque, et ce que ça ne bloque pas** : rien d'urgent. Le
filet ne sert qu'au rattrapage, et l'envoi immédiat fonctionne. Un
parent est prévenu en quelques secondes même si cette tâche ne tourne
pas. Ce qui serait perdu, c'est le rattrapage d'un envoi échoué.

**3. Retirer la consigne « domaine jeune »**, le jour venu. Deux
drapeaux à passer à `false` — `lib/textes/consigne_domaine_jeune.dart`
et `supabase/functions/_logique/consigne_domaine_jeune.mts`. Un test
refuse qu'ils diffèrent.

**Le critère, écrit pour ne pas avoir à le redécider** : un mail de
test vers une boîte neuve arrive en boîte de réception **sans que
personne ait rien marqué**. C'est le même test qu'au point 1.

**4. Le nom d'expéditeur** s'affiche « Kidsrelay » au lieu de
« KidsRelay ». Sans effet sur la délivrabilité, mais c'est la première
chose que lit un parent. Une ligne à corriger dans les secrets
Supabase : `BREVO_SENDER_NAME`.

**5. Les notifications sur écran verrouillé.** Le vrai sujet, et il
est entier. **Pour un message annonçant qu'un enfant part avec les
pompiers, l'email ne sera jamais une garantie** : le classement
appartient au fournisseur du destinataire, pas à nous. Les colonnes de
push existent déjà en base, prêtes.

### Ce qui reste à déployer d'autres chantiers

`consulter-partage` n'est **pas** à jour : le QR de partage (fenêtre
de cinq minutes) et l'écran de reprise attendent son déploiement, ainsi
que le dépôt de `index.html` chez OVH.

**Attention à l'ordre** : Fanny a décidé le 28/08 que la reprise
explicite **disparaît** au profit du blocage au quatrième appareil.
Déployer maintenant mettrait en ligne un écran qu'on va retirer. Voir
la section correspondante de `corrections_a_faire.md`.


## Ce qui est déployé — 01/09/2026

**Tout est en production.** Plus rien n'attend de déploiement, à une
exception près, signalée plus bas.

### Fonctions serveur

| Fonction | À jour |
|---|---|
| `consulter-partage` | oui |
| `declencher-acces-secours` | oui — **première mise en ligne**, l'accès secours depuis un lien ne fonctionnait pas avant |
| `envoyer-code-verification` | oui |
| `envoyer-notifications-maintenant` | oui |
| `envoyer-notifications-parent` | **non** — voir ci-dessous |
| `notifier-note-ajoutee`, `verifier-code`, `confirmer-suppression-compte` | oui, inchangées |

**Une commande reste à lancer, sans urgence :**

```
supabase functions deploy envoyer-notifications-parent --no-verify-jwt
```

Elle branche le ménage des demandes d'accès sans réponse. La fonction
`purger_demandes_acces_partage()` existait en base et **personne ne
l'appelait** — une purge que rien ne déclenche est une règle qui
n'existe pas. C'est branché dans le code, pas encore en ligne.

Aucune urgence : la règle des trente jours ne mord qu'au bout de
trente jours.

### Chez OVH

| | |
|---|---|
| `fiche/index.html` | à jour, 92 513 octets |
| `taches/tache_notifications.php` | déposé, tâche active, `18 * * * *`, PHP 8.2 |
| Zone DNS | correcte, **ne pas y toucher** |

Le journal `taches/dernier_passage.txt` a confirmé le fonctionnement le
01/09 à 10h18 : `code 200`, quatre zéros. Le silence des premières
heures venait du délai d'activation d'OVH, pas d'un défaut.

### Base de données

Tous les scripts sont appliqués et vérifiés, y compris
`schema_trois_appareils.sql`. La table
`evenements_notification_parent` est vide.

## Ce qui reste à vérifier en vrai

**1. Le vrai test de délivrabilité.** Créer une adresse **Gmail
neuve**, qui n'a jamais rien reçu de `kidsrelay.fr`, et y envoyer un
message. Les tests du 28/08 ne prouvent rien : l'expéditeur avait été
marqué comme légitime, le message ne pouvait qu'arriver.

**2. Le parcours complet des trois appareils**, jamais exercé en
production : ouvrir la fiche depuis trois navigateurs, revenir sur
chacun pour confirmer les places, puis tenter un quatrième et vérifier
que l'écran de demande s'affiche, que le mail arrive, et que le bouton
« Autoriser cet appareil » ouvre bien la porte.

**3. Le QR de partage sur un vrai téléphone** : scanner, vérifier que
la fenêtre du lecteur ne consomme pas de place, et que le code cesse
de fonctionner après cinq minutes.

## Ce qui reste à décider ou à faire

**Retirer la consigne « domaine jeune »**, le jour venu. Deux drapeaux
à passer à `false` — `lib/textes/consigne_domaine_jeune.dart` et
`supabase/functions/_logique/consigne_domaine_jeune.mts`. Un test
refuse qu'ils diffèrent.

**Le critère, écrit pour ne pas avoir à le redécider** : un mail de
test vers une boîte neuve arrive en boîte de réception **sans que
personne ait rien marqué**.

**Le nom d'expéditeur** s'affiche « Kidsrelay » au lieu de
« KidsRelay ». Une ligne dans les secrets Supabase :
`BREVO_SENDER_NAME`.

**Les places non confirmées s'accumulent.** Chaque navigateur qui
ouvre une fiche sans revenir laisse une ligne dans
`appareils_partage`. Elles ne comptent dans aucun plafond et ne
gênent rien, mais rien ne les efface. À surveiller si le volume
grandit.

**Les notifications sur écran verrouillé.** Le vrai sujet, et il est
entier. Pour un message annonçant qu'un enfant part avec les pompiers,
**l'email ne sera jamais une garantie** : le classement appartient au
fournisseur du destinataire. Les colonnes de push existent déjà en
base, prêtes.

## État du dépôt au 26/08/2026

| | |
|---|---|
| Branche | `main`, synchronisée avec `origin/main` |
| Tests Flutter | **578**, tous verts |
| Tests JavaScript | **120** pour les fonctions serveur, **29** pour la page auth |
| `flutter analyze` | propre |
| Dernier chantier | fonction du professionnel, vérifiée en production |

**Outillage installé sur le poste** (à savoir avant de chercher) :
`postgresql` 18.6 via scoop (`pg_dump`, `psql`, plus un serveur local
installé mais **arrêté** et non enregistré comme service), la CLI
Supabase, Node 24 avec `node --test`.

`supabase db dump` passe par **Docker**, qui n'est pas installé : le
dump se prend en récupérant le script via
`supabase db dump --linked --dry-run` puis en l'exécutant avec le
`pg_dump` natif. Corriger au passage `--quote-all-identifier` en
`--quote-all-identifiers` — la CLI affiche le singulier, `pg_dump`
attend le pluriel.
