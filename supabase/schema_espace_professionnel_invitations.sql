-- =====================================================================
-- SafeKids - Espace professionnel, phase 3 : gestion d'equipe
-- (inviter un collegue, changer un role, revoquer) -- corrections de
-- l'inventaire du 19/08/2026, point 10. Design valide par Fanny dans
-- le plan de l'espace professionnel (§2) : directeur et adjoint ont
-- exactement les memes pouvoirs de gestion des comptes, un membre
-- simple n'en a aucun ; cette distinction de role ne restreint jamais
-- l'acces aux donnees des enfants, deja regle en phase 4.
--
-- La table membres_etablissement existe deja (phase 2, avec role et
-- statut prets pour cette phase-ci). Ce fichier n'ajoute que les
-- fonctions RPC necessaires -- aucune ecriture directe sur cette table
-- n'est autorisee cote client, pour qu'un utilisateur ne puisse jamais
-- se donner lui-meme un role ou reactiver son propre acces revoque.
--
-- Script idempotent (fonctions en "create or replace"). A executer
-- dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite schema_espace_professionnel_etablissements.sql (deja
-- execute).
-- =====================================================================

-- "L'utilisateur connecte peut-il gerer les membres de cet
-- etablissement ?" -- directeur et adjoint uniquement, jamais un
-- membre simple. SECURITY DEFINER pour eviter toute recursion RLS,
-- meme raison que est_membre_actif().
create or replace function public.peut_gerer_membres(
  p_etablissement_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.membres_etablissement
    where user_id = auth.uid()
      and etablissement_id = p_etablissement_id
      and statut = 'actif'
      and role in ('directeur', 'adjoint')
  );
$$;

-- Nombre de personnes actuellement capables de gerer cet
-- etablissement (directeur ou adjoint actifs) -- sert de garde-fou
-- dans rpc_changer_role_membre et rpc_revoquer_membre : l'etablissement
-- ne doit jamais se retrouver sans personne pour le gerer.
create or replace function public.nombre_gestionnaires_actifs(
  p_etablissement_id uuid
)
returns integer
language sql
security definer
stable
set search_path = public
as $$
  select count(*)::integer
  from public.membres_etablissement
  where etablissement_id = p_etablissement_id
    and statut = 'actif'
    and role in ('directeur', 'adjoint');
$$;

-- Invite un collegue par email. N'ecrase jamais une ligne existante
-- pour ce couple (etablissement, email) -- la contrainte unique de la
-- table s'en charge, l'erreur remonte telle quelle a l'app.
create or replace function public.rpc_inviter_membre(
  p_etablissement_id uuid,
  p_email text,
  p_role text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_email text;
begin
  if not public.peut_gerer_membres(p_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent inviter quelqu''un.';
  end if;

  if p_role not in ('adjoint', 'membre') then
    raise exception
      'Role invalide pour une invitation (adjoint ou membre uniquement).';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));

  if v_email = '' then
    raise exception 'L''adresse email est obligatoire.';
  end if;

  insert into public.membres_etablissement
    (etablissement_id, email, role, statut, invite_par)
  values
    (p_etablissement_id, v_email, p_role, 'invite', auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

-- Change le role d'un membre deja actif (peut aussi nommer un
-- directeur supplementaire -- voir §2 du plan : l'etablissement ne
-- doit jamais dependre d'une seule personne). Refuse si ca laisserait
-- l'etablissement sans aucun directeur/adjoint actif.
create or replace function public.rpc_changer_role_membre(
  p_membre_id uuid,
  p_nouveau_role text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_etablissement_id uuid;
  v_ancien_role text;
  v_statut text;
begin
  select etablissement_id, role, statut
  into v_etablissement_id, v_ancien_role, v_statut
  from public.membres_etablissement
  where id = p_membre_id
  for update;

  if v_etablissement_id is null then
    raise exception 'Membre introuvable.';
  end if;

  if not public.peut_gerer_membres(v_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent changer un role.';
  end if;

  if v_statut != 'actif' then
    raise exception 'Seul un membre actif peut changer de role.';
  end if;

  if p_nouveau_role not in ('directeur', 'adjoint', 'membre') then
    raise exception 'Role invalide.';
  end if;

  if v_ancien_role in ('directeur', 'adjoint')
     and p_nouveau_role = 'membre'
     and public.nombre_gestionnaires_actifs(v_etablissement_id) <= 1 then
    raise exception
      'Impossible : ce serait le dernier directeur ou adjoint de '
      'l''etablissement. Nommez d''abord quelqu''un d''autre.';
  end if;

  update public.membres_etablissement
  set role = p_nouveau_role
  where id = p_membre_id;
end;
$$;

-- Revoque l'acces d'un membre. Meme garde-fou que ci-dessus : jamais
-- le dernier directeur/adjoint actif.
create or replace function public.rpc_revoquer_membre(
  p_membre_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_etablissement_id uuid;
  v_role text;
  v_statut text;
begin
  select etablissement_id, role, statut
  into v_etablissement_id, v_role, v_statut
  from public.membres_etablissement
  where id = p_membre_id
  for update;

  if v_etablissement_id is null then
    raise exception 'Membre introuvable.';
  end if;

  if not public.peut_gerer_membres(v_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent revoquer quelqu''un.';
  end if;

  if v_statut = 'revoque' then
    return;
  end if;

  if v_role in ('directeur', 'adjoint')
     and public.nombre_gestionnaires_actifs(v_etablissement_id) <= 1 then
    raise exception
      'Impossible : ce serait le dernier directeur ou adjoint de '
      'l''etablissement. Nommez d''abord quelqu''un d''autre.';
  end if;

  update public.membres_etablissement
  set statut = 'revoque',
      revoque_par = auth.uid(),
      revoque_le = now()
  where id = p_membre_id;
end;
$$;

-- Active toute invitation en attente dont l'email correspond a
-- l'utilisateur connecte -- a appeler juste apres chaque connexion
-- professionnelle (que ce soit via l'invitation elle-meme ou une
-- connexion normale si la personne avait deja un compte). SECURITY
-- DEFINER : une ligne "invite" pas encore reclamee n'est pas visible
-- par une lecture normale (RLS), donc un simple UPDATE cote client ne
-- fonctionnerait pas.
create or replace function public.rpc_activer_invitations_en_attente()
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

  update public.membres_etablissement
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
