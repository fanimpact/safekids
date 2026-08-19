-- =====================================================================
-- SafeKids - le parent peut lire le journal des consultations de son
-- enfant (qui a consulte quelle fiche, quand) -- corrections de
-- l'audit passe 1 (RGPD), point "journal des consultations illisible
-- par le parent". Jusqu'ici, aucune policy SELECT n'existait sur
-- cette table pour personne : le personnel ne doit toujours pas la
-- lire (tracabilite invisible au quotidien, comme prevu), seul le
-- parent concerne le peut desormais.
--
-- Script idempotent (policy precedee d'un "drop policy if exists").
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite schema_espace_professionnel_fiches.sql (deja execute).
-- =====================================================================

drop policy if exists "journal_lecture_par_parent"
  on public.journal_consultations_fiche;

create policy "journal_lecture_par_parent"
  on public.journal_consultations_fiche
  for select
  using (public.enfant_du_parent(enfant_id));
