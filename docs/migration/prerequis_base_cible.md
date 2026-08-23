# Prérequis d'une base PostgreSQL cible

**État des lieux au 23/08/2026. Ce n'est pas un plan de migration.**

Ce document répond à une seule question : *que devrait fournir une base
PostgreSQL non-Supabase pour que
[`schema_dump_2026-08-23.sql`](../../supabase/_snapshot/schema_dump_2026-08-23.sql)
s'applique ?*

Aucun hébergeur n'est retenu à ce jour. Les équivalents proposés sont
donnés à titre factuel, sans préconisation.

## D'où viennent ces constats

Le dump a été **rejoué le 23/08/2026 sur un PostgreSQL 18.6 vierge**
(installé localement via Scoop, sans aucune extension). Résultat :

```
178 erreurs — 14 tables créées sur 16
```

Répartition :

| Cause | Nombre |
|---|---|
| `role "…" does not exist` | 108 |
| `schema "…" does not exist` | 44 |
| `relation "…" does not exist` | 23 |
| `extension "…" is not available` | 2 |
| `publication "…" does not exist` | 1 |

Chaque point ci-dessous découle de ces erreurs observées, pas d'une
lecture théorique du dump.

---

## 1. Les trois rôles : `anon`, `authenticated`, `service_role`

### Ce que le dump en fait exactement

**108 des 178 erreurs** viennent de leur absence. Chacun reçoit
**38 `GRANT`** :

```sql
GRANT ALL ON TABLE "public"."activites_preparees" TO "anon";
GRANT ALL ON TABLE "public"."activites_preparees" TO "authenticated";
GRANT ALL ON TABLE "public"."activites_preparees" TO "service_role";
```

### Le point à ne pas se tromper : les politiques RLS ne les nomment pas

C'est contre-intuitif, et c'est vérifié : **aucune des 40 politiques ne
cible un rôle**. Le dump ne contient pas une seule clause `TO "anon"` dans
un `CREATE POLICY`. Toutes s'appliquent implicitement à `PUBLIC` :

```sql
CREATE POLICY "enfants_du_parent" ON "public"."enfants"
  USING (("parent_id" = "auth"."uid"()))
  WITH CHECK (("parent_id" = "auth"."uid"()));
```

Le filtrage ne repose donc **jamais sur l'identité du rôle PostgreSQL**,
mais uniquement sur `auth.uid()` — voir §2.

### Rôle par rôle

| Rôle | Utilisé par | Fonction |
|---|---|---|
| `anon` | requêtes portant la clé publique sans session | Chez KidsRelay, l'app crée une **session anonyme Supabase** dès le premier lancement (`lib/auth/app_auth.dart`), donc les requêtes passent presque toujours par `authenticated`. |
| `authenticated` | requêtes portant un JWT valide | Le rôle nominal de l'application, session anonyme comprise. |
| `service_role` | Edge Functions, contourne la RLS | Utilisé par `envoyer-code-verification`, `verifier-code`, `consulter-partage`, `notifier-note-ajoutee` via `SUPABASE_SERVICE_ROLE_KEY`. |

### Hors Supabase

Ces rôles n'ont rien de spécifique à Supabase : ce sont des rôles
PostgreSQL ordinaires, que `CREATE ROLE` suffit à créer. Ce qui est
spécifique, c'est **le mécanisme qui fait qu'une requête arrive sous l'un
ou l'autre** : le proxy PostgREST de Supabase lit le JWT, en déduit le
rôle et exécute `SET LOCAL ROLE`.

Hors Supabase, il faudrait soit reproduire ce comportement dans la couche
d'accès, soit — puisque les politiques ne s'appuient jamais sur le rôle —
n'en conserver qu'un seul et porter l'identité autrement (§2). Les
`GRANT ALL` du dump peuvent alors être réécrits en conséquence.

---

## 2. Les schémas attendus : `auth` et `extensions`

**44 erreurs.** Ce sont les deux seuls schémas hors `public` que le dump
référence.

### `auth` — le plus structurant

Deux usages distincts, tous deux vérifiés dans le dump :

**a) `auth.uid()` — 33 occurrences**, dans les politiques RLS et les
fonctions `security definer`. C'est **le pivot de tout le cloisonnement
des données** : elle rend l'identifiant de l'utilisateur porté par le JWT
de la requête en cours.

**b) `auth.users` — 19 clés étrangères** pointant vers `auth.users(id)` :

```sql
REFERENCES "auth"."users"("id")
```

La table des comptes appartient à Supabase Auth (GoTrue). Le schéma
applicatif s'y raccroche : `enfants.parent_id`, `comptes_parents.user_id`,
`membres_etablissement.user_id`, etc.

**c) `auth.jwt()` — 3 occurrences**, dans les corps de trois fonctions
(`rpc_reclamer_rattachement`, `rpc_activer_invitations_en_attente`,
`rpc_activer_confiances_en_attente`), pour extraire l'email :

```sql
v_email := auth.jwt() ->> 'email';
```

### Hors Supabase

`auth.uid()` et `auth.jwt()` ne sont pas des fonctions PostgreSQL : ce
sont des fonctions SQL que Supabase installe, et qui lisent des
paramètres de session posés par son proxy
(`current_setting('request.jwt.claims')`). Elles sont réimplémentables —
c'est du SQL ordinaire — mais **quelque chose doit alimenter le paramètre
de session à chaque requête**. C'est ce mécanisme, pas la fonction, qui
constitue la vraie dépendance.

`auth.users` suppose de disposer d'un fournisseur d'identité et d'une
table de comptes. Les 19 clés étrangères devraient pointer vers elle.
L'inventaire du 22/08 recense par ailleurs tout ce que l'application
attend de Supabase Auth : inscription, connexion, mot de passe oublié,
session anonyme, PKCE, `token_hash`.

**C'est le point le plus lourd de cette liste.** Il ne se résume pas à
créer un schéma.

### `extensions`

Beaucoup plus modeste : **un seul objet y est cherché**,
`extensions.gen_random_bytes` (§4). C'est le schéma où Supabase installe
`pgcrypto`, `pg_stat_statements` et `uuid-ossp`. Hors Supabase, il suffit
que la fonction existe à l'endroit attendu, ou que les deux valeurs par
défaut concernées soient réécrites.

---

## 3. Les extensions : deux utiles, trois par héritage

Le dump déclare cinq extensions. Toutes ne se valent pas.

| Extension | Schéma | L'application s'en sert ? |
|---|---|---|
| `pgcrypto` | `extensions` | **Oui** — `gen_random_bytes` (§4) |
| `pg_cron` | `pg_catalog` | **Oui** — 2 tâches planifiées |
| `pg_stat_statements` | `extensions` | Non — observabilité de la plateforme |
| `supabase_vault` | `vault` | Non — héritage Supabase |
| `uuid-ossp` | `extensions` | Non — voir ci-dessous |

### `pgcrypto` — requis

Fournit `gen_random_bytes(24)`, qui génère les jetons de partage et de
rattachement. **Vérifié sur PostgreSQL 18.6 nu** : la fonction n'existe
pas sans l'extension.

```
ERROR: function gen_random_bytes(integer) does not exist
```

Disponible en standard dans toute distribution PostgreSQL.

### `pg_cron` — requis pour la rétention

Deux tâches, vérifiées actives le 23/08/2026 (voir
[`../audits/retention_journal_consultations.md`](../audits/retention_journal_consultations.md)) :

| Tâche | Fréquence | Rôle |
|---|---|---|
| `purge-journal-consultations-fiche` | `0 3 * * *` | supprime les entrées de plus de 12 mois — **pièce du dossier RGPD** |
| `supprimer-partages-expires` | `0 3 * * *` | supprime les partages expirés depuis plus de 24 h |

`pg_cron` n'est pas toujours proposé par les hébergeurs managés. À défaut,
ces purges devraient être déclenchées depuis l'extérieur (tâche planifiée
appelant le `DELETE`). **Ce point a une portée réglementaire, pas
seulement technique** : la durée de conservation annoncée en dépend.

### `uuid-ossp` — présente mais inutile

Déclarée par le dump, **jamais utilisée**. Les 15 clés primaires reposent
sur `gen_random_uuid()`, **jamais sur `uuid_generate_v4()`**.

Et `gen_random_uuid()` **ne nécessite aucune extension** : vérifié sur le
PostgreSQL 18.6 nu, elle se trouve dans `pg_catalog`. Elle est intégrée au
cœur de PostgreSQL depuis la version 13.

### `supabase_vault` et la publication `supabase_realtime` — héritage pur

Ni l'un ni l'autre n'est utilisé par l'application. L'inventaire du 22/08
a confirmé **zéro usage de Realtime** dans tout le dépôt : aucun
`channel()`, aucun `subscribe()`.

La publication n'est d'ailleurs même pas créée par le dump — il ne
contient qu'une ligne orpheline :

```sql
ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";
```

Ces deux éléments sont supprimables sans conséquence fonctionnelle.

---

## 4. Les objets qui échouent, et pourquoi

Sur base nue, **2 tables sur 16 ne se créent pas** : `partages` et
`enfants_etablissements`. Les 23 erreurs `relation … does not exist` qui
suivent en découlent — ce sont les contraintes et politiques portant sur
ces deux tables.

### La cause, identique pour les deux

```sql
"token" "text" DEFAULT "encode"("extensions"."gen_random_bytes"(24), 'hex'::"text") NOT NULL,
```

La valeur par défaut appelle une fonction **qualifiée par son schéma**.
Si `extensions` n'existe pas, l'instruction `CREATE TABLE` échoue en
entier.

### Ce que ces deux colonnes portent

| Table | Rôle du jeton |
|---|---|
| `partages` | jeton d'un lien de partage de fiche, envoyé à un accompagnant |
| `enfants_etablissements` | jeton de rattachement d'un enfant à un établissement |

Ce sont des secrets à usage unique. Les 24 octets aléatoires encodés en
hexadécimal donnent 48 caractères.

### Hors Supabase

Trois voies factuelles, sans préconisation :

1. **Créer le schéma `extensions`** et y installer `pgcrypto`. Le dump
   s'applique alors sans modification.
2. **Installer `pgcrypto` dans `public`** et retirer la qualification
   `extensions.` des deux valeurs par défaut.
3. **Remplacer la génération du jeton**, par exemple par
   `encode(sha256(...), 'hex')` ou une génération côté application. Cela
   modifie le format des jetons — les liens déjà émis restent valides,
   puisque seule la valeur par défaut change.

---

## Récapitulatif

| Prérequis | Vraiment nécessaire | Difficulté hors Supabase |
|---|---|---|
| Rôles `anon` / `authenticated` / `service_role` | Oui, pour les `GRANT` | Faible — mais le routage par JWT est à reproduire |
| `auth.uid()` | **Oui, critique** | **Élevée** — dépend d'un paramètre de session posé par le proxy |
| `auth.users` | **Oui, critique** | **Élevée** — 19 clés étrangères, suppose un fournisseur d'identité |
| `auth.jwt()` | Oui, 3 fonctions | Moyenne — même mécanisme que `auth.uid()` |
| Schéma `extensions` | Oui | Faible |
| `pgcrypto` | Oui | Faible |
| `pg_cron` | Oui — **portée RGPD** | Variable selon l'hébergeur |
| `uuid-ossp` | **Non** | — |
| `supabase_vault` | **Non** | — |
| Publication `supabase_realtime` | **Non** | — |

**Le poids réel n'est pas dans le schéma, il est dans l'authentification.**
Rôles, extensions et schémas se recréent en quelques instructions. Ce qui
ne se recrée pas d'une ligne, c'est `auth.uid()` et la table de comptes
sur laquelle 19 clés étrangères s'appuient.

## Ce que ce document ne couvre pas

- **Les données.** Le dump est `--schema-only`. Le transfert des comptes
  existants (`auth.users`) est un sujet distinct, et le plus délicat.
- **Les Edge Functions.** Quatre d'entre elles utilisent
  `SUPABASE_SERVICE_ROLE_KEY` et `SUPABASE_URL` ; deux appellent Brevo.
  Voir l'inventaire du 22/08.
- **Le client Flutter.** 19 fichiers `.dart` importent `supabase_flutter`,
  dont 30 accès `auth`. Voir l'inventaire du 22/08.
- **Le choix d'un hébergeur**, ses conditions et sa conformité RGPD.
