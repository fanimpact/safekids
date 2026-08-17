-- =====================================================================
-- SafeKids - Espace professionnel, phase 1 : comptes parents reels
--
-- Cree les tables necessaires pour remplacer l'identite anonyme des
-- parents par un vrai compte email + mot de passe, avec verification
-- par email uniquement depuis un appareil non reconnu (pas de double
-- authentification par application tierce).
--
-- Ne touche a aucune table existante (enfants, profils_sante,
-- profils_activites, partages) : parent_id reste le meme auth.uid()
-- avant et apres la conversion anonyme -> compte reel.
--
-- Ce fichier peut etre rejoue sans risque (tables et index en
-- "if not exists", policies precedees d'un "drop policy if exists") :
-- le relancer par erreur ne casse rien de deja en place.
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- comptes_parents
-- Metadonnees de compte uniquement : aucune donnee medicale ici.
-- ---------------------------------------------------------------------
create table if not exists public.comptes_parents (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  abonnement_actif boolean not null default false,
  compte_relie_le timestamptz,
  created_at timestamptz not null default now()
);

alter table public.comptes_parents enable row level security;

drop policy if exists "comptes_parents_lecture_propre"
  on public.comptes_parents;

create policy "comptes_parents_lecture_propre"
  on public.comptes_parents
  for select
  using (id = auth.uid());

-- Le parent peut creer/mettre a jour SA ligne, mais jamais passer lui-
-- meme abonnement_actif a true : ce sera ecrit uniquement par un futur
-- backend de facturation via la cle service_role (hors RLS).
drop policy if exists "comptes_parents_creation_propre"
  on public.comptes_parents;

create policy "comptes_parents_creation_propre"
  on public.comptes_parents
  for insert
  with check (id = auth.uid() and abonnement_actif = false);

drop policy if exists "comptes_parents_maj_propre"
  on public.comptes_parents;

create policy "comptes_parents_maj_propre"
  on public.comptes_parents
  for update
  using (id = auth.uid())
  with check (id = auth.uid() and abonnement_actif = false);

-- ---------------------------------------------------------------------
-- appareils_reconnus
-- Un appareil enregistre ici n'a plus besoin du code de verification
-- par email a la prochaine connexion sur ce compte. Le jeton d'appareil
-- lui-meme (genere cote app, stocke localement) n'est jamais transmis
-- en clair a la base : seul son empreinte (hash) est stockee.
-- ---------------------------------------------------------------------
create table if not exists public.appareils_reconnus (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  jeton_hash text not null,
  nom_appareil text,
  cree_le timestamptz not null default now(),
  derniere_utilisation_le timestamptz not null default now(),
  unique (user_id, jeton_hash)
);

alter table public.appareils_reconnus enable row level security;

drop policy if exists "appareils_du_compte"
  on public.appareils_reconnus;

create policy "appareils_du_compte"
  on public.appareils_reconnus
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- codes_verification
-- Code a usage unique envoye par email quand un appareil n'est pas
-- reconnu. AUCUNE policy volontairement : ni l'utilisateur authentifie,
-- ni un visiteur anonyme ne peuvent lire/ecrire cette table depuis
-- l'app. Seule une Edge Function utilisant la cle service_role (donc
-- hors RLS) peut y ecrire ou verifier un code.
-- ---------------------------------------------------------------------
create table if not exists public.codes_verification (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  code_hash text not null,
  jeton_appareil_hash text not null,
  cree_le timestamptz not null default now(),
  expire_le timestamptz not null,
  utilise_le timestamptz,
  tentatives int not null default 0
);

alter table public.codes_verification enable row level security;

-- Nettoyage : les vieux codes (utilises ou perimes depuis longtemps)
-- n'ont pas besoin d'etre conserves indefiniment.
create index if not exists codes_verification_expire_le_idx
  on public.codes_verification (expire_le);
