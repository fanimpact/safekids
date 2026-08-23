# Où nous en sommes — point de reprise

**Dernière mise à jour : 24/08/2026**

Document de reprise : à lire en premier au début d'une session pour
savoir ce qui est fait, ce qui attend, et ce qui bloque. À tenir à jour
plutôt qu'à laisser vieillir.

---

> ## ⚠️ Six fonctions serveur à redéployer
>
> **Depuis le 23/08/2026**, les six Edge Functions ont été
> réorganisées dans le dépôt : la logique métier est sortie des
> fichiers déployés, vers `supabase/functions/_logique/`.
> **Aucune n'a été redéployée.** Les cinq fonctions en ligne tournent
> encore la version d'avant cette date.
>
> Le décalage est assumé et sans effet sur la production tant qu'aucun
> déploiement n'est lancé. Mais contrairement à `auth.kidsrelay.fr`,
> **aucun vérificateur** ne peut comparer ce qui tourne à ce qui est
> versionné.
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
> aux trois premières ouvrirait à n'importe qui des fonctions qui
> écrivent en base.
>
> Le bundling des modules partagés n'a **pas pu être vérifié en local**
> (Docker absent de ce poste). Commencer par `consulter-partage`, la
> moins risquée à casser.
>
> Détail complet : [`../migration/fonctions_serveur.md`](../migration/fonctions_serveur.md).

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

### Reste ouvert depuis les sessions précédentes

- **SPF / DKIM / DMARC de `kidsrelay.fr` dans Brevo** — les Edge
  Functions ont été redéployées avec `contact@kidsrelay.fr`, mais rien
  ne confirme que les emails arrivent en boîte de réception plutôt
  qu'en spam. Indépendant de tout choix d'hébergeur : c'est de la
  configuration DNS du domaine, à faire côté Fanny.
- **Modèles d'email Supabase** — à coller dans le tableau de bord pour
  que les liens pointent vers `auth.kidsrelay.fr` (contenu exact fourni
  en session, non encore appliqué au 23/08/2026).
- **Doublon d'affichage de l'équipement** sur la fiche d'activité (bloc
  de situation + récapitulatif « Matériel à prévoir »). Comportement
  existant, signalé, jugé volontaire — à confirmer.

---

## État du dépôt au 24/08/2026

| | |
|---|---|
| Branche | `main`, synchronisée avec `origin/main` |
| Tests Flutter | **448**, tous verts |
| Tests JavaScript | **99** pour les fonctions serveur, **29** pour la page auth |
| `flutter analyze` | propre |
| Dernier chantier | conformité RGPD, 8 commits |

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
