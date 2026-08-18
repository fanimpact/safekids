-- =====================================================================
-- SafeKids - Espace professionnel : garantir la ligne auth.identities
--
-- Constat : convertir une session anonyme en compte reel via
-- auth.updateUser(email, password) ne cree pas systematiquement de
-- ligne dans auth.identities (provider "email") tant que la
-- confirmation par email n'a pas ete cliquee -- or signInWithPassword
-- semble en avoir besoin independamment du mot de passe lui-meme.
-- C'est ce qui a bloque la reconnexion a plusieurs reprises ce soir.
--
-- Cette fonction est appelee automatiquement par l'app juste apres
-- chaque creation de compte (AccountService.createAccount), pour que
-- la ligne d'identite existe immediatement, sans dependre du clic sur
-- le lien de confirmation.
--
-- Idempotente (ON CONFLICT DO NOTHING) : peut etre appelee plusieurs
-- fois sans risque, y compris sur un compte deja correctement forme.
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
-- Rattrapage ponctuel : cree la ligne manquante pour tout compte deja
-- existant qui aurait un email (confirme ou en attente) mais aucune
-- identite "email" -- sans effet sur les comptes deja corrects.
-- ---------------------------------------------------------------------
insert into auth.identities (
  id, provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(), u.id, u.id,
  jsonb_build_object(
    'sub', u.id,
    'email', coalesce(nullif(u.email, ''), nullif(u.email_change, '')),
    'email_verified', true,
    'phone_verified', false
  ),
  'email', now(), now(), now()
from auth.users u
where coalesce(nullif(u.email, ''), nullif(u.email_change, '')) is not null
  and not exists (
    select 1 from auth.identities i
    where i.user_id = u.id and i.provider = 'email'
  );
