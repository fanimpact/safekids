-- =====================================================================
-- KidsRelay - liens de partage : token genere automatiquement +
-- purge planifiee des partages expires depuis plus de 24h.
--
-- A executer APRES schema.sql (ou en complement si schema.sql a deja
-- ete execute avant cette mise a jour) : Dashboard -> SQL Editor ->
-- coller -> Run.
-- =====================================================================

-- Si la table "partages" existe deja sans valeur par defaut pour
-- "token" (creee avant cette mise a jour de schema.sql), on l'ajoute
-- ici. Sans effet si schema.sql vient d'etre execute avec la version
-- a jour.
alter table public.partages
  alter column token
  set default encode(gen_random_bytes(24), 'hex');

-- pg_cron doit etre active sur le projet. Si la ligne suivante echoue
-- avec une erreur de permission, active l'extension via le Dashboard :
-- Database -> Extensions -> rechercher "pg_cron" -> Enable, puis
-- relance uniquement le bloc "select cron.schedule(...)" ci-dessous.
create extension if not exists pg_cron;

-- Supprime tous les jours a 3h du matin les partages dont la date
-- d'expiration est depassee depuis plus de 24h. Remplace le job s'il
-- existe deja (evite les doublons si ce script est relance).
select cron.unschedule('supprimer-partages-expires')
where exists (
  select 1 from cron.job where jobname = 'supprimer-partages-expires'
);

select cron.schedule(
  'supprimer-partages-expires',
  '0 3 * * *',
  $$
    delete from public.partages
    where date_expiration < now() - interval '24 hours';
  $$
);
