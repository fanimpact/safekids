# Rétention du journal des consultations de fiches — pièce RGPD

**Élément à conserver au dossier RGPD.**

## Ce qui est attesté

La table `public.journal_consultations_fiche` enregistre, pour chaque
consultation d'une fiche d'enfant par un membre d'établissement, qui a
consulté quoi et quand. C'est une donnée de traçabilité, rattachée à un
enfant et à une personne identifiée.

**Sa purge automatique à 12 mois est vérifiée active au 23/08/2026.**

| | |
|---|---|
| Durée de conservation | **12 mois** |
| Mécanisme | tâche `pg_cron` `purge-journal-consultations-fiche` (jobid 3) |
| Fréquence d'exécution | tous les jours à 3 h — `0 3 * * *` |
| État constaté | `active = true` |
| Date de vérification | **23/08/2026** |
| Méthode | requête `select … from cron.job` exécutée par Fanny dans le SQL Editor du tableau de bord Supabase |
| Base concernée | projet `xcugfdjaifdibwowlrpi`, région `eu-central-1` (Francfort, UE) |

La suppression est portée par la clause `where` de la tâche, définie dans
[`schema_espace_professionnel_fiches.sql:100-103`](../../supabase/schema_espace_professionnel_fiches.sql) :

```sql
delete from public.journal_consultations_fiche
where consulte_le < now() - interval '12 months';
```

La tâche tourne donc **quotidiennement** et retire, à chaque passage, les
entrées de plus de 12 mois. Aucune entrée ne peut dépasser 12 mois et un
jour.

## Comment cette vérification a été obtenue

Elle **ne provient pas** de l'audit de schéma automatisé du 23/08/2026
([`ecart_schema.md`](ecart_schema.md)). Le rôle de connexion temporaire
utilisé par cet audit n'a pas accès au schéma `cron` :

```
permission denied for schema cron
```

Le point est resté ouvert jusqu'à ce que Fanny exécute la requête
elle-même, depuis le SQL Editor du tableau de bord, avec un rôle disposant
des droits nécessaires :

```sql
select jobid, jobname, schedule, active from cron.job order by jobname;
```

Résultat obtenu :

```
jobid 3 — purge-journal-consultations-fiche — 0 3 * * * — active true
jobid 2 — supprimer-partages-expires        — 0 3 * * * — active true
```

Cette distinction compte pour le dossier : **l'attestation repose sur une
observation directe de la base de production**, pas sur une déduction
tirée des fichiers du dépôt.

## Pourquoi cette pièce est nécessaire

La programmation de cette tâche est enveloppée, dans
[`schema_espace_professionnel_fiches.sql:105-106`](../../supabase/schema_espace_professionnel_fiches.sql),
dans un bloc qui **avale toute erreur en silence** :

```sql
exception when others then
  raise notice 'Programmation de la purge automatique impossible (pg_cron indisponible).';
```

Si la tâche n'avait pas été créée — extension indisponible, droits
insuffisants, script interrompu — rien ne l'aurait signalé. Ni à
l'exécution du script, ni ensuite. Le journal aurait grossi indéfiniment,
sans purge et sans alerte, et la durée de conservation annoncée n'aurait
pas été tenue.

**C'est précisément pour écarter ce scénario que la vérification a été
faite, et qu'elle est consignée ici.**

## Ce que cette pièce ne couvre pas

- Elle atteste d'un **état à une date**. Une réinitialisation de la base,
  une restauration de sauvegarde ou une désactivation de `pg_cron`
  invalideraient le constat sans avertissement.
- Elle ne couvre **que cette table**. La seconde tâche,
  `supprimer-partages-expires`, purge les liens de partage expirés depuis
  plus de 24 h (`partages_liens.sql:32`) ; elle est active elle aussi, mais
  relève d'une autre finalité.
- Les **sauvegardes automatiques de Supabase** peuvent conserver des
  entrées purgées au-delà de 12 mois, selon la politique de rétention du
  plan souscrit. Ce point n'a pas été instruit.

## À refaire

Cette vérification n'a pas de mécanisme de contrôle automatique — aucune
alerte ne se déclenchera si la tâche disparaît. **La rejouer
périodiquement**, et en tout cas après toute restauration de sauvegarde ou
changement de plan Supabase :

```sql
select jobid, jobname, schedule, active from cron.job order by jobname;
```

Consigner la date et le résultat dans ce fichier à chaque passage.

| Date | Résultat | Par |
|---|---|---|
| 23/08/2026 | jobid 3, `0 3 * * *`, active `true` | Fanny, SQL Editor |
