-- =====================================================================
-- KidsRelay - DUMP pg_dump AUTHENTIQUE
--
-- Projet Supabase : xcugfdjaifdibwowlrpi (eu-central-1)
-- Date de capture : 23/08/2026
-- Produit par     : pg_dump (PostgreSQL) 18.6, option --schema-only
-- Serveur source  : PostgreSQL 17.6.1.155
--
-- Contenu : 16 tables, 150 colonnes, 40 policies RLS, 18 fonctions,
-- 68 contraintes, 4 index explicites, 0 vue, 0 trigger.
-- STRUCTURE UNIQUEMENT : aucune donnee (0 INSERT, 0 COPY).
--
-- Options reprises a l'identique de `supabase db dump --linked`, dont
-- l'exclusion des schemas internes de la plateforme. Seul le schema
-- `public` figure ici.
--
-- ---------------------------------------------------------------------
-- REJOUABLE, MAIS SUR UN PROJET SUPABASE UNIQUEMENT
-- ---------------------------------------------------------------------
--
-- Verifie le 23/08/2026 en le rejouant reellement sur un PostgreSQL
-- 18.6 vierge : 178 erreurs, 14 tables creees sur 16. Ce dump n'est
-- donc PAS autonome. Il suppose l'environnement d'un projet Supabase,
-- qu'il ne recree pas :
--
--   - les roles      : anon, authenticated, service_role
--   - les schemas    : auth (referencie par 9 cles etrangeres),
--                      extensions
--   - les extensions : pg_cron, supabase_vault
--   - la publication : supabase_realtime
--
-- Les deux tables qui echouent sur une base nue sont `partages` et
-- `enfants_etablissements` : leur colonne `token` a pour valeur par
-- defaut extensions.gen_random_bytes(24), donc le schema `extensions`
-- doit exister avant. Les 23 erreurs suivantes en decoulent (policies
-- et contraintes portant sur ces deux tables).
--
-- Sur une base Supabase neuve, ces prerequis sont deja en place.
--
-- ---------------------------------------------------------------------
-- A NE PAS CONFONDRE
-- ---------------------------------------------------------------------
--
-- schema_reel_2026-08-23.sql, dans ce meme dossier, est une
-- reconstruction depuis les catalogues PostgreSQL, faite avant que les
-- outils clients ne soient installes. Ce n'est pas un dump : c'est une
-- photographie lisible, destinee a la comparaison avec les 17 fichiers
-- supabase/*.sql (voir docs/audits/ecart_schema.md).
--
-- Les deux fichiers ont ete compares le 23/08/2026 : tables, colonnes,
-- policies et fonctions concordent a l'identique. Seule la forme
-- differe (pg_dump emet les index de contrainte comme ADD CONSTRAINT
-- et les CHECK en ligne dans CREATE TABLE).
--
-- ---------------------------------------------------------------------
--
-- Ce fichier est date et ne se met pas a jour tout seul. Pour en
-- reprendre un :
--   supabase db dump --linked --dry-run > script.sh
-- puis executer ce script avec le pg_dump natif (scoop install
-- postgresql). Corriger au passage --quote-all-identifier en
-- --quote-all-identifiers : la CLI affiche le singulier, pg_dump
-- attend le pluriel.
-- =====================================================================

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."enfant_confie_a"("p_enfant_id" "uuid", "p_niveau_requis" "text" DEFAULT 'lecture'::"text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."enfant_confie_a"("p_enfant_id" "uuid", "p_niveau_requis" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enfant_du_parent"("p_enfant_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.enfants
    where id = p_enfant_id and parent_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."enfant_du_parent"("p_enfant_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enfant_visible_par_etablissement"("p_enfant_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.enfant_id = p_enfant_id
      and ee.statut = 'actif'
      and ee.date_expiration > now()
      and ee.etablissement_id is not null
      and public.est_membre_actif(ee.etablissement_id)
  );
$$;


ALTER FUNCTION "public"."enfant_visible_par_etablissement"("p_enfant_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."est_membre_actif"("p_etablissement_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.membres_etablissement
    where user_id = auth.uid()
      and etablissement_id = p_etablissement_id
      and statut = 'actif'
  );
$$;


ALTER FUNCTION "public"."est_membre_actif"("p_etablissement_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."etablissement_du_parent"("p_etablissement_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.etablissement_id = p_etablissement_id
      and public.enfant_du_parent(ee.enfant_id)
  );
$$;


ALTER FUNCTION "public"."etablissement_du_parent"("p_etablissement_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nombre_gestionnaires_actifs"("p_etablissement_id" "uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select count(*)::integer
  from public.membres_etablissement
  where etablissement_id = p_etablissement_id
    and statut = 'actif'
    and role in ('directeur', 'adjoint');
$$;


ALTER FUNCTION "public"."nombre_gestionnaires_actifs"("p_etablissement_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."peut_gerer_membres"("p_etablissement_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.membres_etablissement
    where user_id = auth.uid()
      and etablissement_id = p_etablissement_id
      and statut = 'actif'
      and role in ('directeur', 'adjoint')
  );
$$;


ALTER FUNCTION "public"."peut_gerer_membres"("p_etablissement_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_activer_confiances_en_attente"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_activer_confiances_en_attente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_activer_invitations_en_attente"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_activer_invitations_en_attente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_assurer_identite_email"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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

  -- Cause racine confirmee (19/08/2026) : comptes_parents.email n'est
  -- ecrit qu'une fois, lors de AccountService.createAccount() --
  -- jamais resynchronise si l'email de auth.users change ensuite (ex.
  -- correction manuelle en base pendant le debogage du 17-18/08). Les
  -- notifications par email (note ajoutee, expiration) lisent
  -- comptes_parents.email, pas auth.users.email : un ecart entre les
  -- deux fait partir l'email vers une adresse perimee, en silence,
  -- sans jamais faire echouer l'appel Brevo (l'adresse perimee peut
  -- tres bien exister). On les garde synchronises ici a chaque appel.
  update public.comptes_parents
  set email = v_email
  where id = v_user_id
    and email is distinct from v_email;
end;
$$;


ALTER FUNCTION "public"."rpc_assurer_identite_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_changer_niveau_confiance"("p_confiance_id" "uuid", "p_nouveau_niveau" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_changer_niveau_confiance"("p_confiance_id" "uuid", "p_nouveau_niveau" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_changer_role_membre"("p_membre_id" "uuid", "p_nouveau_role" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_changer_role_membre"("p_membre_id" "uuid", "p_nouveau_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_creer_etablissement"("p_nom" "text", "p_type" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_creer_etablissement"("p_nom" "text", "p_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_inviter_membre"("p_etablissement_id" "uuid", "p_email" "text", "p_role" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_inviter_membre"("p_etablissement_id" "uuid", "p_email" "text", "p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_inviter_personne_confiance"("p_enfant_id" "uuid", "p_email" "text", "p_niveau_acces" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_inviter_personne_confiance"("p_enfant_id" "uuid", "p_email" "text", "p_niveau_acces" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_reclamer_rattachement"("p_token" "text", "p_etablissement_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_reclamer_rattachement"("p_token" "text", "p_etablissement_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_revoquer_confiance"("p_confiance_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_revoquer_confiance"("p_confiance_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_revoquer_membre"("p_membre_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."rpc_revoquer_membre"("p_membre_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activites_preparees" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cree_par" "uuid" NOT NULL,
    "parent_id" "uuid",
    "etablissement_id" "uuid",
    "nom_activite" "text",
    "date_activite" timestamp with time zone,
    "lieu" "text",
    "description" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "enfants_ids" "uuid"[] DEFAULT '{}'::"uuid"[] NOT NULL,
    "cree_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modifie_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modifie_par" "uuid",
    CONSTRAINT "un_seul_proprietaire" CHECK ((((("parent_id" IS NOT NULL))::integer + (("etablissement_id" IS NOT NULL))::integer) = 1))
);


ALTER TABLE "public"."activites_preparees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."activites_recommandations_masquees" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "activite_id" "uuid" NOT NULL,
    "cle_recommandation" "text" NOT NULL,
    "masque_le" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."activites_recommandations_masquees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."appareils_reconnus" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "jeton_hash" "text" NOT NULL,
    "nom_appareil" "text",
    "cree_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "derniere_utilisation_le" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."appareils_reconnus" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."codes_verification" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "code_hash" "text" NOT NULL,
    "jeton_appareil_hash" "text" NOT NULL,
    "cree_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expire_le" timestamp with time zone NOT NULL,
    "utilise_le" timestamp with time zone,
    "tentatives" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."codes_verification" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comptes_parents" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "abonnement_actif" boolean DEFAULT false NOT NULL,
    "compte_relie_le" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."comptes_parents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."enfants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parent_id" "uuid" NOT NULL,
    "prenom" "text",
    "nom" "text",
    "date_naissance" "date",
    "poids" numeric,
    "taille" numeric,
    "date_maj_poids" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "a_pathologies_diagnostiquees" boolean
);


ALTER TABLE "public"."enfants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."enfants_confiance" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "user_id" "uuid",
    "niveau_acces" "text" DEFAULT 'lecture'::"text" NOT NULL,
    "statut" "text" DEFAULT 'invite'::"text" NOT NULL,
    "invite_par" "uuid" NOT NULL,
    "invite_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "accepte_le" timestamp with time zone,
    "revoque_par" "uuid",
    "revoque_le" timestamp with time zone,
    CONSTRAINT "enfants_confiance_niveau_acces_check" CHECK (("niveau_acces" = ANY (ARRAY['lecture'::"text", 'lecture_ecriture'::"text"]))),
    CONSTRAINT "enfants_confiance_statut_check" CHECK (("statut" = ANY (ARRAY['invite'::"text", 'actif'::"text", 'revoque'::"text"])))
);


ALTER TABLE "public"."enfants_confiance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."enfants_etablissements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "text" DEFAULT "encode"("extensions"."gen_random_bytes"(24), 'hex'::"text") NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "etablissement_id" "uuid",
    "statut" "text" DEFAULT 'en_attente'::"text" NOT NULL,
    "date_creation" timestamp with time zone DEFAULT "now"() NOT NULL,
    "date_expiration" timestamp with time zone NOT NULL,
    "claime_par" "uuid",
    "claime_le" timestamp with time zone,
    "revoque_le" timestamp with time zone,
    CONSTRAINT "enfants_etablissements_statut_check" CHECK (("statut" = ANY (ARRAY['en_attente'::"text", 'actif'::"text", 'revoque'::"text"])))
);


ALTER TABLE "public"."enfants_etablissements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."etablissements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nom" "text" NOT NULL,
    "type_etablissement" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."etablissements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."evenements_notification_parent" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parent_id" "uuid" NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "type_evenement" "text" NOT NULL,
    "donnees" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "statut_email" "text" DEFAULT 'en_attente'::"text" NOT NULL,
    "email_envoye_le" timestamp with time zone,
    "statut_push" "text" DEFAULT 'non_branche'::"text" NOT NULL,
    "push_envoye_le" timestamp with time zone,
    "cree_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "evenements_notification_parent_statut_email_check" CHECK (("statut_email" = ANY (ARRAY['en_attente'::"text", 'envoye'::"text", 'echoue'::"text"]))),
    CONSTRAINT "evenements_notification_parent_statut_push_check" CHECK (("statut_push" = ANY (ARRAY['non_branche'::"text", 'en_attente'::"text", 'envoye'::"text", 'echoue'::"text"]))),
    CONSTRAINT "evenements_notification_parent_type_evenement_check" CHECK (("type_evenement" = ANY (ARRAY['note_ajoutee'::"text", 'expiration_rattachement_7_jours'::"text", 'rappel_mise_a_jour_profil'::"text"])))
);


ALTER TABLE "public"."evenements_notification_parent" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."journal_consultations_fiche" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "etablissement_id" "uuid",
    "type_fiche" "text" NOT NULL,
    "consulte_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "journal_consultations_fiche_type_fiche_check" CHECK (("type_fiche" = ANY (ARRAY['secours'::"text", 'ce_qu_il_faut_savoir'::"text", 'profil_activites'::"text", 'mode_urgence'::"text"])))
);


ALTER TABLE "public"."journal_consultations_fiche" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."membres_etablissement" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "etablissement_id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "user_id" "uuid",
    "role" "text" NOT NULL,
    "statut" "text" DEFAULT 'invite'::"text" NOT NULL,
    "invite_par" "uuid" NOT NULL,
    "invite_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "accepte_le" timestamp with time zone,
    "revoque_par" "uuid",
    "revoque_le" timestamp with time zone,
    CONSTRAINT "membres_etablissement_role_check" CHECK (("role" = ANY (ARRAY['directeur'::"text", 'adjoint'::"text", 'membre'::"text"]))),
    CONSTRAINT "membres_etablissement_statut_check" CHECK (("statut" = ANY (ARRAY['invite'::"text", 'actif'::"text", 'revoque'::"text"])))
);


ALTER TABLE "public"."membres_etablissement" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notes_activite" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "activite_id" "uuid" NOT NULL,
    "auteur_id" "uuid" NOT NULL,
    "enfant_id" "uuid",
    "note" "text" NOT NULL,
    "cree_le" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modifie_le" timestamp with time zone
);


ALTER TABLE "public"."notes_activite" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."partages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "text" DEFAULT "encode"("extensions"."gen_random_bytes"(24), 'hex'::"text") NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "type_fiche" "text" NOT NULL,
    "date_creation" timestamp with time zone DEFAULT "now"() NOT NULL,
    "date_expiration" timestamp with time zone NOT NULL,
    "date_derniere_consultation" timestamp with time zone,
    "contenu_fige" "jsonb",
    "activite_id" "uuid",
    "destinataire" "text" DEFAULT 'particulier'::"text" NOT NULL,
    CONSTRAINT "partages_destinataire_check" CHECK (("destinataire" = ANY (ARRAY['particulier'::"text", 'structure_accueil'::"text"]))),
    CONSTRAINT "partages_type_fiche_check" CHECK (("type_fiche" = ANY (ARRAY['secours'::"text", 'ce_qu_il_faut_savoir'::"text", 'recommandations_activite'::"text"])))
);


ALTER TABLE "public"."partages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profils_activites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "habillage" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "toilettes" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "communication" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "transport" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "securite" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "nuitee" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "activite_aquatique" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "effort_marche" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "transitions" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "autres_informations" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "repas" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."profils_activites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profils_sante" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "enfant_id" "uuid" NOT NULL,
    "pathologies" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "allergies" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "traitements_urgence" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "traitements_reguliers" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "dispositifs_medicaux" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "medecin_traitant" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "facteurs_declenchants" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "contacts_urgence" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "evenements_medicaux" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "observations_medicales" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "traitements_arretes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "a_pathologies" boolean,
    "a_allergies" boolean,
    "a_traitements_reguliers" boolean,
    "a_traitements_arretes" boolean,
    "a_traitements_urgence" boolean,
    "a_dispositifs_medicaux" boolean
);


ALTER TABLE "public"."profils_sante" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activites_preparees"
    ADD CONSTRAINT "activites_preparees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."activites_recommandations_masquees"
    ADD CONSTRAINT "activites_recommandations_mas_user_id_activite_id_cle_recom_key" UNIQUE ("user_id", "activite_id", "cle_recommandation");



ALTER TABLE ONLY "public"."activites_recommandations_masquees"
    ADD CONSTRAINT "activites_recommandations_masquees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appareils_reconnus"
    ADD CONSTRAINT "appareils_reconnus_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appareils_reconnus"
    ADD CONSTRAINT "appareils_reconnus_user_id_jeton_hash_key" UNIQUE ("user_id", "jeton_hash");



ALTER TABLE ONLY "public"."codes_verification"
    ADD CONSTRAINT "codes_verification_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comptes_parents"
    ADD CONSTRAINT "comptes_parents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_enfant_id_email_key" UNIQUE ("enfant_id", "email");



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."enfants_etablissements"
    ADD CONSTRAINT "enfants_etablissements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."enfants_etablissements"
    ADD CONSTRAINT "enfants_etablissements_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."enfants"
    ADD CONSTRAINT "enfants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."etablissements"
    ADD CONSTRAINT "etablissements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."evenements_notification_parent"
    ADD CONSTRAINT "evenements_notification_parent_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journal_consultations_fiche"
    ADD CONSTRAINT "journal_consultations_fiche_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_etablissement_id_email_key" UNIQUE ("etablissement_id", "email");



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notes_activite"
    ADD CONSTRAINT "notes_activite_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partages"
    ADD CONSTRAINT "partages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partages"
    ADD CONSTRAINT "partages_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."profils_activites"
    ADD CONSTRAINT "profils_activites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profils_sante"
    ADD CONSTRAINT "profils_sante_pkey" PRIMARY KEY ("id");



CREATE INDEX "codes_verification_expire_le_idx" ON "public"."codes_verification" USING "btree" ("expire_le");



CREATE INDEX "journal_consultations_consulte_le_idx" ON "public"."journal_consultations_fiche" USING "btree" ("consulte_le");



CREATE UNIQUE INDEX "profils_activites_enfant_id_key" ON "public"."profils_activites" USING "btree" ("enfant_id");



CREATE UNIQUE INDEX "profils_sante_enfant_id_key" ON "public"."profils_sante" USING "btree" ("enfant_id");



ALTER TABLE ONLY "public"."activites_preparees"
    ADD CONSTRAINT "activites_preparees_cree_par_fkey" FOREIGN KEY ("cree_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."activites_preparees"
    ADD CONSTRAINT "activites_preparees_etablissement_id_fkey" FOREIGN KEY ("etablissement_id") REFERENCES "public"."etablissements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activites_preparees"
    ADD CONSTRAINT "activites_preparees_modifie_par_fkey" FOREIGN KEY ("modifie_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."activites_preparees"
    ADD CONSTRAINT "activites_preparees_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."activites_recommandations_masquees"
    ADD CONSTRAINT "activites_recommandations_masquees_activite_id_fkey" FOREIGN KEY ("activite_id") REFERENCES "public"."activites_preparees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activites_recommandations_masquees"
    ADD CONSTRAINT "activites_recommandations_masquees_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."appareils_reconnus"
    ADD CONSTRAINT "appareils_reconnus_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."codes_verification"
    ADD CONSTRAINT "codes_verification_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comptes_parents"
    ADD CONSTRAINT "comptes_parents_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_invite_par_fkey" FOREIGN KEY ("invite_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_revoque_par_fkey" FOREIGN KEY ("revoque_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."enfants_confiance"
    ADD CONSTRAINT "enfants_confiance_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."enfants_etablissements"
    ADD CONSTRAINT "enfants_etablissements_claime_par_fkey" FOREIGN KEY ("claime_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."enfants_etablissements"
    ADD CONSTRAINT "enfants_etablissements_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."enfants_etablissements"
    ADD CONSTRAINT "enfants_etablissements_etablissement_id_fkey" FOREIGN KEY ("etablissement_id") REFERENCES "public"."etablissements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."enfants"
    ADD CONSTRAINT "enfants_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."etablissements"
    ADD CONSTRAINT "etablissements_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."evenements_notification_parent"
    ADD CONSTRAINT "evenements_notification_parent_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."evenements_notification_parent"
    ADD CONSTRAINT "evenements_notification_parent_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."journal_consultations_fiche"
    ADD CONSTRAINT "journal_consultations_fiche_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_consultations_fiche"
    ADD CONSTRAINT "journal_consultations_fiche_etablissement_id_fkey" FOREIGN KEY ("etablissement_id") REFERENCES "public"."etablissements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_consultations_fiche"
    ADD CONSTRAINT "journal_consultations_fiche_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_etablissement_id_fkey" FOREIGN KEY ("etablissement_id") REFERENCES "public"."etablissements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_invite_par_fkey" FOREIGN KEY ("invite_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_revoque_par_fkey" FOREIGN KEY ("revoque_par") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."membres_etablissement"
    ADD CONSTRAINT "membres_etablissement_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notes_activite"
    ADD CONSTRAINT "notes_activite_activite_id_fkey" FOREIGN KEY ("activite_id") REFERENCES "public"."activites_preparees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notes_activite"
    ADD CONSTRAINT "notes_activite_auteur_id_fkey" FOREIGN KEY ("auteur_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notes_activite"
    ADD CONSTRAINT "notes_activite_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."partages"
    ADD CONSTRAINT "partages_activite_id_fkey" FOREIGN KEY ("activite_id") REFERENCES "public"."activites_preparees"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."partages"
    ADD CONSTRAINT "partages_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profils_activites"
    ADD CONSTRAINT "profils_activites_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profils_sante"
    ADD CONSTRAINT "profils_sante_enfant_id_fkey" FOREIGN KEY ("enfant_id") REFERENCES "public"."enfants"("id") ON DELETE CASCADE;



CREATE POLICY "activites_creation_par_membre" ON "public"."activites_preparees" FOR INSERT WITH CHECK ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id") AND ("cree_par" = "auth"."uid"())));



CREATE POLICY "activites_du_parent" ON "public"."activites_preparees" USING (("parent_id" = "auth"."uid"())) WITH CHECK ((("parent_id" = "auth"."uid"()) AND ("cree_par" = "auth"."uid"())));



CREATE POLICY "activites_lecture_par_membre" ON "public"."activites_preparees" FOR SELECT USING ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id")));



CREATE POLICY "activites_modification_par_membre" ON "public"."activites_preparees" FOR UPDATE USING ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id"))) WITH CHECK ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id")));



ALTER TABLE "public"."activites_preparees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."activites_recommandations_masquees" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "activites_suppression_par_membre" ON "public"."activites_preparees" FOR DELETE USING ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id")));



CREATE POLICY "appareils_du_compte" ON "public"."appareils_reconnus" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."appareils_reconnus" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."codes_verification" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comptes_parents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comptes_parents_creation_propre" ON "public"."comptes_parents" FOR INSERT WITH CHECK ((("id" = "auth"."uid"()) AND ("abonnement_actif" = false)));



CREATE POLICY "comptes_parents_lecture_propre" ON "public"."comptes_parents" FOR SELECT USING (("id" = "auth"."uid"()));



CREATE POLICY "comptes_parents_maj_propre" ON "public"."comptes_parents" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK ((("id" = "auth"."uid"()) AND ("abonnement_actif" = false)));



ALTER TABLE "public"."enfants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."enfants_confiance" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "enfants_confiance_lecture" ON "public"."enfants_confiance" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR "public"."enfant_du_parent"("enfant_id")));



CREATE POLICY "enfants_du_parent" ON "public"."enfants" USING (("parent_id" = "auth"."uid"())) WITH CHECK (("parent_id" = "auth"."uid"()));



ALTER TABLE "public"."enfants_etablissements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "enfants_etablissements_du_parent" ON "public"."enfants_etablissements" USING ("public"."enfant_du_parent"("enfant_id")) WITH CHECK ("public"."enfant_du_parent"("enfant_id"));



CREATE POLICY "enfants_etablissements_lecture_par_membre" ON "public"."enfants_etablissements" FOR SELECT USING ((("etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("etablissement_id")));



CREATE POLICY "enfants_etablissements_lecture_token_en_attente" ON "public"."enfants_etablissements" FOR SELECT USING ((("statut" = 'en_attente'::"text") AND ("date_expiration" > "now"())));



CREATE POLICY "enfants_modifiables_par_personne_de_confiance" ON "public"."enfants" FOR UPDATE USING ("public"."enfant_confie_a"("id", 'lecture_ecriture'::"text")) WITH CHECK ("public"."enfant_confie_a"("id", 'lecture_ecriture'::"text"));



CREATE POLICY "enfants_visibles_par_etablissement" ON "public"."enfants" FOR SELECT USING ("public"."enfant_visible_par_etablissement"("id"));



CREATE POLICY "enfants_visibles_par_personne_de_confiance" ON "public"."enfants" FOR SELECT USING ("public"."enfant_confie_a"("id"));



ALTER TABLE "public"."etablissements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "etablissements_visibles_par_membre_actif" ON "public"."etablissements" FOR SELECT USING ("public"."est_membre_actif"("id"));



CREATE POLICY "etablissements_visibles_par_parent_enfant_rattache" ON "public"."etablissements" FOR SELECT USING ("public"."etablissement_du_parent"("id"));



CREATE POLICY "evenements_notification_lecture_par_parent" ON "public"."evenements_notification_parent" FOR SELECT USING (("parent_id" = "auth"."uid"()));



ALTER TABLE "public"."evenements_notification_parent" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journal_consultations_fiche" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journal_ecriture_par_membre_actif" ON "public"."journal_consultations_fiche" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) AND "public"."enfant_visible_par_etablissement"("enfant_id")));



CREATE POLICY "journal_lecture_par_parent" ON "public"."journal_consultations_fiche" FOR SELECT USING ("public"."enfant_du_parent"("enfant_id"));



CREATE POLICY "masquages_ecriture_insert" ON "public"."activites_recommandations_masquees" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."activites_preparees" "a"
  WHERE (("a"."id" = "activites_recommandations_masquees"."activite_id") AND (("a"."parent_id" = "auth"."uid"()) OR (("a"."etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("a"."etablissement_id"))))))));



CREATE POLICY "masquages_ecriture_update" ON "public"."activites_recommandations_masquees" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."activites_preparees" "a"
  WHERE (("a"."id" = "activites_recommandations_masquees"."activite_id") AND (("a"."parent_id" = "auth"."uid"()) OR (("a"."etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("a"."etablissement_id"))))))));



CREATE POLICY "masquages_lecture" ON "public"."activites_recommandations_masquees" FOR SELECT USING ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."activites_preparees" "a"
  WHERE (("a"."id" = "activites_recommandations_masquees"."activite_id") AND (("a"."parent_id" = "auth"."uid"()) OR (("a"."etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("a"."etablissement_id"))))))));



CREATE POLICY "masquages_suppression" ON "public"."activites_recommandations_masquees" FOR DELETE USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."membres_etablissement" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "membres_lecture_par_membre_actif_ou_soi_meme" ON "public"."membres_etablissement" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR "public"."est_membre_actif"("etablissement_id")));



ALTER TABLE "public"."notes_activite" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notes_creation_par_membre" ON "public"."notes_activite" FOR INSERT WITH CHECK ((("auteur_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."activites_preparees" "a"
  WHERE (("a"."id" = "notes_activite"."activite_id") AND ("a"."etablissement_id" IS NOT NULL) AND "public"."est_membre_actif"("a"."etablissement_id"))))));



CREATE POLICY "notes_lecture_auteur_ou_parent" ON "public"."notes_activite" FOR SELECT USING ((("auteur_id" = "auth"."uid"()) OR (("enfant_id" IS NOT NULL) AND "public"."enfant_du_parent"("enfant_id"))));



CREATE POLICY "notes_modification_par_auteur" ON "public"."notes_activite" FOR UPDATE USING (("auteur_id" = "auth"."uid"())) WITH CHECK (("auteur_id" = "auth"."uid"()));



CREATE POLICY "notes_suppression_par_auteur" ON "public"."notes_activite" FOR DELETE USING (("auteur_id" = "auth"."uid"()));



ALTER TABLE "public"."partages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "partages_geres_par_le_parent" ON "public"."partages" USING ("public"."enfant_du_parent"("enfant_id")) WITH CHECK ("public"."enfant_du_parent"("enfant_id"));



ALTER TABLE "public"."profils_activites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profils_activites_du_parent" ON "public"."profils_activites" USING (("enfant_id" IN ( SELECT "enfants"."id"
   FROM "public"."enfants"
  WHERE ("enfants"."parent_id" = "auth"."uid"())))) WITH CHECK (("enfant_id" IN ( SELECT "enfants"."id"
   FROM "public"."enfants"
  WHERE ("enfants"."parent_id" = "auth"."uid"()))));



CREATE POLICY "profils_activites_modifiables_par_personne_de_confiance" ON "public"."profils_activites" FOR UPDATE USING ("public"."enfant_confie_a"("enfant_id", 'lecture_ecriture'::"text")) WITH CHECK ("public"."enfant_confie_a"("enfant_id", 'lecture_ecriture'::"text"));



CREATE POLICY "profils_activites_visibles_par_etablissement" ON "public"."profils_activites" FOR SELECT USING ("public"."enfant_visible_par_etablissement"("enfant_id"));



CREATE POLICY "profils_activites_visibles_par_personne_de_confiance" ON "public"."profils_activites" FOR SELECT USING ("public"."enfant_confie_a"("enfant_id"));



ALTER TABLE "public"."profils_sante" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profils_sante_du_parent" ON "public"."profils_sante" USING (("enfant_id" IN ( SELECT "enfants"."id"
   FROM "public"."enfants"
  WHERE ("enfants"."parent_id" = "auth"."uid"())))) WITH CHECK (("enfant_id" IN ( SELECT "enfants"."id"
   FROM "public"."enfants"
  WHERE ("enfants"."parent_id" = "auth"."uid"()))));



CREATE POLICY "profils_sante_modifiables_par_personne_de_confiance" ON "public"."profils_sante" FOR UPDATE USING ("public"."enfant_confie_a"("enfant_id", 'lecture_ecriture'::"text")) WITH CHECK ("public"."enfant_confie_a"("enfant_id", 'lecture_ecriture'::"text"));



CREATE POLICY "profils_sante_visibles_par_etablissement" ON "public"."profils_sante" FOR SELECT USING ("public"."enfant_visible_par_etablissement"("enfant_id"));



CREATE POLICY "profils_sante_visibles_par_personne_de_confiance" ON "public"."profils_sante" FOR SELECT USING ("public"."enfant_confie_a"("enfant_id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON FUNCTION "public"."enfant_confie_a"("p_enfant_id" "uuid", "p_niveau_requis" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."enfant_confie_a"("p_enfant_id" "uuid", "p_niveau_requis" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."enfant_confie_a"("p_enfant_id" "uuid", "p_niveau_requis" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."enfant_du_parent"("p_enfant_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."enfant_du_parent"("p_enfant_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."enfant_du_parent"("p_enfant_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."enfant_visible_par_etablissement"("p_enfant_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."enfant_visible_par_etablissement"("p_enfant_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."enfant_visible_par_etablissement"("p_enfant_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."est_membre_actif"("p_etablissement_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."est_membre_actif"("p_etablissement_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."est_membre_actif"("p_etablissement_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."etablissement_du_parent"("p_etablissement_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."etablissement_du_parent"("p_etablissement_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."etablissement_du_parent"("p_etablissement_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."nombre_gestionnaires_actifs"("p_etablissement_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."nombre_gestionnaires_actifs"("p_etablissement_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."nombre_gestionnaires_actifs"("p_etablissement_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."peut_gerer_membres"("p_etablissement_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."peut_gerer_membres"("p_etablissement_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."peut_gerer_membres"("p_etablissement_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_activer_confiances_en_attente"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_activer_confiances_en_attente"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_activer_confiances_en_attente"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_activer_invitations_en_attente"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_activer_invitations_en_attente"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_activer_invitations_en_attente"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_assurer_identite_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_assurer_identite_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_assurer_identite_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_changer_niveau_confiance"("p_confiance_id" "uuid", "p_nouveau_niveau" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_changer_niveau_confiance"("p_confiance_id" "uuid", "p_nouveau_niveau" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_changer_niveau_confiance"("p_confiance_id" "uuid", "p_nouveau_niveau" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_changer_role_membre"("p_membre_id" "uuid", "p_nouveau_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_changer_role_membre"("p_membre_id" "uuid", "p_nouveau_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_changer_role_membre"("p_membre_id" "uuid", "p_nouveau_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_creer_etablissement"("p_nom" "text", "p_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_creer_etablissement"("p_nom" "text", "p_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_creer_etablissement"("p_nom" "text", "p_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_inviter_membre"("p_etablissement_id" "uuid", "p_email" "text", "p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_inviter_membre"("p_etablissement_id" "uuid", "p_email" "text", "p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_inviter_membre"("p_etablissement_id" "uuid", "p_email" "text", "p_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_inviter_personne_confiance"("p_enfant_id" "uuid", "p_email" "text", "p_niveau_acces" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_inviter_personne_confiance"("p_enfant_id" "uuid", "p_email" "text", "p_niveau_acces" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_inviter_personne_confiance"("p_enfant_id" "uuid", "p_email" "text", "p_niveau_acces" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_reclamer_rattachement"("p_token" "text", "p_etablissement_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_reclamer_rattachement"("p_token" "text", "p_etablissement_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_reclamer_rattachement"("p_token" "text", "p_etablissement_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_revoquer_confiance"("p_confiance_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_revoquer_confiance"("p_confiance_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_revoquer_confiance"("p_confiance_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_revoquer_membre"("p_membre_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_revoquer_membre"("p_membre_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_revoquer_membre"("p_membre_id" "uuid") TO "service_role";
























GRANT ALL ON TABLE "public"."activites_preparees" TO "anon";
GRANT ALL ON TABLE "public"."activites_preparees" TO "authenticated";
GRANT ALL ON TABLE "public"."activites_preparees" TO "service_role";



GRANT ALL ON TABLE "public"."activites_recommandations_masquees" TO "anon";
GRANT ALL ON TABLE "public"."activites_recommandations_masquees" TO "authenticated";
GRANT ALL ON TABLE "public"."activites_recommandations_masquees" TO "service_role";



GRANT ALL ON TABLE "public"."appareils_reconnus" TO "anon";
GRANT ALL ON TABLE "public"."appareils_reconnus" TO "authenticated";
GRANT ALL ON TABLE "public"."appareils_reconnus" TO "service_role";



GRANT ALL ON TABLE "public"."codes_verification" TO "anon";
GRANT ALL ON TABLE "public"."codes_verification" TO "authenticated";
GRANT ALL ON TABLE "public"."codes_verification" TO "service_role";



GRANT ALL ON TABLE "public"."comptes_parents" TO "anon";
GRANT ALL ON TABLE "public"."comptes_parents" TO "authenticated";
GRANT ALL ON TABLE "public"."comptes_parents" TO "service_role";



GRANT ALL ON TABLE "public"."enfants" TO "anon";
GRANT ALL ON TABLE "public"."enfants" TO "authenticated";
GRANT ALL ON TABLE "public"."enfants" TO "service_role";



GRANT ALL ON TABLE "public"."enfants_confiance" TO "anon";
GRANT ALL ON TABLE "public"."enfants_confiance" TO "authenticated";
GRANT ALL ON TABLE "public"."enfants_confiance" TO "service_role";



GRANT ALL ON TABLE "public"."enfants_etablissements" TO "anon";
GRANT ALL ON TABLE "public"."enfants_etablissements" TO "authenticated";
GRANT ALL ON TABLE "public"."enfants_etablissements" TO "service_role";



GRANT ALL ON TABLE "public"."etablissements" TO "anon";
GRANT ALL ON TABLE "public"."etablissements" TO "authenticated";
GRANT ALL ON TABLE "public"."etablissements" TO "service_role";



GRANT ALL ON TABLE "public"."evenements_notification_parent" TO "anon";
GRANT ALL ON TABLE "public"."evenements_notification_parent" TO "authenticated";
GRANT ALL ON TABLE "public"."evenements_notification_parent" TO "service_role";



GRANT ALL ON TABLE "public"."journal_consultations_fiche" TO "anon";
GRANT ALL ON TABLE "public"."journal_consultations_fiche" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_consultations_fiche" TO "service_role";



GRANT ALL ON TABLE "public"."membres_etablissement" TO "anon";
GRANT ALL ON TABLE "public"."membres_etablissement" TO "authenticated";
GRANT ALL ON TABLE "public"."membres_etablissement" TO "service_role";



GRANT ALL ON TABLE "public"."notes_activite" TO "anon";
GRANT ALL ON TABLE "public"."notes_activite" TO "authenticated";
GRANT ALL ON TABLE "public"."notes_activite" TO "service_role";



GRANT ALL ON TABLE "public"."partages" TO "anon";
GRANT ALL ON TABLE "public"."partages" TO "authenticated";
GRANT ALL ON TABLE "public"."partages" TO "service_role";



GRANT ALL ON TABLE "public"."profils_activites" TO "anon";
GRANT ALL ON TABLE "public"."profils_activites" TO "authenticated";
GRANT ALL ON TABLE "public"."profils_activites" TO "service_role";



GRANT ALL ON TABLE "public"."profils_sante" TO "anon";
GRANT ALL ON TABLE "public"."profils_sante" TO "authenticated";
GRANT ALL ON TABLE "public"."profils_sante" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































