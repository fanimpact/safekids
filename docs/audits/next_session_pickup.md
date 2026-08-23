# Où nous en sommes — point de reprise

**Dernière mise à jour : 23/08/2026**

Document de reprise : à lire en premier au début d'une session pour
savoir ce qui est fait, ce qui attend, et ce qui bloque. À tenir à jour
plutôt qu'à laisser vieillir.

---

## En une phrase

Le socle technique est **prêt à être quitté** : le schéma est figé et
versionné, les prérequis d'une base cible sont documentés, et
l'authentification est isolée derrière une interface unique. **Rien ne
bouge tant que Clever Cloud n'a pas répondu sur l'hébergement HDS.**

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
  qu'en spam.
- **Modèles d'email Supabase** — à coller dans le tableau de bord pour
  que les liens pointent vers `auth.kidsrelay.fr` (contenu exact fourni
  en session, non encore appliqué au 23/08/2026).
- **Doublon d'affichage de l'équipement** sur la fiche d'activité (bloc
  de situation + récapitulatif « Matériel à prévoir »). Comportement
  existant, signalé, jugé volontaire — à confirmer.

---

## État du dépôt au 23/08/2026

| | |
|---|---|
| Branche | `main`, synchronisée avec `origin/main` |
| Tests | **309**, tous verts |
| `flutter analyze` | propre |
| Dernier commit | `3352252` — tests du câblage d'authentification |

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
