-- ---------------------------------------------------------------------
-- Conformite RGPD (23/08/2026)
--
-- Quatre decisions mises en oeuvre par ce fichier :
--   1. delai de grace de 7 jours a la suppression du compte ;
--   2. consentement explicite a l'enregistrement des donnees de sante ;
--   3. compteurs d'usage anonymises ;
--   4. adresse email de secours.
--
-- A executer dans le SQL Editor de Supabase, en une fois. Le fichier
-- est reexecutable : chaque objet est cree "if not exists" ou remplace.
--
-- Ce fichier n'a PAS ete applique par l'agent. Comme les 17 autres, il
-- est execute a la main.
-- ---------------------------------------------------------------------


-- =====================================================================
-- 1. Colonnes ajoutees
-- =====================================================================

-- Le compte du parent porte desormais son etat administratif : demande
-- de suppression en cours, adresse de secours.
alter table public.comptes_parents
  add column if not exists email_secours text,
  add column if not exists suppression_demandee_le timestamptz,
  add column if not exists suppression_effective_le timestamptz;

comment on column public.comptes_parents.email_secours is
  'Seconde adresse, facultative, saisie par le parent. Sert uniquement '
  'a le recontacter s''il perd l''acces a son compte. Jamais utilisee '
  'pour un envoi automatique.';

comment on column public.comptes_parents.suppression_effective_le is
  'Date a laquelle les donnees seront effacees definitivement. Le '
  'compte est deja inaccessible depuis suppression_demandee_le.';

-- Le consentement porte sur l'enfant, pas sur le compte : un parent
-- peut avoir consenti pour un enfant et pas encore pour un autre.
alter table public.enfants
  add column if not exists consentement_sante_le timestamptz;

comment on column public.enfants.consentement_sante_le is
  'Date a laquelle le parent a coche la case autorisant '
  'l''enregistrement des informations de sante de cet enfant. Retirer '
  'le consentement revient a supprimer la fiche, donc la ligne.';


-- =====================================================================
-- 2. Suppression du compte : le compte devient inaccessible tout de
--    suite, les donnees sont effacees 7 jours plus tard
-- =====================================================================

-- "Le compte connecte est-il en attente de suppression ?"
--
-- security definer : la fonction doit pouvoir lire comptes_parents
-- meme depuis une policy, sans declencher de recursion.
create or replace function public.compte_en_suppression()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.comptes_parents
    where id = auth.uid()
      and suppression_demandee_le is not null
  );
$$;

-- Le blocage passe par deux leviers seulement, et c'est voulu :
-- multiplier les policies modifiees multiplierait les facons de se
-- tromper sur une base en production.
--
--   a) `enfant_du_parent()` : point de passage de toutes les policies
--      qui demandent "cet enfant est-il a ce parent ?"
--      (enfants_etablissements, etablissements, notes_activite...).
--      Elle est security definer, donc elle ne cascade pas toute
--      seule : il faut l'y ecrire.
--
--   b) les policies qui testent `parent_id = auth.uid()` en direct.
--
-- profils_sante et profils_activites ne sont pas touches : leurs
-- policies font une sous-requete ordinaire sur `enfants`, donc le RLS
-- de `enfants` s'y applique et le refus cascade.
--
-- `comptes_parents` reste lisible, volontairement : c'est la que
-- l'application lit l'etat de la demande pour afficher l'ecran
-- d'annulation. Un parent bloque doit pouvoir revenir en arriere.
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
  ) and not public.compte_en_suppression();
$$;

drop policy if exists "enfants_du_parent" on public.enfants;

create policy "enfants_du_parent"
  on public.enfants
  for all
  using (
    parent_id = auth.uid()
    and not public.compte_en_suppression()
  )
  with check (
    parent_id = auth.uid()
    and not public.compte_en_suppression()
  );

drop policy if exists "activites_du_parent"
  on public.activites_preparees;

create policy "activites_du_parent"
  on public.activites_preparees
  for all
  using (
    parent_id = auth.uid()
    and not public.compte_en_suppression()
  )
  with check (
    parent_id = auth.uid()
    and cree_par = auth.uid()
    and not public.compte_en_suppression()
  );

drop policy if exists "notifications_lecture_parent"
  on public.evenements_notification_parent;

create policy "notifications_lecture_parent"
  on public.evenements_notification_parent
  for select
  using (
    parent_id = auth.uid()
    and not public.compte_en_suppression()
  );

-- Demande de suppression. Renvoie la date d'effacement definitif, que
-- l'application affiche et que l'email reprend.
--
-- 7 jours : assez pour qu'un parent qui a cliqué par erreur, ou qui
-- part en week-end, puisse revenir. Pas au point de faire trainer un
-- effacement demande.
create or replace function public.demander_suppression_compte()
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_effective timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Aucun compte connecte.';
  end if;

  v_effective := now() + interval '7 days';

  -- La ligne peut ne pas exister : un compte cree avant l'espace
  -- professionnel n'a pas forcement de ligne comptes_parents.
  insert into public.comptes_parents (id, suppression_demandee_le, suppression_effective_le)
  values (auth.uid(), now(), v_effective)
  on conflict (id) do update
    set suppression_demandee_le = now(),
        suppression_effective_le = v_effective;

  return v_effective;
end;
$$;

-- Annulation. Le compte redevient accessible immediatement.
create or replace function public.annuler_suppression_compte()
returns void
language sql
security definer
set search_path = public
as $$
  update public.comptes_parents
  set suppression_demandee_le = null,
      suppression_effective_le = null
  where id = auth.uid();
$$;

-- Etat de la demande, lisible par le parent concerne uniquement.
-- Passe par une fonction plutot que par une lecture directe : le
-- parent bloque doit pouvoir lire ceci et rien d'autre.
create or replace function public.suppression_en_cours()
returns timestamptz
language sql
security definer
stable
set search_path = public
as $$
  select suppression_effective_le
  from public.comptes_parents
  where id = auth.uid()
    and suppression_demandee_le is not null;
$$;

grant execute on function public.demander_suppression_compte() to authenticated;
grant execute on function public.annuler_suppression_compte() to authenticated;
grant execute on function public.suppression_en_cours() to authenticated;

-- Effacement definitif, une fois par jour.
--
-- Supprimer la ligne auth.users suffit : enfants.parent_id,
-- comptes_parents.id et tout ce qui en derive sont en cascade. C'est
-- aussi ce qui garantit qu'aucune donnee ne survit a l'effacement
-- parce qu'on aurait oublie une table.
do $$
begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron indisponible : effacement automatique non programme.';
end;
$$;

select cron.unschedule('effacer-comptes-supprimes')
where exists (
  select 1 from cron.job where jobname = 'effacer-comptes-supprimes'
);

select cron.schedule(
  'effacer-comptes-supprimes',
  '0 4 * * *',
  $$
    delete from auth.users
    where id in (
      select id from public.comptes_parents
      where suppression_effective_le is not null
        and suppression_effective_le < now()
    );
  $$
);


-- =====================================================================
-- 3. Compteurs d'usage
--
-- Objectif : savoir combien de familles distinctes ont utilise chaque
-- fonctionnalite chaque mois. Jamais laquelle, jamais pour quel
-- enfant, jamais a quel moment.
--
-- Compter des familles DISTINCTES impose de garder un marqueur par
-- famille au moins le temps du mois : sinon on ne saurait pas si un
-- deuxieme usage vient de la meme famille. Le mois en cours est donc
-- pseudonyme, pas anonyme. C'est assume et documente.
--
-- Ce qui rend l'historique anonyme, c'est la consolidation : a la fin
-- du mois, les marqueurs et le sel sont detruits et il ne reste qu'un
-- entier. Sans le sel, l'empreinte n'est plus rattachable a personne,
-- meme en connaissant l'identifiant du parent.
-- =====================================================================

-- pgcrypto fournit gen_random_bytes et digest. Sur Supabase il est
-- installe dans le schema "extensions", pas dans "public" : les appels
-- ci-dessous sont donc qualifies, sinon ils ne se resolvent pas depuis
-- une fonction dont le search_path vaut "public".
create extension if not exists pgcrypto with schema extensions;

-- Un sel par mois, jamais lu par personne d'autre que la fonction
-- ci-dessous. Aucune policy : les roles anon et authenticated n'y ont
-- donc aucun acces.
create table if not exists public.sels_usage (
  mois date primary key,
  sel text not null default encode(extensions.gen_random_bytes(32), 'hex'),
  cree_le timestamptz not null default now()
);

alter table public.sels_usage enable row level security;

-- Une empreinte par (mois, fonctionnalite, famille). Pas de date, pas
-- d'heure, pas d'identifiant d'enfant, pas de compteur d'usages : la
-- seule chose qu'on peut en tirer est un decompte de distincts.
create table if not exists public.marqueurs_usage (
  mois date not null,
  fonctionnalite text not null,
  empreinte text not null,
  primary key (mois, fonctionnalite, empreinte)
);

alter table public.marqueurs_usage enable row level security;

-- Le resultat consolide. C'est tout ce qui reste apres la fin du mois.
create table if not exists public.compteurs_usage (
  mois date not null,
  fonctionnalite text not null,
  nombre_familles integer not null,
  consolide_le timestamptz not null default now(),
  primary key (mois, fonctionnalite)
);

alter table public.compteurs_usage enable row level security;

-- Appelee par l'application a chaque usage d'une fonctionnalite.
--
-- Le client ne transmet que le nom de la fonctionnalite : l'identite
-- vient de auth.uid(), donc un parent ne peut marquer que lui-meme, et
-- ne voit jamais le sel.
create or replace function public.enregistrer_usage(
  p_fonctionnalite text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mois date := date_trunc('month', now())::date;
  v_sel text;
begin
  if auth.uid() is null then
    return;
  end if;

  -- Liste fermee : une faute de frappe cote application ne doit pas
  -- creer une fonctionnalite fantome dans les statistiques.
  if p_fonctionnalite not in (
    'activite_preparee',
    'fiche_secours_generee',
    'mode_urgence_ouvert',
    'lien_partage_cree'
  ) then
    return;
  end if;

  insert into public.sels_usage (mois)
  values (v_mois)
  on conflict (mois) do nothing;

  select sel into v_sel from public.sels_usage where mois = v_mois;

  insert into public.marqueurs_usage (mois, fonctionnalite, empreinte)
  values (
    v_mois,
    p_fonctionnalite,
    encode(
      extensions.digest(auth.uid()::text || ':' || v_sel, 'sha256'),
      'hex'
    )
  )
  on conflict do nothing;
end;
$$;

grant execute on function public.enregistrer_usage(text) to authenticated;

-- Consolidation : le 1er de chaque mois, le mois ecoule devient un
-- entier et tout le reste disparait.
create or replace function public.consolider_compteurs_usage()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mois date := (date_trunc('month', now()) - interval '1 month')::date;
begin
  insert into public.compteurs_usage (mois, fonctionnalite, nombre_familles)
  select mois, fonctionnalite, count(*)
  from public.marqueurs_usage
  where mois = v_mois
  group by mois, fonctionnalite
  on conflict (mois, fonctionnalite) do update
    set nombre_familles = excluded.nombre_familles,
        consolide_le = now();

  -- Sans le sel, les empreintes restantes ne seraient de toute facon
  -- plus rattachables. On les supprime quand meme : garder une donnee
  -- dont on n'a plus l'usage n'a pas de justification.
  delete from public.marqueurs_usage where mois = v_mois;
  delete from public.sels_usage where mois = v_mois;
end;
$$;

select cron.unschedule('consolider-compteurs-usage')
where exists (
  select 1 from cron.job where jobname = 'consolider-compteurs-usage'
);

select cron.schedule(
  'consolider-compteurs-usage',
  '30 4 1 * *',
  $$ select public.consolider_compteurs_usage(); $$
);


-- =====================================================================
-- Verifications apres execution
-- =====================================================================
--
--   -- les colonnes ajoutees
--   select column_name from information_schema.columns
--   where table_name = 'comptes_parents'
--     and column_name in ('email_secours', 'suppression_demandee_le',
--                         'suppression_effective_le');
--
--   -- les trois taches automatiques
--   select jobid, jobname, schedule, active from cron.job;
--
--   -- le mois en cours (aucune ligne tant que personne n'a rien fait)
--   select mois, fonctionnalite, count(*)
--   from public.marqueurs_usage group by 1, 2;
--
--   -- l'historique anonyme
--   select * from public.compteurs_usage order by mois desc;
