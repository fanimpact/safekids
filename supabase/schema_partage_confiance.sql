-- =====================================================================
-- SafeKids - partage de la fiche d'un enfant avec un co-parent ou un
-- tuteur, jusqu'a 2 personnes de confiance par enfant. Corrections de
-- l'inventaire du 19/08/2026, point 9. Design valide par Fanny :
--
-- - niveau d'acces choisi par le parent PAR invitation (lecture seule
--   par defaut, ou lecture/ecriture complete), visible et modifiable
--   apres coup ;
-- - la personne de confiance ne peut jamais : supprimer le profil de
--   l'enfant, voir les autres enfants du parent, ni inviter/revoquer
--   quelqu'un -- seul le parent d'origine garde ce controle ;
-- - la revocation coupe l'acces immediatement (RLS), sans effacer ce
--   qui a deja ete saisi pendant que l'acces etait actif.
--
-- Meme mecanique que les invitations d'equipe cote etablissement
-- (schema_espace_professionnel_invitations.sql) : toutes les
-- ecritures passent par des fonctions RPC, jamais d'ecriture cliente
-- directe sur enfants_confiance.
--
-- Script idempotent (table en "if not exists", policies precedees
-- d'un "drop policy if exists", fonctions en "create or replace").
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

-- =======================================================================
-- 1. TABLE
-- =======================================================================

create table if not exists public.enfants_confiance (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null
    references public.enfants (id) on delete cascade,
  email text not null,
  user_id uuid references auth.users (id),
  niveau_acces text not null default 'lecture'
    check (niveau_acces in ('lecture', 'lecture_ecriture')),
  statut text not null default 'invite'
    check (statut in ('invite', 'actif', 'revoque')),
  invite_par uuid not null references auth.users (id),
  invite_le timestamptz not null default now(),
  accepte_le timestamptz,
  revoque_par uuid references auth.users (id),
  revoque_le timestamptz,
  unique (enfant_id, email)
);

alter table public.enfants_confiance enable row level security;

-- =======================================================================
-- 2. FONCTIONS UTILITAIRES (SECURITY DEFINER, meme raison que pour
-- l'espace professionnel : evite toute recursion RLS entre enfants et
-- enfants_confiance).
-- =======================================================================

-- "L'utilisateur connecte a-t-il un acces de confiance actif a cet
-- enfant, au moins au niveau demande ?" p_niveau_requis = 'lecture'
-- (defaut) est satisfait par les deux niveaux ; 'lecture_ecriture'
-- n'est satisfait que par ce niveau precis.
create or replace function public.enfant_confie_a(
  p_enfant_id uuid,
  p_niveau_requis text default 'lecture'
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.enfants_confiance
    where enfant_id = p_enfant_id
      and user_id = auth.uid()
      and statut = 'actif'
      and (
        p_niveau_requis = 'lecture'
        or niveau_acces = 'lecture_ecriture'
      )
  );
$$;

-- =======================================================================
-- 3. POLICIES
-- =======================================================================

-- --- enfants_confiance ---------------------------------------------------

-- Le parent proprietaire de l'enfant voit toutes les personnes de
-- confiance de cet enfant (invitees, actives, revoquees) ; une
-- personne de confiance voit sa propre ligne.
drop policy if exists "enfants_confiance_lecture"
  on public.enfants_confiance;

create policy "enfants_confiance_lecture"
  on public.enfants_confiance
  for select
  using (
    user_id = auth.uid()
    or public.enfant_du_parent(enfant_id)
  );

-- Aucune policy d'ecriture directe : creation, changement de niveau et
-- revocation passent toutes par des fonctions RPC (voir plus bas),
-- pour qu'une personne de confiance ne puisse jamais modifier son
-- propre acces, et que seul le parent proprietaire gere la liste.

-- --- enfants : lecture/ecriture etendue aux personnes de confiance -----

drop policy if exists "enfants_visibles_par_personne_de_confiance"
  on public.enfants;

create policy "enfants_visibles_par_personne_de_confiance"
  on public.enfants
  for select
  using (public.enfant_confie_a(id));

drop policy if exists "enfants_modifiables_par_personne_de_confiance"
  on public.enfants;

create policy "enfants_modifiables_par_personne_de_confiance"
  on public.enfants
  for update
  using (public.enfant_confie_a(id, 'lecture_ecriture'))
  with check (public.enfant_confie_a(id, 'lecture_ecriture'));

-- --- profils_sante : idem ------------------------------------------------

drop policy if exists "profils_sante_visibles_par_personne_de_confiance"
  on public.profils_sante;

create policy "profils_sante_visibles_par_personne_de_confiance"
  on public.profils_sante
  for select
  using (public.enfant_confie_a(enfant_id));

drop policy if exists "profils_sante_modifiables_par_personne_de_confiance"
  on public.profils_sante;

create policy "profils_sante_modifiables_par_personne_de_confiance"
  on public.profils_sante
  for update
  using (public.enfant_confie_a(enfant_id, 'lecture_ecriture'))
  with check (public.enfant_confie_a(enfant_id, 'lecture_ecriture'));

-- --- profils_activites : idem --------------------------------------------

drop policy if exists
  "profils_activites_visibles_par_personne_de_confiance"
  on public.profils_activites;

create policy "profils_activites_visibles_par_personne_de_confiance"
  on public.profils_activites
  for select
  using (public.enfant_confie_a(enfant_id));

drop policy if exists
  "profils_activites_modifiables_par_personne_de_confiance"
  on public.profils_activites;

create policy "profils_activites_modifiables_par_personne_de_confiance"
  on public.profils_activites
  for update
  using (public.enfant_confie_a(enfant_id, 'lecture_ecriture'))
  with check (public.enfant_confie_a(enfant_id, 'lecture_ecriture'));

-- =======================================================================
-- 4. FONCTIONS RPC
-- =======================================================================

-- Invite une personne de confiance par email, avec le niveau d'acces
-- choisi par le parent. Refuse au-dela de 2 personnes actives ou
-- invitees (non revoquees) pour cet enfant.
create or replace function public.rpc_inviter_personne_confiance(
  p_enfant_id uuid,
  p_email text,
  p_niveau_acces text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_email text;
  v_nombre_actuel integer;
begin
  if not public.enfant_du_parent(p_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut inviter une personne de '
      'confiance.';
  end if;

  if p_niveau_acces not in ('lecture', 'lecture_ecriture') then
    raise exception 'Niveau d''acces invalide.';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));

  if v_email = '' then
    raise exception 'L''adresse email est obligatoire.';
  end if;

  select count(*) into v_nombre_actuel
  from public.enfants_confiance
  where enfant_id = p_enfant_id
    and statut != 'revoque';

  if v_nombre_actuel >= 2 then
    raise exception
      'Deux personnes de confiance au maximum par enfant. '
      'Revoquez d''abord un acces existant.';
  end if;

  insert into public.enfants_confiance
    (enfant_id, email, niveau_acces, statut, invite_par)
  values
    (p_enfant_id, v_email, p_niveau_acces, 'invite', auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

-- Change le niveau d'acces d'une personne de confiance deja invitee
-- ou active.
create or replace function public.rpc_changer_niveau_confiance(
  p_confiance_id uuid,
  p_nouveau_niveau text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enfant_id uuid;
begin
  select enfant_id into v_enfant_id
  from public.enfants_confiance
  where id = p_confiance_id
  for update;

  if v_enfant_id is null then
    raise exception 'Personne de confiance introuvable.';
  end if;

  if not public.enfant_du_parent(v_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut changer ce niveau d''acces.';
  end if;

  if p_nouveau_niveau not in ('lecture', 'lecture_ecriture') then
    raise exception 'Niveau d''acces invalide.';
  end if;

  update public.enfants_confiance
  set niveau_acces = p_nouveau_niveau
  where id = p_confiance_id;
end;
$$;

-- Revoque l'acces d'une personne de confiance. L'acces est coupe
-- immediatement (RLS reevaluee a chaque requete) ; ce qui a deja ete
-- saisi par cette personne reste sur la fiche.
create or replace function public.rpc_revoquer_confiance(
  p_confiance_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enfant_id uuid;
begin
  select enfant_id into v_enfant_id
  from public.enfants_confiance
  where id = p_confiance_id
  for update;

  if v_enfant_id is null then
    raise exception 'Personne de confiance introuvable.';
  end if;

  if not public.enfant_du_parent(v_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut revoquer cet acces.';
  end if;

  update public.enfants_confiance
  set statut = 'revoque',
      revoque_par = auth.uid(),
      revoque_le = now()
  where id = p_confiance_id;
end;
$$;

-- Active toute invitation "personne de confiance" en attente pour
-- l'utilisateur connecte -- a appeler juste apres chaque connexion
-- parent, avant de charger la liste des enfants. Meme principe que
-- rpc_activer_invitations_en_attente cote etablissement.
create or replace function public.rpc_activer_confiances_en_attente()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_count integer;
begin
  v_email := lower(trim(coalesce(auth.jwt() ->> 'email', '')));

  if v_email = '' then
    return 0;
  end if;

  update public.enfants_confiance
  set user_id = auth.uid(),
      statut = 'actif',
      accepte_le = now()
  where email = v_email
    and statut = 'invite'
    and user_id is null;

  get diagnostics v_count = row_count;

  return v_count;
end;
$$;
