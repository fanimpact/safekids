-- =====================================================================
-- KidsRelay - Espace professionnel, phase 2 : etablissements et
-- rattachement d'un enfant, a une duree choisie par le parent
--
-- Cette phase ne construit PAS encore les invitations/revocations de
-- personnel (phase 3) : un seul "directeur" par etablissement pour
-- l'instant (celui qui l'a cree), meme si la table membres_etablissement
-- est deja prete pour les roles adjoint/membre a venir.
--
-- Ce fichier peut etre rejoue sans risque (tables en "if not exists",
-- policies precedees d'un "drop policy if exists", fonctions en
-- "create or replace") : le relancer par erreur ne casse rien de deja
-- en place. Toutes les tables sont creees AVANT la moindre policy, car
-- plusieurs policies de ce fichier font reference a plusieurs de ces
-- tables entre elles (une policy ne peut pas etre creee tant qu'une
-- table qu'elle mentionne n'existe pas encore).
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite schema_espace_professionnel_comptes.sql (deja execute).
-- =====================================================================

-- =======================================================================
-- 1. TABLES (toutes creees avant la moindre policy)
-- =======================================================================

create table if not exists public.etablissements (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  type_etablissement text,
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

alter table public.etablissements enable row level security;

-- Role et statut prets pour la phase 3 (adjoint, invitations), meme si
-- cette phase-ci ne cree que la ligne "directeur" du createur.
create table if not exists public.membres_etablissement (
  id uuid primary key default gen_random_uuid(),
  etablissement_id uuid not null
    references public.etablissements (id) on delete cascade,
  email text not null,
  user_id uuid references auth.users (id),
  role text not null check (role in ('directeur', 'adjoint', 'membre')),
  statut text not null default 'invite'
    check (statut in ('invite', 'actif', 'revoque')),
  invite_par uuid not null references auth.users (id),
  invite_le timestamptz not null default now(),
  accepte_le timestamptz,
  revoque_par uuid references auth.users (id),
  revoque_le timestamptz,
  unique (etablissement_id, email)
);

alter table public.membres_etablissement enable row level security;

-- Rattachement N-N enfant <-> etablissement. La duree est TOUJOURS
-- choisie par le parent au moment de la creation du lien (jamais de
-- valeur par defaut implicite) : date_expiration est obligatoire des
-- l'insertion, imposee cote app, pas de defaut ici.
create table if not exists public.enfants_etablissements (
  id uuid primary key default gen_random_uuid(),
  token text not null unique
    default encode(gen_random_bytes(24), 'hex'),
  enfant_id uuid not null
    references public.enfants (id) on delete cascade,
  etablissement_id uuid
    references public.etablissements (id) on delete cascade,
  statut text not null default 'en_attente'
    check (statut in ('en_attente', 'actif', 'revoque')),
  date_creation timestamptz not null default now(),
  date_expiration timestamptz not null,
  claime_par uuid references auth.users (id),
  claime_le timestamptz,
  revoque_le timestamptz
);

alter table public.enfants_etablissements enable row level security;

-- =======================================================================
-- 2. FONCTION UTILITAIRE (avant les policies qui l'utilisent)
--
-- "Est-ce que l'utilisateur connecte est membre actif de cet
-- etablissement ?", en SECURITY DEFINER : la fonction s'execute avec
-- les droits de son proprietaire (qui contourne le RLS), donc sa
-- propre lecture de membres_etablissement ne redeclenche PAS les
-- policies de cette table. Sans ca, une policy sur membres_etablissement
-- qui s'interroge elle-meme via une sous-requete directe provoque une
-- recursion infinie (erreur Postgres 42P17) -- c'est exactement le bug
-- corrige ici.
-- =======================================================================

create or replace function public.est_membre_actif(
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
  );
$$;

-- Meme principe, pour un deuxieme cas de recursion : la policy de
-- lecture d'un enfant par le personnel (plus bas) a besoin de lire
-- enfants_etablissements, mais enfants_etablissements a elle-meme une
-- policy ("enfants_etablissements_du_parent") qui relit enfants -- une
-- sous-requete normale entre les deux forme une boucle croisee entre
-- deux tables (meme erreur 42P17, juste etalee sur deux tables au lieu
-- d'une seule qui se cite elle-meme). Meme remede : SECURITY DEFINER.
create or replace function public.enfant_visible_par_etablissement(
  p_enfant_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.enfant_id = p_enfant_id
      and ee.statut = 'actif'
      and ee.date_expiration > now()
      and ee.etablissement_id is not null
      and public.est_membre_actif(ee.etablissement_id)
  );
$$;

-- "Cet enfant appartient-il au parent connecte ?" -- sert uniquement
-- aux policies d'AUTRES tables qui ont besoin de le savoir
-- (enfants_etablissements, etablissements) sans jamais faire de
-- sous-requete brute sur `enfants` directement dans leur USING/WITH
-- CHECK. Ne change rien a l'acces normal du parent a ses propres
-- enfants : la policy "enfants_du_parent" d'origine (schema.sql,
-- deja en place) n'est pas touchee par ce fichier.
create or replace function public.enfant_du_parent(
  p_enfant_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.enfants
    where id = p_enfant_id and parent_id = auth.uid()
  );
$$;

-- "Cet etablissement a-t-il au moins un enfant du parent connecte
-- rattache ?" -- pour l'ecran "mes rattachements" du parent, sans
-- sous-requete brute croisant enfants_etablissements et enfants.
create or replace function public.etablissement_du_parent(
  p_etablissement_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.etablissement_id = p_etablissement_id
      and public.enfant_du_parent(ee.enfant_id)
  );
$$;

-- =======================================================================
-- 3. POLICIES (toutes les tables ci-dessus existent maintenant)
-- =======================================================================

-- --- etablissements ----------------------------------------------------

drop policy if exists "etablissements_visibles_par_membre_actif"
  on public.etablissements;

create policy "etablissements_visibles_par_membre_actif"
  on public.etablissements
  for select
  using (public.est_membre_actif(id));

-- Un parent doit pouvoir voir le NOM de l'etablissement auquel son
-- enfant est rattache (ecran "mes rattachements"), meme s'il n'en est
-- pas membre lui-meme.
drop policy if exists "etablissements_visibles_par_parent_enfant_rattache"
  on public.etablissements;

create policy "etablissements_visibles_par_parent_enfant_rattache"
  on public.etablissements
  for select
  using (public.etablissement_du_parent(id));

-- Pas de policy INSERT/UPDATE directe : la creation passe par
-- rpc_creer_etablissement (voir plus bas), pour garantir que
-- l'etablissement et sa ligne "directeur" sont crees ensemble.

-- --- membres_etablissement ----------------------------------------------

-- Un membre actif voit tout le trombinoscope de son etablissement
-- (utile des la phase 3 pour l'ecran de gestion des invitations) ; en
-- attendant, chacun voit au moins sa propre ligne. Passe par
-- est_membre_actif() -- PAS par une sous-requete directe sur cette
-- meme table, qui provoquait la recursion (bug corrige, voir plus haut).
drop policy if exists "membres_lecture_par_membre_actif_ou_soi_meme"
  on public.membres_etablissement;

create policy "membres_lecture_par_membre_actif_ou_soi_meme"
  on public.membres_etablissement
  for select
  using (
    user_id = auth.uid()
    or public.est_membre_actif(etablissement_id)
  );

-- Aucune policy d'ecriture directe : toute creation/modification passe
-- par des fonctions RPC (rpc_creer_etablissement ici ; invitation et
-- revocation arriveront en phase 3), pour ne jamais laisser un client
-- modifier le role ou le statut de quelqu'un d'autre directement.

-- --- enfants_etablissements ----------------------------------------------

-- Le parent gere librement SES rattachements : creation, liste,
-- revocation -- c'est le principe non negociable du parent qui decide.
drop policy if exists "enfants_etablissements_du_parent"
  on public.enfants_etablissements;

create policy "enfants_etablissements_du_parent"
  on public.enfants_etablissements
  for all
  using (public.enfant_du_parent(enfant_id))
  with check (public.enfant_du_parent(enfant_id));

-- N'importe quel utilisateur authentifie peut lire une ligne EN
-- ATTENTE et non expiree (necessaire pour verifier un token avant de
-- le reclamer) -- jamais une ligne deja reclamee/revoquee/expiree
-- d'un enfant qu'il n'a pas le droit de voir autrement.
drop policy if exists "enfants_etablissements_lecture_token_en_attente"
  on public.enfants_etablissements;

create policy "enfants_etablissements_lecture_token_en_attente"
  on public.enfants_etablissements
  for select
  using (statut = 'en_attente' and date_expiration > now());

-- Une fois reclamee, la ligne reste visible aux membres actifs de
-- l'etablissement concerne (trombinoscope).
drop policy if exists "enfants_etablissements_lecture_par_membre"
  on public.enfants_etablissements;

create policy "enfants_etablissements_lecture_par_membre"
  on public.enfants_etablissements
  for select
  using (
    etablissement_id is not null
    and public.est_membre_actif(etablissement_id)
  );

-- Pas de policy UPDATE pour la reclamation elle-meme : passe par
-- rpc_reclamer_rattachement (voir plus bas), pour empecher un client
-- de reecrire enfant_id sur une ligne qui ne lui appartient pas.

-- --- enfants (table existante, une policy en plus) -----------------------

-- Lecture (uniquement) de la fiche identite d'un enfant rattache, pour
-- que le personnel actif puisse voir un trombinoscope avec un vrai nom
-- plutot qu'un identifiant. Version minimale de ce qui sera etendu en
-- phase 4 (fiche secours, profil activites) : n'apporte aucun droit
-- d'ecriture, seuls les parents modifient `enfants`.
drop policy if exists "enfants_visibles_par_etablissement"
  on public.enfants;

create policy "enfants_visibles_par_etablissement"
  on public.enfants
  for select
  using (public.enfant_visible_par_etablissement(id));

-- =======================================================================
-- 4. FONCTIONS RPC
-- =======================================================================

-- Cree l'etablissement et la ligne "directeur" du createur ensemble
-- (atomique), avec la cle service_role implicite d'une fonction
-- "security definer" -- c'est le seul moyen d'ecrire dans ces deux
-- tables depuis le client.
create or replace function public.rpc_creer_etablissement(
  p_nom text,
  p_type text
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
  if p_nom is null or length(trim(p_nom)) = 0 then
    raise exception 'Le nom de l''etablissement est obligatoire.';
  end if;

  v_email := auth.jwt() ->> 'email';

  insert into public.etablissements (nom, type_etablissement, created_by)
  values (trim(p_nom), p_type, auth.uid())
  returning id into v_id;

  insert into public.membres_etablissement
    (etablissement_id, email, user_id, role, statut, invite_par, accepte_le)
  values
    (v_id, coalesce(v_email, ''), auth.uid(), 'directeur', 'actif', auth.uid(), now());

  return v_id;
end;
$$;

-- Valide un token en attente et l'attache a l'etablissement de
-- l'appelant, seulement si celui-ci en est membre actif. Renvoie le
-- prenom de l'enfant (uniquement, jamais le nom de famille ni de
-- donnee de sante) pour permettre a l'app d'afficher une confirmation.
create or replace function public.rpc_reclamer_rattachement(
  p_token text,
  p_etablissement_id uuid
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rattachement_id uuid;
  v_enfant_id uuid;
  v_prenom text;
begin
  if not public.est_membre_actif(p_etablissement_id) then
    raise exception 'Vous n''etes pas membre actif de cet etablissement.';
  end if;

  select id, enfant_id into v_rattachement_id, v_enfant_id
  from public.enfants_etablissements
  where token = p_token
    and statut = 'en_attente'
    and date_expiration > now()
  for update;

  if v_rattachement_id is null then
    raise exception 'Lien invalide ou expire.';
  end if;

  update public.enfants_etablissements
  set etablissement_id = p_etablissement_id,
      statut = 'actif',
      claime_par = auth.uid(),
      claime_le = now()
  where id = v_rattachement_id;

  select prenom into v_prenom
  from public.enfants
  where id = v_enfant_id;

  return v_prenom;
end;
$$;
