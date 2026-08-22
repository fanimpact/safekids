-- =====================================================================
-- KidsRelay - Espace professionnel, phase 4 : fiche secours, "Ce qu'il
-- faut savoir sur...", profil activites et Mode Urgence cote
-- professionnel, avec journal de consultation.
--
-- Ce fichier peut etre rejoue sans risque (policies precedees d'un
-- "drop policy if exists", table/index en "if not exists", fonction
-- en "create or replace").
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite les fichiers precedents (comptes, etablissements,
-- identites) deja executes.
-- =====================================================================

-- =======================================================================
-- 1. Lecture (uniquement) du profil sante et du profil activites par
-- le personnel actif d'un etablissement -- meme principe que la
-- policy deja en place sur `enfants`. Ecriture toujours reservee aux
-- parents (policies existantes, non touchees).
-- =======================================================================

drop policy if exists "profils_sante_visibles_par_etablissement"
  on public.profils_sante;

create policy "profils_sante_visibles_par_etablissement"
  on public.profils_sante
  for select
  using (public.enfant_visible_par_etablissement(enfant_id));

drop policy if exists "profils_activites_visibles_par_etablissement"
  on public.profils_activites;

create policy "profils_activites_visibles_par_etablissement"
  on public.profils_activites
  for select
  using (public.enfant_visible_par_etablissement(enfant_id));

-- =======================================================================
-- 2. Journal des consultations -- tracabilite RGPD : qui a consulte
-- quelle fiche, quand. Invisible au quotidien pour le personnel
-- (aucune policy SELECT pour "authenticated") ; conservation 12 mois.
-- =======================================================================

create table if not exists public.journal_consultations_fiche (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  enfant_id uuid not null references public.enfants (id) on delete cascade,
  etablissement_id uuid references public.etablissements (id) on delete cascade,
  type_fiche text not null check (
    type_fiche in (
      'secours', 'ce_qu_il_faut_savoir', 'profil_activites', 'mode_urgence'
    )
  ),
  consulte_le timestamptz not null default now()
);

alter table public.journal_consultations_fiche enable row level security;

create index if not exists journal_consultations_consulte_le_idx
  on public.journal_consultations_fiche (consulte_le);

-- Un membre actif peut ENREGISTRER sa propre consultation d'un enfant
-- de son etablissement -- jamais lire le journal (aucune policy
-- SELECT), jamais enregistrer au nom de quelqu'un d'autre.
drop policy if exists "journal_ecriture_par_membre_actif"
  on public.journal_consultations_fiche;

create policy "journal_ecriture_par_membre_actif"
  on public.journal_consultations_fiche
  for insert
  with check (
    user_id = auth.uid()
    and public.enfant_visible_par_etablissement(enfant_id)
  );

-- Purge automatique des entrees de plus de 12 mois. Necessite
-- l'extension pg_cron (deja disponible sur les projets Supabase
-- standards) ; si son activation echoue (plan sans pg_cron), le reste
-- du fichier s'applique quand meme -- la purge devra alors se faire
-- manuellement de temps en temps avec la meme requete DELETE.
do $$
begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron indisponible sur ce projet : purge automatique non programmee.';
end $$;

do $$
begin
  perform cron.unschedule('purge-journal-consultations-fiche');
exception when others then
  null;
end $$;

do $$
begin
  perform cron.schedule(
    'purge-journal-consultations-fiche',
    '0 3 * * *',
    $sql$
      delete from public.journal_consultations_fiche
      where consulte_le < now() - interval '12 months';
    $sql$
  );
exception when others then
  raise notice 'Programmation de la purge automatique impossible (pg_cron indisponible).';
end $$;
