-- =======================================================================
-- Refonte des liens de partage — 27/08/2026
-- =======================================================================
--
-- Ce que ce script change, et pourquoi.
--
-- Le plafond de 7 jours et l'impossibilité de prolonger dataient du
-- 25/08/2026. Ils partaient d'un bon principe — un lien de partage est
-- un jeton porteur, donc plus il vit, moins le parent le maîtrise —
-- mais la réponse était mauvaise. Le rattachement à un établissement
-- propose déjà un calendrier libre, parce que le professionnel y est
-- identifié.
--
-- La règle retenue : **accès anonyme = risque à compenser, pas durée à
-- plafonner.** La compensation, c'est le verrouillage à la première
-- ouverture ; la durée redevient libre.
--
-- =======================================================================
-- 1. Les colonnes
-- =======================================================================

alter table public.partages
  add column if not exists nom_destinataire   text,
  add column if not exists revoque_le         timestamptz,
  add column if not exists verrou_empreinte   text,
  add column if not exists verrou_pose_le     timestamptz,
  add column if not exists permanent          boolean not null default false,
  add column if not exists dernier_rappel_le  timestamptz;

comment on column public.partages.nom_destinataire is
  'Saisi librement par le parent : « Aurelie, animatrice piscine ». '
  'Distinct de la colonne destinataire, qui porte le choix '
  'particulier / structure_accueil et gouverne la mention accolee aux '
  'traitements.';

comment on column public.partages.revoque_le is
  'Revocation par marquage et non par suppression : le parent garde '
  'l''historique de ce qu''il a partage, et la preuve que la '
  'revocation a eu lieu.';

comment on column public.partages.verrou_empreinte is
  'Hachage SHA-256 d''un secret aleatoire que NOUS fabriquons a la '
  'premiere ouverture et deposons dans le navigateur. Jamais le secret '
  'lui-meme. Ce n''est pas une empreinte de navigateur : aucune donnee '
  'n''est lue sur l''appareil.';

comment on column public.partages.permanent is
  'Lien sans date de fin. Le parent en est rappele tous les 6 mois.';

comment on column public.partages.dernier_rappel_le is
  'Dernier rappel semestriel envoye pour un lien permanent.';

-- La contrainte qui tient tout le reste.
--
-- `date_expiration` etait NOT NULL. « Permanent » veut dire « pas de
-- date » : plutot qu'une date lointaine posee en douce — un 31/12/2099
-- que personne ne saurait relire dans deux ans — le lien a soit une
-- date, soit le statut permanent. Jamais les deux, jamais aucun.

alter table public.partages
  alter column date_expiration drop not null;

alter table public.partages
  drop constraint if exists partage_a_une_fin_ou_est_permanent;

alter table public.partages
  add constraint partage_a_une_fin_ou_est_permanent check (
    (permanent = true  and date_expiration is null)
    or
    (permanent = false and date_expiration is not null)
  );

-- =======================================================================
-- 2. Les tentatives refusées
-- =======================================================================
--
-- Une ouverture depuis un appareil autre que celui qui a pris le
-- verrou. Remontee au parent, qui peut alors autoriser le nouvel
-- appareil en un geste.
--
-- **Aucune adresse IP, aucun en-tete de requete, aucune empreinte de
-- navigateur.** Meme regle que le journal des ouvertures : on
-- enregistre qu'une tentative a eu lieu, jamais qui l'a faite.
--
-- `toleree` porte la fenetre de 15 minutes. Pendant ce delai, le
-- second appareil prend le verrou au lieu d'etre refuse — cela absorbe
-- le cas tres courant du navigateur integre d'un client mail suivi de
-- « ouvrir dans Chrome ». Mais la ligne est ecrite quand meme et
-- remontee au parent : sans elle, la fenetre serait un trou de quinze
-- minutes invisible.

create table if not exists public.tentatives_partage_refusees (
  id         uuid primary key default gen_random_uuid(),
  partage_id uuid not null
    references public.partages (id) on delete cascade,
  tentee_le  timestamptz not null default now(),
  toleree    boolean not null default false
);

create index if not exists tentatives_partage_refusees_partage_idx
  on public.tentatives_partage_refusees (partage_id, tentee_le desc);

alter table public.tentatives_partage_refusees enable row level security;

-- Lecture par le parent de l'enfant concerne. Aucune policy d'ecriture :
-- seule la cle de service ecrit ici, hors RLS, puisque celui qui tente
-- d'ouvrir n'est pas authentifie — c'est aussi ce qui garantit que
-- personne ne peut fabriquer une fausse tentative.
drop policy if exists "tentatives_lisibles_par_le_parent"
  on public.tentatives_partage_refusees;

create policy "tentatives_lisibles_par_le_parent"
  on public.tentatives_partage_refusees
  for select
  using (
    exists (
      select 1 from public.partages p
      where p.id = partage_id
        and public.enfant_du_parent(p.enfant_id)
    )
  );

-- =======================================================================
-- 3. La purge, reprise
-- =======================================================================
--
-- L'ancienne tache faisait :
--   delete from public.partages where date_expiration < now() - '24 hours'
--
-- Elle detruisait precisement l'historique que la revocation par
-- marquage vise a conserver. Elle est remplacee par une purge a
-- **12 mois**, alignee sur celle du journal de consultation.
--
-- Deux choses a savoir :
--   - un lien permanent n'est jamais purge tant qu'il n'est pas
--     revoque : c'est ce que « permanent » veut dire ;
--   - le `coalesce` fait courir les 12 mois depuis la revocation
--     quand elle a eu lieu, sinon depuis l'expiration.
--
-- La suppression d'un compte n'a pas besoin de cette tache : verifie le
-- 27/08/2026, auth.users -> enfants -> partages est en CASCADE de bout
-- en bout, et tentatives_partage_refusees suit partages.

select cron.unschedule('supprimer-partages-expires')
where exists (
  select 1 from cron.job where jobname = 'supprimer-partages-expires'
);

select cron.unschedule('purger-partages-termines')
where exists (
  select 1 from cron.job where jobname = 'purger-partages-termines'
);

select cron.schedule(
  'purger-partages-termines',
  '0 3 * * *',
  $$
    delete from public.partages
    where permanent = false
      and coalesce(revoque_le, date_expiration) < now() - interval '12 months';
  $$
);

-- =======================================================================
-- 4. Le rappel semestriel des liens permanents
-- =======================================================================
--
-- La tache ne fait que **preparer les lignes**, en SQL pur. Une Edge
-- Function les lit et envoie le mail, appelee par le planificateur de
-- Supabase — hors base.
--
-- Choix du 27/08/2026, contre `pg_net` : aucune extension a installer,
-- aucune cle rangee en base. C'est ce qui pese le moins sur le dossier
-- d'hebergement de donnees de sante.
--
-- Le canal push n'est pas branche. Les colonnes statut_push /
-- push_envoye_le d'evenements_notification_parent restent a null,
-- pretes pour le chantier des notifications sur ecran verrouille.

-- `type_evenement` est contraint a une liste fermee. Sans cette
-- reprise, l'insertion echouerait — verifie le 27/08/2026 avant
-- d'appliquer le script.
alter table public.evenements_notification_parent
  drop constraint if exists evenements_notification_parent_type_evenement_check;

alter table public.evenements_notification_parent
  add constraint evenements_notification_parent_type_evenement_check
  check (type_evenement = any (array[
    'note_ajoutee',
    'expiration_rattachement_7_jours',
    'rappel_mise_a_jour_profil',
    'rappel_partages_permanents'
  ]));

create or replace function public.preparer_rappels_partages_permanents()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lignes integer;
begin
  -- Une seule instruction : un CTE ne survit pas a l'instruction
  -- suivante. Marquer `dernier_rappel_le` dans un `update` separe
  -- aurait echoue sur « relation a_rappeler does not exist ».
  --
  -- Les deux CTE ecrivains voient le meme instantane, et sont
  -- independants l'un de l'autre : l'ordre de leurs effets n'a pas
  -- d'importance ici.
  with a_rappeler as (
    select p.id, p.enfant_id, e.parent_id
    from public.partages p
    join public.enfants e on e.id = p.enfant_id
    where p.permanent = true
      and p.revoque_le is null
      and e.parent_id is not null
      and coalesce(p.dernier_rappel_le, p.date_creation)
          < now() - interval '6 months'
  ),
  marques as (
    update public.partages
    set dernier_rappel_le = now()
    where id in (select id from a_rappeler)
    returning id
  ),
  evenements as (
    insert into public.evenements_notification_parent
      (parent_id, enfant_id, type_evenement, donnees)
    select
      a.parent_id,
      a.enfant_id,
      'rappel_partages_permanents',
      jsonb_build_object('partageId', a.id)
    from a_rappeler a
    returning 1
  )
  select count(*)::integer into v_lignes from evenements;

  return v_lignes;
end;
$$;

comment on function public.preparer_rappels_partages_permanents() is
  'Prepare les rappels semestriels des liens permanents. N''envoie '
  'rien : une Edge Function lit evenements_notification_parent et '
  'envoie. Le rappel informe, il n''annule jamais un partage.';

select cron.unschedule('preparer-rappels-partages')
where exists (
  select 1 from cron.job where jobname = 'preparer-rappels-partages'
);

select cron.schedule(
  'preparer-rappels-partages',
  '0 5 * * *',
  $$ select public.preparer_rappels_partages_permanents(); $$
);

-- =======================================================================
-- 5. Le nom du destinataire devient obligatoire — 27/08/2026
-- =======================================================================
--
-- Decision de Fanny, apres coup : le champ ne doit pas etre facultatif.
--
-- Sans nom, la liste des partages devient une suite de lignes
-- indistinctes — « Informations pour les secours », trois fois — et un
-- parent qui ne sait plus a quoi correspond un lien ne le revoquera
-- jamais. Le nom sert exactement a ca.
--
-- La contrainte est posee en base et pas seulement a l'ecran : c'est le
-- seul endroit qui tienne si un jour une autre voie d'ecriture
-- apparait.
--
-- `trim` dans la contrainte : un nom fait uniquement d'espaces passe
-- `not null` sans rien nommer.
--
-- Applicable sans precaution : la table etait **vide** au moment de
-- l'appliquer — verifie le 27/08/2026, zero ligne. Les liens creees
-- pendant les audits avaient deja ete nettoyes.

alter table public.partages
  alter column nom_destinataire set not null;

alter table public.partages
  drop constraint if exists nom_destinataire_non_vide;

alter table public.partages
  add constraint nom_destinataire_non_vide
  check (length(trim(nom_destinataire)) > 0);
