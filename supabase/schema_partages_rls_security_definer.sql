-- =====================================================================
-- KidsRelay - aligne la policy RLS de `partages` sur le pattern
-- SECURITY DEFINER utilise partout ailleurs (enfant_du_parent()),
-- au lieu de la sous-requete brute sur `enfants` heritee de la
-- version d'origine de schema.sql -- corrections de l'audit passe 1,
-- item 4. Pas un bug actif aujourd'hui (aucun risque de recursion
-- constate), simple coherence de code : toutes les autres tables
-- protegees par "cet enfant m'appartient-il ?" passent deja par cette
-- fonction.
--
-- Script idempotent (policy precedee d'un "drop policy if exists").
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite schema_espace_professionnel_etablissements.sql (deja
-- execute, definit enfant_du_parent()).
-- =====================================================================

drop policy if exists "partages_geres_par_le_parent"
  on public.partages;

create policy "partages_geres_par_le_parent"
  on public.partages
  for all
  using (public.enfant_du_parent(enfant_id))
  with check (public.enfant_du_parent(enfant_id));
