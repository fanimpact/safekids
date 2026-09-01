-- =======================================================================
-- Trois appareils, et une demande au parent au-delà — 01/09/2026
-- =======================================================================
--
-- CE QUI NE MARCHAIT PAS
--
-- Le parent choisissait 1, 2 ou 5 « personnes » à la création d'un
-- partage. Or le mécanisme ne compte pas des personnes : il compte des
-- **navigateurs**. Un seul téléphone en fournit déjà deux — la fenêtre
-- intégrée du lecteur de QR, puis Safari ou Chrome quand la personne
-- rouvre plus tard.
--
-- Une maîtresse avec son téléphone, sa tablette et son ordinateur
-- atteignait donc quatre à six places sans avoir rien fait d'anormal.
--
-- L'écart avait été constaté dès le 27/08 et documenté au lieu d'être
-- corrigé. Il l'est ici.
--
-- CE QUI EST DÉCIDÉ (Fanny, 01/09/2026)
--
--   - **trois places pour tout partage ordinaire**, sans réglage ;
--   - une place n'est comptée qu'au **retour** du navigateur, à sa
--     deuxième visite : la fenêtre du lecteur de QR ne consomme rien ;
--   - au quatrième appareil, la personne est **arrêtée** et le parent
--     reçoit une demande à autoriser. Un appareil à la fois : le
--     cinquième redemandera ;
--   - l'accès secours et le Mode Urgence ne bloquent **jamais**, quel
--     que soit le nombre. On ne bloque pas ce qui peut sauver
--     l'enfant, on bloque ce qui peut attendre.

-- =======================================================================
-- 1. Une place ne compte qu'au retour du navigateur
-- =======================================================================
--
-- Le secret du verrou vit dans le stockage local du navigateur qui a
-- ouvert la fiche, et ce cloisonnement n'est pas le notre : c'est celui
-- du systeme. Un lecteur de QR ouvre souvent la page dans sa propre
-- fenetre integree, qu'on referme et qu'on ne rouvre jamais.
--
-- On ne peut pas **deviner** si un navigateur va rester : aucune
-- detection n'est fiable, et Apple rend volontairement ses fenetres
-- integrees indiscernables de Safari. On attend donc de voir s'il
-- revient.
--
-- Premiere visite : la place est creee, elle ne compte pas.
-- Deuxieme visite du meme navigateur : elle est confirmee, elle compte.

alter table public.appareils_partage
  add column if not exists confirme boolean not null default false;

comment on column public.appareils_partage.confirme is
  'Le navigateur est revenu une seconde fois : cette place compte '
  'dans le plafond. Une premiere visite ne compte pas — la fenetre '
  'integree d''un lecteur de QR ne revient jamais.';

-- Les places deja posees appartiennent a des navigateurs qui ont
-- vraiment consulte la fiche. Les laisser non confirmees relacherait
-- le plafond sur tous les partages en cours.
update public.appareils_partage set confirme = true where not confirme;

-- =======================================================================
-- 2. Trois places, pour tout le monde
-- =======================================================================
--
-- Le plafond monte d'une unite a chaque appareil que le parent
-- autorise : la contrainte accepte donc tout nombre a partir de trois,
-- et non plus une liste fermee.
--
-- Cinquante reste la borne technique, la meme que pour l'acces
-- secours : au-dela, ce n'est plus un partage.

alter table public.partages
  alter column appareils_max set default 3;

-- L'ancienne contrainte d'abord : elle n'accepte que 1, 2 ou 5, et
-- refuserait la mise a jour ci-dessous. Erreur commise a la premiere
-- execution du 01/09/2026 — l'ordre compte.
alter table public.partages
  drop constraint if exists appareils_max_propose;

-- Les onze partages existants portent tous 1. Le plafond ne retire
-- jamais une place deja prise : personne ne perd son acces, on ouvre
-- seulement ce qui etait ferme.
update public.partages
set appareils_max = 3
where not declenche_en_secours and appareils_max < 3;

alter table public.partages
  add constraint appareils_max_propose check (
    (declenche_en_secours = false
      and appareils_max >= 3 and appareils_max <= 50)
    or
    (declenche_en_secours = true
      and appareils_max >= 1 and appareils_max <= 50)
  );

-- =======================================================================
-- 3. La reprise explicite disparaît
-- =======================================================================
--
-- Construite le 28/08, retiree le 01/09. Elle repondait au meme
-- probleme — le navigateur integre qui verrouille dehors une personne
-- legitime — mais le comptage au retour le regle sans rien demander a
-- personne.
--
-- La garder dirait le contraire de la nouvelle regle sur le meme
-- ecran : « reprenez l'acces vous-meme » d'un cote, « demandez au
-- parent » de l'autre.

alter table public.tentatives_partage_refusees
  drop column if exists reprise;

alter table public.evenements_notification_parent
  drop constraint if exists
    evenements_notification_parent_type_evenement_check;

alter table public.evenements_notification_parent
  add constraint evenements_notification_parent_type_evenement_check
  check (
    type_evenement = any (array[
      'note_ajoutee',
      'expiration_rattachement_7_jours',
      'rappel_mise_a_jour_profil',
      'rappel_partages_permanents',
      'acces_secours_declenche',
      -- Remplace 'acces_repris', retire le meme jour.
      'demande_acces_partage'
    ])
  );

-- =======================================================================
-- 4. Les demandes d'accès
-- =======================================================================
--
-- Un quatrieme appareil est arrete. La personne dit qui elle est, en
-- soixante caracteres, et le parent decide.
--
-- **La raison ne sort jamais de l'application.** Le mail annonce
-- seulement qu'une demande attend : quelqu'un pourrait ecrire
-- n'importe quoi dans ce champ, et la regle permanente interdit toute
-- donnee de sante ou nom de famille dans un email.

create table if not exists public.demandes_acces_partage (
  id uuid primary key default gen_random_uuid(),

  partage_id uuid not null
    references public.partages (id) on delete cascade,

  -- Le hache du secret du navigateur bloque, jamais le secret. Une
  -- fuite de la table ne donnerait a personne de quoi ouvrir un lien.
  --
  -- Aucune adresse IP, aucun en-tete, aucune empreinte de navigateur :
  -- meme regle que le journal des tentatives.
  empreinte text not null,

  raison text not null,

  cree_le timestamptz not null default now(),

  -- Nulle tant que le parent n'a pas repondu. **Le silence ne vaut
  -- jamais accord** : une demande sans reponse s'efface au bout de
  -- trente jours sans rien autoriser.
  autorisee_le timestamptz,

  unique (partage_id, empreinte)
);

alter table public.demandes_acces_partage
  drop constraint if exists raison_courte;

alter table public.demandes_acces_partage
  add constraint raison_courte check (
    length(btrim(raison)) between 1 and 60
  );

comment on table public.demandes_acces_partage is
  'Un quatrieme appareil demande a ouvrir un partage. Trois demandes '
  'en attente au maximum par partage ; une demande sans reponse '
  's''efface au bout de 30 jours, sans valoir accord.';

create index if not exists demandes_acces_partage_en_attente
  on public.demandes_acces_partage (partage_id)
  where autorisee_le is null;

alter table public.demandes_acces_partage enable row level security;

drop policy if exists demandes_lisibles_par_le_parent
  on public.demandes_acces_partage;

-- Lecture seule : la demande est ecrite par la fonction serveur, et
-- l'autorisation passe par une fonction dediee. Le parent ne peut ni
-- fabriquer une demande, ni la modifier a la main.
create policy demandes_lisibles_par_le_parent
  on public.demandes_acces_partage
  for select
  using (
    exists (
      select 1 from public.partages p
      where p.id = demandes_acces_partage.partage_id
        and public.enfant_du_parent(p.enfant_id)
    )
  );

-- =======================================================================
-- 5. Le parent autorise un appareil
-- =======================================================================
--
-- Un seul geste, un seul appareil. Pas de « ne plus me demander » :
-- l'application ne sait pas distinguer les appareils d'une personne de
-- ceux de plusieurs, et cette option ouvrirait exactement la porte
-- qu'on cherche a fermer.

create or replace function public.autoriser_appareil_partage(
  p_demande_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partage uuid;
  v_enfant uuid;
  v_nouveau integer;
begin
  select d.partage_id, p.enfant_id into v_partage, v_enfant
  from public.demandes_acces_partage d
  join public.partages p on p.id = d.partage_id
  where d.id = p_demande_id;

  if v_partage is null then
    raise exception 'Demande introuvable.';
  end if;

  if not public.enfant_du_parent(v_enfant) then
    raise exception 'Cette demande ne vous concerne pas.';
  end if;

  update public.demandes_acces_partage
  set autorisee_le = now()
  where id = p_demande_id and autorisee_le is null;

  -- Une place de plus, pour cet appareil-la. Le cinquieme redemandera.
  update public.partages
  set appareils_max = least(appareils_max + 1, 50)
  where id = v_partage
  returning appareils_max into v_nouveau;

  return v_nouveau;
end;
$$;

revoke all on function public.autoriser_appareil_partage(uuid) from public;
revoke all on function public.autoriser_appareil_partage(uuid) from anon;
grant execute on function public.autoriser_appareil_partage(uuid)
  to authenticated;

-- =======================================================================
-- 6. Le ménage des demandes sans réponse
-- =======================================================================
--
-- Trente jours, puis effacement — regle de Fanny du 25/08/2026. Le
-- silence du parent ne vaut ni refus ni acceptation : la demande
-- disparait simplement, et la personne peut redemander.
--
-- Appelee par le passage horaire d'OVH, celui qui envoie deja les
-- notifications en attente. Une tache planifiee de plus n'apporterait
-- rien.

create or replace function public.purger_demandes_acces_partage()
returns integer
language sql
security definer
set search_path = public
as $$
  with parties as (
    delete from public.demandes_acces_partage
    where autorisee_le is null
      and cree_le < now() - interval '30 days'
    returning 1
  )
  select count(*)::integer from parties;
$$;

revoke all on function public.purger_demandes_acces_partage() from public;
revoke all on function public.purger_demandes_acces_partage() from anon;
revoke all on function public.purger_demandes_acces_partage()
  from authenticated;

-- Appelee par la fonction serveur `envoyer-notifications-parent`, qui
-- passe deja toutes les heures. Le role de service est le seul a
-- pouvoir la declencher : ce n'est pas un geste d'utilisateur.
grant execute on function public.purger_demandes_acces_partage()
  to service_role;
