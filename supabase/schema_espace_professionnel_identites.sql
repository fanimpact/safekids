-- =====================================================================
-- SafeKids - Espace professionnel : rendre un compte connectable
-- immediatement apres conversion anonyme -> reel, sans dependre du
-- clic sur le lien de confirmation par email.
--
-- Cause racine confirmee (18/08/2026), via une inspection directe de
-- auth.users : auth.updateUser(email, password) sur une session
-- anonyme ne pose PAS l'email sur auth.users.email tant que le lien de
-- confirmation n'a pas ete clique -- il est stocke en attente dans
-- auth.users.email_change, et auth.users.email reste NULL,
-- auth.users.is_anonymous reste TRUE.
--
-- Or signInWithPassword recherche le compte PAR auth.users.email :
-- avec cette colonne vide, la connexion est refusee ("Invalid login
-- credentials") de facon systematique et deterministe, quel que soit
-- le mot de passe -- meme correct. La session ouverte au moment de la
-- creation du compte continue de fonctionner (elle ne depend pas de
-- cette colonne), ce qui donne l'illusion que "ça marche juste apres
-- la creation" ; c'est seulement a la reconnexion suivante (typiquement
-- apres etre passe sur l'autre espace de l'app) que l'echec apparait --
-- exactement le symptome "systematique et symetrique" observe.
--
-- La verification par email sur nouvel appareil (code a usage unique,
-- voir schema_espace_professionnel_comptes.sql) est deja le vrai
-- garde-fou de securite de cette architecture (§1 du plan) ; le clic
-- sur le lien de confirmation initial n'apporte rien de plus a ce
-- niveau. Cette fonction confirme donc directement l'email cote
-- serveur, au lieu d'attendre ce clic.
--
-- Cette fonction est appelee automatiquement par l'app juste apres
-- chaque creation de compte (AccountService.createAccount), pour que
-- le compte soit immediatement utilisable pour se reconnecter.
--
-- Idempotente : peut etre appelee plusieurs fois sans risque, y
-- compris sur un compte deja correctement forme.
--
-- Ce fichier peut etre rejoue sans risque.
--
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

create or replace function public.rpc_assurer_identite_email()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_email text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    return;
  end if;

  -- Utilise l'email confirme s'il existe deja, sinon celui en attente
  -- de confirmation : dans les deux cas, c'est l'adresse avec laquelle
  -- la personne va essayer de se reconnecter.
  select coalesce(
    nullif(email, ''),
    nullif(email_change, '')
  )
  into v_email
  from auth.users
  where id = v_user_id;

  if v_email is null then
    return;
  end if;

  -- Confirme l'email directement sur auth.users, sans attendre le
  -- clic sur le lien envoye par Supabase : c'est cette colonne, pas
  -- auth.identities, que signInWithPassword utilise pour retrouver le
  -- compte.
  -- confirmed_at est une colonne generee (derivee de
  -- email_confirmed_at / phone_confirmed_at) : impossible de l'ecrire
  -- directement, elle se met a jour toute seule.
  update auth.users
  set
    email = v_email,
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    email_change = '',
    email_change_confirm_status = 0,
    is_anonymous = false
  where id = v_user_id;

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  )
  values (
    gen_random_uuid(), v_user_id, v_user_id,
    jsonb_build_object(
      'sub', v_user_id,
      'email', v_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  )
  on conflict (provider_id, provider) do nothing;
end;
$$;

-- ---------------------------------------------------------------------
-- Rattrapage ponctuel : applique la meme correction a tout compte deja
-- existant bloque dans cet etat (email en attente non confirme), et
-- cree la ligne d'identite manquante le cas echeant -- sans effet sur
-- les comptes deja corrects.
-- ---------------------------------------------------------------------
update auth.users
set
  email = coalesce(nullif(email, ''), nullif(email_change, '')),
  email_confirmed_at = coalesce(email_confirmed_at, now()),
  email_change = '',
  email_change_confirm_status = 0,
  is_anonymous = false
where email is null
  and nullif(email_change, '') is not null;

insert into auth.identities (
  id, provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(), u.id, u.id,
  jsonb_build_object(
    'sub', u.id,
    'email', u.email,
    'email_verified', true,
    'phone_verified', false
  ),
  'email', now(), now(), now()
from auth.users u
where nullif(u.email, '') is not null
  and not exists (
    select 1 from auth.identities i
    where i.user_id = u.id and i.provider = 'email'
  );
