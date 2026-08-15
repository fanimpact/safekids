-- =====================================================================
-- SafeKids - structure des tables Supabase
--
-- Cree uniquement la structure (tables + RLS). Aucune donnee existante
-- de ChildRepository (en memoire, cote app Flutter) n'est migree ici.
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- enfants
-- ---------------------------------------------------------------------
create table if not exists public.enfants (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  prenom text,
  nom text,
  date_naissance date,
  poids numeric,
  taille numeric,
  date_maj_poids date,
  created_at timestamptz not null default now()
);

alter table public.enfants enable row level security;

create policy "enfants_du_parent"
  on public.enfants
  for all
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());

-- ---------------------------------------------------------------------
-- profils_sante
-- Colonnes en jsonb : chaque champ correspond a une liste ou un objet
-- structure cote app (ex. pathologies = liste d'objets), pas a une
-- valeur simple. Pas de normalisation en tables separees pour l'instant.
-- ---------------------------------------------------------------------
create table if not exists public.profils_sante (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references public.enfants (id) on delete cascade,
  pathologies jsonb not null default '[]'::jsonb,
  allergies jsonb not null default '[]'::jsonb,
  traitements_urgence jsonb not null default '[]'::jsonb,
  traitements_reguliers jsonb not null default '[]'::jsonb,
  dispositifs_medicaux jsonb not null default '[]'::jsonb,
  medecin_traitant jsonb not null default '{}'::jsonb,
  facteurs_declenchants jsonb not null default '{}'::jsonb,
  contacts_urgence jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profils_sante enable row level security;

create policy "profils_sante_du_parent"
  on public.profils_sante
  for all
  using (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  )
  with check (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- profils_activites
-- ---------------------------------------------------------------------
create table if not exists public.profils_activites (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references public.enfants (id) on delete cascade,
  habillage jsonb not null default '{}'::jsonb,
  toilettes jsonb not null default '{}'::jsonb,
  communication jsonb not null default '{}'::jsonb,
  transport jsonb not null default '{}'::jsonb,
  securite jsonb not null default '{}'::jsonb,
  nuitee jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profils_activites enable row level security;

create policy "profils_activites_du_parent"
  on public.profils_activites
  for all
  using (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  )
  with check (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- partages
-- type_fiche restreint aux 3 fiches existantes dans l'app :
-- "secours" (Informations pour les secours),
-- "ce_qu_il_faut_savoir" (Ce qu'il faut savoir sur...),
-- "recommandations_activite" (Fiche de recommandations d'activite).
--
-- IMPORTANT (a lire) : la policy ci-dessous ne permet au parent de
-- gerer que SES propres partages. Elle ne permet PAS a un accompagnant
-- externe (non authentifie comme parent) de lire une fiche via le lien
-- token -- cette policy d'acces public par token n'existe pas encore,
-- il faudra l'ajouter quand la fonctionnalite de partage sera
-- effectivement construite cote app.
-- ---------------------------------------------------------------------
create table if not exists public.partages (
  id uuid primary key default gen_random_uuid(),
  token text not null unique
    default encode(gen_random_bytes(24), 'hex'),
  enfant_id uuid not null references public.enfants (id) on delete cascade,
  type_fiche text not null check (
    type_fiche in (
      'secours',
      'ce_qu_il_faut_savoir',
      'recommandations_activite'
    )
  ),
  date_creation timestamptz not null default now(),
  date_expiration timestamptz not null,
  date_derniere_consultation timestamptz
);

alter table public.partages enable row level security;

create policy "partages_geres_par_le_parent"
  on public.partages
  for all
  using (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  )
  with check (
    enfant_id in (
      select id from public.enfants where parent_id = auth.uid()
    )
  );
