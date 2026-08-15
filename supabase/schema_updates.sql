-- =====================================================================
-- SafeKids - colonnes manquantes sur profils_sante / profils_activites
--
-- Ajoutees pour la migration de ChildRepository (memoire -> Supabase) :
-- ces champs existent dans le modele Flutter mais n'avaient pas encore
-- de colonne. Script idempotent (peut etre rejoue sans risque).
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

alter table public.enfants
  add column if not exists a_pathologies_diagnostiquees boolean;

alter table public.profils_sante
  add column if not exists evenements_medicaux jsonb not null default '[]'::jsonb,
  add column if not exists observations_medicales jsonb not null default '[]'::jsonb,
  add column if not exists traitements_arretes jsonb not null default '[]'::jsonb,
  add column if not exists a_pathologies boolean,
  add column if not exists a_allergies boolean,
  add column if not exists a_traitements_reguliers boolean,
  add column if not exists a_traitements_arretes boolean,
  add column if not exists a_traitements_urgence boolean,
  add column if not exists a_dispositifs_medicaux boolean;

alter table public.profils_activites
  add column if not exists activite_aquatique jsonb not null default '{}'::jsonb,
  add column if not exists effort_marche jsonb not null default '{}'::jsonb,
  add column if not exists transitions jsonb not null default '{}'::jsonb,
  add column if not exists autres_informations jsonb not null default '{}'::jsonb;

-- Un seul profil santé / profil activités par enfant : nécessaire pour
-- que les upserts cote app (ON CONFLICT enfant_id) fonctionnent.
create unique index if not exists profils_sante_enfant_id_key
  on public.profils_sante (enfant_id);

create unique index if not exists profils_activites_enfant_id_key
  on public.profils_activites (enfant_id);
