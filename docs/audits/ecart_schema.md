# Écart entre la base réelle et les fichiers SQL du dépôt

**Date : 23/08/2026** — projet Supabase `xcugfdjaifdibwowlrpi` (`eu-central-1`)

Comparaison entre l'état réel de la base et les 17 fichiers `supabase/*.sql`,
appliqués à la main dans le SQL Editor depuis le début du projet.

Instantané de référence : [`supabase/_snapshot/schema_reel_2026-08-23.sql`](../../supabase/_snapshot/schema_reel_2026-08-23.sql)

**La base n'a été ni modifiée, ni touchée** — uniquement lue, par des
`SELECT` sur les catalogues.

Côté dépôt, l'audit est en lecture seule à **une exception près** : la
déclaration en double de `partages_geres_par_le_parent` dans `schema.sql`
a été retirée dans le même commit que ce rapport (voir §3). C'est la
seule modification, et elle ne change rien à l'état de la production.

---

## Verdict

**La base correspond aux fichiers.** Aucun objet créé à la main sans
équivalent versionné, aucun objet déclaré mais absent de la base, aucune
divergence de définition détectée sur les colonnes, les commandes des
politiques ou les fonctions.

Une seule zone reste **non vérifiable** : les tâches planifiées `pg_cron`
(voir §7).

| Catégorie | Base | Fichiers | Verdict |
|---|---|---|---|
| Tables | 16 | 16 | identiques |
| Colonnes | 150 | 150 | identiques |
| Vues | 0 | 0 | identiques |
| Triggers | 0 | 0 | identiques |
| Contraintes | 68 | déclarées en ligne | cohérentes |
| Index | 26 | 22 implicites + 4 explicites | identiques |
| Politiques RLS | 40 | 41 distinctes, 1 supprimée volontairement | cohérentes |
| Fonctions | 18 | 18 | identiques |
| Extensions | 6 | 2 déclarées, 4 par défaut Supabase | à connaître |
| Tâches `pg_cron` | ? | 2 déclarées | **non vérifiable** |

---

## Comment cet instantané a été produit

`supabase db dump` exécute `pg_dump` dans Docker. Ni `pg_dump`, ni `psql`,
ni Docker ne sont installés sur le poste — la commande échoue et laisse un
fichier vide.

L'instantané a donc été reconstruit en interrogeant directement les
catalogues PostgreSQL (`pg_class`, `pg_attribute`, `pg_constraint`,
`pg_indexes`, `pg_policies`, `pg_proc`, `pg_trigger`, `pg_extension`), via
le rôle de connexion temporaire que la CLI Supabase crée elle-même. Aucun
mot de passe de la base n'a été demandé ni conservé.

**Ce n'est donc pas un `pg_dump`.** Le contenu est fidèle, mais la mise en
forme diffère : ordre alphabétique, pas d'ordre de dépendances, pas de
`GRANT` ni de propriétaires. Le fichier est une **photographie destinée à
la comparaison**, pas un script rejouable en l'état.

Deux requêtes ont buté sur les privilèges du rôle temporaire :

- `information_schema.columns` renvoyait 0 ligne (ce catalogue filtre selon
  les droits). Contourné par `pg_attribute`, qui a bien rendu les 150
  colonnes.
- `cron.job` : `permission denied for schema cron`. Non contournable.

---

## 1. Objets présents en base, absents des fichiers

**Aucun**, sur les tables, colonnes, index, politiques et fonctions.

Vérifications croisées :

- Les 16 tables de la base sont toutes déclarées par un `create table` dans
  les fichiers.
- Les 150 colonnes de la base sont toutes déclarées.
- Les 26 index se répartissent en 22 adossés à une contrainte
  `primary key` / `unique` (créés automatiquement par PostgreSQL) et 4
  déclarés explicitement. **Aucun index orphelin.**
- Les 40 politiques et les 18 fonctions portent toutes un nom déclaré dans
  les fichiers.

### Extensions : 4 non déclarées, mais installées par Supabase

| Extension | Version | Schéma | Déclarée dans le dépôt |
|---|---|---|---|
| `pgcrypto` | 1.3 | `extensions` | oui — `partages_liens.sql` |
| `pg_cron` | 1.6.4 | `pg_catalog` | oui — 2 fichiers |
| `plpgsql` | 1.0 | `pg_catalog` | non — livrée avec PostgreSQL |
| `pg_stat_statements` | 1.11 | `extensions` | non — activée par Supabase |
| `supabase_vault` | 0.3.1 | `vault` | non — activée par Supabase |
| `uuid-ossp` | 1.1 | `extensions` | non — activée par Supabase |

Les quatre non déclarées font partie de l'installation standard d'un projet
Supabase. Aucune n'est utilisée par le code : les identifiants viennent de
`gen_random_uuid()` (`pgcrypto`), jamais de `uuid_generate_v4()`.

**Schémas présents** : `auth`, `cron`, `extensions`, `graphql`,
`graphql_public`, `public`, `realtime`, `storage`, `vault`. Seul `public`
est peuplé par le projet. `storage` et `realtime` existent mais sont vides
d'usage, ce qui confirme l'inventaire précédent.

---

## 2. Objets présents dans les fichiers, absents de la base

**Un seul, et c'est voulu.**

### `masquages_du_lecteur` — politique supprimée volontairement

Créée par `schema_espace_professionnel_activites.sql:154`, puis
explicitement retirée par `schema_masquages_lecture_visibilite.sql:24` :

```sql
drop policy if exists "masquages_du_lecteur"
```

Elle est remplacée par quatre politiques plus fines sur la même table
`activites_recommandations_masquees` : `masquages_lecture`,
`masquages_ecriture_insert`, `masquages_ecriture_update`,
`masquages_suppression`. Les quatre sont bien en base.

**Ce n'est pas un écart** : les fichiers décrivent une histoire, la base en
reflète le dernier état.

C'est aussi ce qui explique l'écart de comptage vu dans l'inventaire du
22/08 : les fichiers contenaient alors **42 instructions** `create policy`
pour **41 noms distincts** (un doublon, corrigé depuis — voir §3), dont
**40 subsistent** en base. Après correction : 41 instructions, 41 noms,
40 en base.

---

## 3. Divergences de définition

### Colonnes : aucune

Les 150 colonnes concordent, table par table, en nom comme en présence.

Une première passe automatique avait signalé des colonnes `references` et
`default` « présentes dans les fichiers, absentes de la base » sur 7
tables. Vérification faite, ce sont des **artefacts de mon analyseur** :
des lignes de continuation d'une définition de colonne étalée sur
plusieurs lignes, par exemple `schema.sql:119-120` :

```sql
  token text not null unique
    default encode(gen_random_bytes(24), 'hex'),
```

Le mot `default` en début de ligne avait été pris pour un nom de colonne.
**Aucune colonne réelle n'est en écart.**

### Politiques : la commande concorde pour les 40

Pour chacune des 40 politiques, la commande en base (`SELECT`, `INSERT`,
`UPDATE`, `DELETE`, `ALL`) correspond au `for …` du fichier. Toutes sont
`PERMISSIVE` et s'appliquent au rôle `public`.

**Limite de méthode, à connaître** : PostgreSQL réécrit et normalise les
expressions `USING` / `WITH CHECK`. Une comparaison texte à texte avec les
fichiers produirait des différences de forme sur toutes les politiques,
sans signifier de divergence réelle. La comparaison porte donc sur ce qui
est comparable de façon fiable — existence, commande, caractère permissif,
rôles, et présence de `auth.uid()`. **Une différence de logique interne
subtile ne serait pas détectée par cette méthode.**

### Un cas où la base tranchait entre deux versions — corrigé

`partages_geres_par_le_parent` était déclarée **deux fois** dans les
fichiers, avec deux définitions différentes :

| Source | Définition |
|---|---|
| `schema.sql:136` *(obsolète)* | `enfant_id in (select id from enfants where parent_id = auth.uid())` |
| `schema_partages_rls_security_definer.sql:20` *(en vigueur)* | `public.enfant_du_parent(enfant_id)` |

**La base porte la seconde** — vérifié : `using` et `with check` valent
tous deux `enfant_du_parent(enfant_id)`. C'est bien le dernier fichier
appliqué qui l'emporte. Mais un lecteur qui ouvrait `schema.sql` seul en
tirait la conclusion inverse, et rejouer ce fichier aurait réécrit la
policy avec sa version périmée.

**Corrigé le 23/08/2026, dans le même commit que ce rapport** : la
déclaration obsolète a été retirée de `schema.sql` et remplacée par un
commentaire renvoyant au fichier qui fait foi. **La base n'a pas été
touchée** — le fichier `security_definer`, déjà appliqué, reste la
source de vérité, et le retrait ne change rien à l'état en production.

Après correction, les fichiers contiennent **41 instructions**
`create policy` pour **41 noms distincts** : plus aucun doublon dans le
dépôt.

### Fonctions : les 18 concordent

Chacune des 18 fonctions de la base est déclarée dans **exactement un**
fichier — aucune déclaration en double, donc aucune ambiguïté sur la
version qui s'applique.

---

## 4. Les 40 politiques RLS, une par une

`auth.uid` = la définition en base appelle directement `auth.uid()`.
Un `—` signifie qu'elle délègue à une fonction `security definer`, qui
l'appelle en interne.

| Table | Politique | Cmd | `auth.uid()` | Fichier source | Concorde |
|---|---|---|---|---|---|
| activites_preparees | activites_creation_par_membre | INSERT | oui | espace_professionnel_activites | ✔ |
| activites_preparees | activites_du_parent | ALL | oui | espace_professionnel_activites | ✔ |
| activites_preparees | activites_lecture_par_membre | SELECT | — | espace_professionnel_activites | ✔ |
| activites_preparees | activites_modification_par_membre | UPDATE | — | espace_professionnel_activites | ✔ |
| activites_preparees | activites_suppression_par_membre | DELETE | — | espace_professionnel_activites | ✔ |
| activites_recommandations_masquees | masquages_ecriture_insert | INSERT | oui | masquages_lecture_visibilite | ✔ |
| activites_recommandations_masquees | masquages_ecriture_update | UPDATE | oui | masquages_lecture_visibilite | ✔ |
| activites_recommandations_masquees | masquages_lecture | SELECT | oui | masquages_lecture_visibilite | ✔ |
| activites_recommandations_masquees | masquages_suppression | DELETE | oui | masquages_lecture_visibilite | ✔ |
| appareils_reconnus | appareils_du_compte | ALL | oui | espace_professionnel_comptes | ✔ |
| comptes_parents | comptes_parents_creation_propre | INSERT | oui | espace_professionnel_comptes | ✔ |
| comptes_parents | comptes_parents_lecture_propre | SELECT | oui | espace_professionnel_comptes | ✔ |
| comptes_parents | comptes_parents_maj_propre | UPDATE | oui | espace_professionnel_comptes | ✔ |
| enfants | enfants_du_parent | ALL | oui | schema | ✔ |
| enfants | enfants_modifiables_par_personne_de_confiance | UPDATE | — | partage_confiance | ✔ |
| enfants | enfants_visibles_par_etablissement | SELECT | — | espace_professionnel_etablissements | ✔ |
| enfants | enfants_visibles_par_personne_de_confiance | SELECT | — | partage_confiance | ✔ |
| enfants_confiance | enfants_confiance_lecture | SELECT | oui | partage_confiance | ✔ |
| enfants_etablissements | enfants_etablissements_du_parent | ALL | — | espace_professionnel_etablissements | ✔ |
| enfants_etablissements | enfants_etablissements_lecture_par_membre | SELECT | — | espace_professionnel_etablissements | ✔ |
| enfants_etablissements | enfants_etablissements_lecture_token_en_attente | SELECT | — | espace_professionnel_etablissements | ✔ |
| etablissements | etablissements_visibles_par_membre_actif | SELECT | — | espace_professionnel_etablissements | ✔ |
| etablissements | etablissements_visibles_par_parent_enfant_rattache | SELECT | — | espace_professionnel_etablissements | ✔ |
| evenements_notification_parent | evenements_notification_lecture_par_parent | SELECT | oui | espace_professionnel_notifications | ✔ |
| journal_consultations_fiche | journal_ecriture_par_membre_actif | INSERT | oui | espace_professionnel_fiches | ✔ |
| journal_consultations_fiche | journal_lecture_par_parent | SELECT | — | journal_consultations_lecture_parent | ✔ |
| membres_etablissement | membres_lecture_par_membre_actif_ou_soi_meme | SELECT | oui | espace_professionnel_etablissements | ✔ |
| notes_activite | notes_creation_par_membre | INSERT | oui | espace_professionnel_activites | ✔ |
| notes_activite | notes_lecture_auteur_ou_parent | SELECT | oui | espace_professionnel_activites | ✔ |
| notes_activite | notes_modification_par_auteur | UPDATE | oui | espace_professionnel_activites | ✔ |
| notes_activite | notes_suppression_par_auteur | DELETE | oui | espace_professionnel_activites | ✔ |
| partages | partages_geres_par_le_parent | ALL | — | partages_rls_security_definer | ✔ |
| profils_activites | profils_activites_du_parent | ALL | oui | schema | ✔ |
| profils_activites | profils_activites_modifiables_par_personne_de_confiance | UPDATE | — | partage_confiance | ✔ |
| profils_activites | profils_activites_visibles_par_etablissement | SELECT | — | espace_professionnel_fiches | ✔ |
| profils_activites | profils_activites_visibles_par_personne_de_confiance | SELECT | — | partage_confiance | ✔ |
| profils_sante | profils_sante_du_parent | ALL | oui | schema | ✔ |
| profils_sante | profils_sante_modifiables_par_personne_de_confiance | UPDATE | — | partage_confiance | ✔ |
| profils_sante | profils_sante_visibles_par_etablissement | SELECT | — | espace_professionnel_fiches | ✔ |
| profils_sante | profils_sante_visibles_par_personne_de_confiance | SELECT | — | partage_confiance | ✔ |

**41ᵉ** : `masquages_du_lecteur`, supprimée volontairement (§2).

RLS est **activée sur les 16 tables**. Aucune table n'est exposée sans
politique.

---

## 5. Les 18 fonctions, une par une

Toutes sont `security definer` et déclarées dans un seul fichier.

| Fonction | Langage | Fichier source | Concorde |
|---|---|---|---|
| enfant_confie_a | sql | partage_confiance | ✔ |
| enfant_du_parent | sql | espace_professionnel_etablissements | ✔ |
| enfant_visible_par_etablissement | sql | espace_professionnel_etablissements | ✔ |
| est_membre_actif | sql | espace_professionnel_etablissements | ✔ |
| etablissement_du_parent | sql | espace_professionnel_etablissements | ✔ |
| nombre_gestionnaires_actifs | sql | espace_professionnel_invitations | ✔ |
| peut_gerer_membres | sql | espace_professionnel_invitations | ✔ |
| rpc_activer_confiances_en_attente | plpgsql | partage_confiance | ✔ |
| rpc_activer_invitations_en_attente | plpgsql | espace_professionnel_invitations | ✔ |
| rpc_assurer_identite_email | plpgsql | espace_professionnel_identites | ✔ |
| rpc_changer_niveau_confiance | plpgsql | partage_confiance | ✔ |
| rpc_changer_role_membre | plpgsql | espace_professionnel_invitations | ✔ |
| rpc_creer_etablissement | plpgsql | espace_professionnel_etablissements | ✔ |
| rpc_inviter_membre | plpgsql | espace_professionnel_invitations | ✔ |
| rpc_inviter_personne_confiance | plpgsql | partage_confiance | ✔ |
| rpc_reclamer_rattachement | plpgsql | espace_professionnel_etablissements | ✔ |
| rpc_revoquer_confiance | plpgsql | partage_confiance | ✔ |
| rpc_revoquer_membre | plpgsql | espace_professionnel_invitations | ✔ |

Le corps complet de chaque fonction, tel qu'il existe en base, figure dans
l'instantané — c'est la référence en cas de doute sur une version.

**Limite** : la concordance porte sur l'existence, la signature, le langage
et le mode `security definer`. Le corps n'a pas été comparé ligne à ligne
avec les fichiers, PostgreSQL le réécrivant à l'enregistrement.

---

## 6. Index

| Type | Nombre | Détail |
|---|---|---|
| Adossés à une contrainte | 22 | créés automatiquement par les `primary key` et `unique` |
| Déclarés explicitement | 4 | voir ci-dessous |
| Sans origine identifiée | **0** | |

Les 4 explicites : `codes_verification_expire_le_idx`,
`journal_consultations_consulte_le_idx`, `profils_activites_enfant_id_key`,
`profils_sante_enfant_id_key`.

Les deux derniers sont les index uniques ajoutés par `schema_updates.sql`
pour permettre les `upsert … on conflict (enfant_id)` côté application.

---

## 7. Le point non vérifiable : `pg_cron`

Le rôle temporaire de la CLI n'a pas accès au schéma `cron` :

```
permission denied for schema cron
```

**Impossible de dire si les tâches planifiées existent, sont actives, ou
correspondent aux fichiers.** Deux sont déclarées :

| Tâche | Fréquence | Fichier |
|---|---|---|
| `supprimer-partages-expires` | `0 3 * * *` | `partages_liens.sql:32` |
| `purge-journal-consultations-fiche` | 12 mois | `schema_espace_professionnel_fiches.sql:88` |

L'extension `pg_cron` **est bien installée** (v1.6.4) — ça, c'est vérifié.
Mais son installation ne dit rien de la programmation des tâches.

Le second fichier enveloppe d'ailleurs sa programmation dans un
`do $$ … exception when others then null; end $$`, qui **avale toute
erreur en silence**. Si cette tâche n'a pas été créée, rien ne l'aura
signalé, et le journal des consultations n'est jamais purgé.

**Pour trancher**, dans le SQL Editor du tableau de bord :

```sql
select jobid, jobname, schedule, active from cron.job order by jobname;
```

C'est le seul point de cet audit qui reste ouvert.

---

## 8. Ce que cet audit ne couvre pas

Trois catégories restent hors de portée d'une comparaison de schéma, et
n'ont **aucun équivalent versionné dans le dépôt** :

- **Configuration Auth** : modèles d'email, Redirect URLs, durées
  d'expiration des jetons et des sessions.
- **Secrets des Edge Functions** : `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`,
  `BREVO_SENDER_NAME`, `BREVO_REPLY_TO_EMAIL`.
- **Code des Edge Functions** : versionné dans `supabase/functions/`, mais
  le déploiement est manuel et rien ne garantit que la version déployée
  correspond au dépôt — même problème que la page web
  `auth.kidsrelay.fr`, qui a son propre contrôle
  (`web_auth/verifier-deploiement.mjs`).

---

## 9. Comment refaire cette photographie

L'instantané est daté et ne se met pas à jour tout seul. Il vaut pour le
**23/08/2026** et se périmera à la première instruction lancée dans le SQL
Editor.

La CLI Supabase suffit dès lors que **Docker Desktop** est installé :

```
supabase db dump --linked -f supabase/_snapshot/schema_reel_AAAA-MM-JJ.sql
```

Sans Docker, la méthode employée ici — interroger les catalogues avec le
rôle temporaire de la CLI — reste applicable, mais elle demande un client
PostgreSQL installé hors du dépôt.
