-- =====================================================================
-- KidsRelay - Espace professionnel, phase 5 : activites preparees
-- (parent ET etablissement), masquage individuel des recommandations,
-- notes rattachees a une activite
--
-- Voir C:\Users\fanny\.claude\plans\rustling-jumping-pebble.md, section
-- 11 (Phase 5), pour le detail des decisions et leur justification.
--
-- Ce fichier peut etre rejoue sans risque (tables en "if not exists",
-- policies precedees d'un "drop policy if exists", fonctions en
-- "create or replace"). Necessite schema_espace_professionnel_etablissements.sql
-- (deja execute) pour est_membre_actif()/enfant_visible_par_etablissement()/
-- enfant_du_parent().
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

-- =======================================================================
-- 1. TABLES (toutes creees avant la moindre policy)
-- =======================================================================

-- Une activite preparee appartient SOIT a un parent SOIT a un
-- etablissement, jamais aux deux. Cote etablissement, elle est
-- partagee : n'importe quel membre actif peut la lire ET la modifier
-- (pas seulement son createur), pour qu'elle ne reste jamais bloquee
-- si l'auteur d'origine est absent -- cree_par/modifie_par gardent la
-- tracabilite de qui a fait quoi, sans restreindre qui peut agir.
--
-- Les recommandations elles-memes ne sont jamais stockees ici : elles
-- sont recalculees a chaque ouverture a partir du profil le plus a
-- jour de chaque enfant (voir plan, section 6).
create table if not exists public.activites_preparees (
  id uuid primary key default gen_random_uuid(),
  cree_par uuid not null references auth.users (id),
  parent_id uuid references auth.users (id),
  etablissement_id uuid references public.etablissements (id) on delete cascade,
  nom_activite text,
  date_activite timestamptz,
  lieu text,
  description jsonb not null default '{}'::jsonb,
  enfants_ids uuid[] not null default '{}',
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  modifie_par uuid references auth.users (id),
  constraint un_seul_proprietaire check (
    ((parent_id is not null)::int + (etablissement_id is not null)::int) = 1
  )
);

alter table public.activites_preparees enable row level security;

-- Masquage d'une recommandation, strictement individuel : une
-- preference par utilisateur, jamais une propriete de l'activite
-- elle-meme. cle_recommandation encode "<enfant_id ou 'global'>:<id>"
-- cote app, pour eviter les soucis d'unicite avec un enfant_id
-- nullable en base.
create table if not exists public.activites_recommandations_masquees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id),
  activite_id uuid not null
    references public.activites_preparees (id) on delete cascade,
  cle_recommandation text not null,
  masque_le timestamptz not null default now(),
  unique (user_id, activite_id, cle_recommandation)
);

alter table public.activites_recommandations_masquees enable row level security;

-- Note rattachee a une activite (pas a la fiche d'un enfant) : un
-- membre du personnel peut y ecrire une remarque generale au groupe
-- (enfant_id null, jamais transmise au parent) ou concernant un enfant
-- precis parmi ceux de l'activite (enfant_id renseigne, visible ET
-- notifie au parent). Jamais visible des autres membres du personnel.
create table if not exists public.notes_activite (
  id uuid primary key default gen_random_uuid(),
  activite_id uuid not null
    references public.activites_preparees (id) on delete cascade,
  auteur_id uuid not null references auth.users (id),
  enfant_id uuid references public.enfants (id) on delete cascade,
  note text not null,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz
);

alter table public.notes_activite enable row level security;

-- =======================================================================
-- 2. POLICIES
-- =======================================================================

-- --- activites_preparees -------------------------------------------------

drop policy if exists "activites_du_parent" on public.activites_preparees;

create policy "activites_du_parent"
  on public.activites_preparees
  for all
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid() and cree_par = auth.uid());

drop policy if exists "activites_lecture_par_membre" on public.activites_preparees;

create policy "activites_lecture_par_membre"
  on public.activites_preparees
  for select
  using (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
  );

-- Ecriture partagee : tout membre actif peut creer/modifier/supprimer
-- une activite de son etablissement, pas seulement son createur --
-- decision explicite de Fanny (18/08/2026) : "l'ecole ne doit jamais
-- se retrouver bloquee si l'auteur d'origine est absent."
drop policy if exists "activites_creation_par_membre" on public.activites_preparees;

create policy "activites_creation_par_membre"
  on public.activites_preparees
  for insert
  with check (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
    and cree_par = auth.uid()
  );

drop policy if exists "activites_modification_par_membre" on public.activites_preparees;

create policy "activites_modification_par_membre"
  on public.activites_preparees
  for update
  using (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
  )
  with check (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
  );

drop policy if exists "activites_suppression_par_membre" on public.activites_preparees;

create policy "activites_suppression_par_membre"
  on public.activites_preparees
  for delete
  using (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
  );

-- --- activites_recommandations_masquees ----------------------------------

drop policy if exists "masquages_du_lecteur" on public.activites_recommandations_masquees;

create policy "masquages_du_lecteur"
  on public.activites_recommandations_masquees
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.activites_preparees a
      where a.id = activite_id
        and (
          a.parent_id = auth.uid()
          or (
            a.etablissement_id is not null
            and public.est_membre_actif(a.etablissement_id)
          )
        )
    )
  );

-- --- notes_activite -------------------------------------------------------

-- L'auteur voit ses propres notes ; le parent voit celles rattachees a
-- son enfant (jamais les notes generales au groupe, enfant_id null) ;
-- jamais visible des autres membres du personnel.
drop policy if exists "notes_lecture_auteur_ou_parent" on public.notes_activite;

create policy "notes_lecture_auteur_ou_parent"
  on public.notes_activite
  for select
  using (
    auteur_id = auth.uid()
    or (enfant_id is not null and public.enfant_du_parent(enfant_id))
  );

drop policy if exists "notes_creation_par_membre" on public.notes_activite;

create policy "notes_creation_par_membre"
  on public.notes_activite
  for insert
  with check (
    auteur_id = auth.uid()
    and exists (
      select 1 from public.activites_preparees a
      where a.id = activite_id
        and a.etablissement_id is not null
        and public.est_membre_actif(a.etablissement_id)
    )
  );

drop policy if exists "notes_modification_par_auteur" on public.notes_activite;

create policy "notes_modification_par_auteur"
  on public.notes_activite
  for update
  using (auteur_id = auth.uid())
  with check (auteur_id = auth.uid());

drop policy if exists "notes_suppression_par_auteur" on public.notes_activite;

create policy "notes_suppression_par_auteur"
  on public.notes_activite
  for delete
  using (auteur_id = auth.uid());
