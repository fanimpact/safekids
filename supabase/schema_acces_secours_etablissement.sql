-- =======================================================================
-- L'accès secours depuis un rattachement d'établissement — 28/08/2026
-- =======================================================================
--
-- Le trou que ce script bouche.
--
-- L'accès secours ne se déclenchait que depuis la page publique d'un
-- lien de partage. Or **c'est le rattachement qui est le cas normal**
-- dans une école : le professionnel passe par l'application, et ne
-- voyait jamais le bouton.
--
-- Autrement dit, le mécanisme ne fonctionnait pas dans le scénario qui
-- l'a motivé : l'enfant part avec les pompiers, quelqu'un de l'école
-- l'accompagne, et cette personne ne pouvait rien transmettre.
--
-- =======================================================================
-- Ce qui change, et ce qui ne change pas
-- =======================================================================
--
-- Un accès secours reste **une ligne `partages` dérivée**. Elle hérite
-- ainsi de tout ce qui existe déjà : les places et le verrou, la
-- révocation par marquage, l'horloge indépendante de 24 heures, le
-- journal des ouvertures, la présence dans la liste du parent.
--
-- Seule son origine change : un rattachement au lieu d'un partage.
--
-- Les décisions de Fanny du 28/08/2026, toutes portées ici :
--
--   - la préautorisation du parent vaut pour **tous les canaux** : il a
--     répondu une fois par enfant, on ne lui redemande rien ;
--   - **tout membre actif** peut déclencher, pas seulement un
--     directeur. On ne sait pas d'avance qui montera dans le camion, et
--     réserver le bouton à un rôle recréerait le problème ;
--   - **un seul accès à la fois** : si un est déjà ouvert et valide
--     pour cet enfant, un nouveau déclenchement le retrouve. Une seule
--     notification, une seule ligne dans la liste du parent ;
--   - le parent voit **la fonction et l'établissement**, jamais le nom
--     de la personne : « ouvert par une ATSEM de l'École les Tilleuls ».
--     Il doit comprendre ce qui s'est passé, pas surveiller
--     nominativement le personnel.

-- =======================================================================
-- 1. L'origine, et qui a déclenché
-- =======================================================================

alter table public.partages
  add column if not exists rattachement_origine_id uuid
    references public.enfants_etablissements (id) on delete cascade,
  add column if not exists declenche_par_fonction text;

comment on column public.partages.rattachement_origine_id is
  'Le rattachement dont cet acces secours derive. Exclusif de '
  'partage_origine_id : un acces vient d''un lien ou d''un '
  'rattachement, jamais des deux.';

comment on column public.partages.declenche_par_fonction is
  'La fonction declaree de la personne qui a declenche — « ATSEM », '
  '« Direction ». Jamais son nom ni son adresse. Nulle depuis un lien '
  'de partage, ou celui qui ouvre est anonyme : on n''invente rien.';

-- Exactement une origine, et toujours une date de déclenchement.
alter table public.partages
  drop constraint if exists secours_porte_sa_filiation;

alter table public.partages
  add constraint secours_porte_sa_filiation check (
    declenche_en_secours = false
    or (
      declenche_le is not null
      and (
        (partage_origine_id is not null
          and rattachement_origine_id is null)
        or
        (partage_origine_id is null
          and rattachement_origine_id is not null)
      )
    )
  );

-- =======================================================================
-- 2. L'accès secours déjà ouvert, s'il y en a un
-- =======================================================================
--
-- Deux personnes peuvent appuyer en meme temps — la maitresse et la
-- directrice. Deux acces, deux notifications et deux lignes dans la
-- liste du parent seraient du bruit au pire moment.

create or replace function public.acces_secours_en_cours(
  p_enfant_id uuid,
  p_maintenant timestamptz default now()
)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select p.id
  from public.partages p
  where p.enfant_id = p_enfant_id
    and p.declenche_en_secours
    and p.revoque_le is null
    and p.date_expiration > p_maintenant
  order by p.declenche_le desc
  limit 1;
$$;

-- =======================================================================
-- 3. Le déclenchement depuis un rattachement
-- =======================================================================
--
-- Appelee par l'application, donc par quelqu'un d'**authentifie** :
-- pas besoin de fonction serveur ici, contrairement au lien de partage
-- ou l'ouvreur est anonyme. Un deploiement de moins.
--
-- `security definer` parce qu'elle ecrit une ligne `partages` sur un
-- enfant qui n'appartient pas a l'appelant. Les trois controles
-- ci-dessous sont donc le seul rempart.

create or replace function public.declencher_acces_secours_etablissement(
  p_enfant_id uuid,
  p_etablissement_id uuid,
  p_maintenant timestamptz default now()
)
returns table (
  secours_id uuid,
  secours_token text,
  secours_expire_le timestamptz,
  secours_cree boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rattachement public.enfants_etablissements%rowtype;
  v_autorise boolean;
  v_fonction text;
  v_parent uuid;
  v_deja uuid;
  v_expire timestamptz;
  v_id uuid;
  v_token text;
begin
  -- 1. L'appelant est membre actif de cet etablissement.
  if not public.est_membre_actif(p_etablissement_id) then
    raise exception 'Vous n''etes pas membre actif de cet etablissement.';
  end if;

  -- 2. L'enfant y est rattache, et le rattachement est vivant.
  select * into v_rattachement
  from public.enfants_etablissements ee
  where ee.enfant_id = p_enfant_id
    and ee.etablissement_id = p_etablissement_id
    and ee.statut = 'actif'
    and ee.revoque_le is null
    and ee.date_expiration > p_maintenant
  order by ee.date_creation desc
  limit 1;

  if v_rattachement.id is null then
    raise exception 'Cet enfant n''est pas rattache a votre etablissement.';
  end if;

  -- 3. Le parent a preautorise. Sa reponse vaut pour tous les canaux.
  select e.acces_secours_autorise, e.parent_id
  into v_autorise, v_parent
  from public.enfants e
  where e.id = p_enfant_id;

  if not coalesce(v_autorise, false) then
    raise exception 'L''acces secours n''a pas ete autorise par le parent.';
  end if;

  -- Un seul acces a la fois, quel que soit le canal qui l'a ouvert.
  v_deja := public.acces_secours_en_cours(p_enfant_id, p_maintenant);

  if v_deja is not null then
    return query
    select p.id, p.token, p.date_expiration, false
    from public.partages p
    where p.id = v_deja;

    return;
  end if;

  -- La fonction declaree, figee au moment du declenchement : le parent
  -- lit « ouvert par une ATSEM », pas le nom de la personne.
  select m.fonction into v_fonction
  from public.membres_etablissement m
  where m.etablissement_id = p_etablissement_id
    and m.user_id = auth.uid()
    and m.statut = 'actif'
  limit 1;

  v_expire := p_maintenant + interval '24 hours';

  insert into public.partages (
    enfant_id,
    type_fiche,
    destinataire,
    nom_destinataire,
    date_expiration,
    permanent,
    appareils_max,
    declenche_en_secours,
    rattachement_origine_id,
    declenche_le,
    declenche_par_fonction
  )
  values (
    p_enfant_id,
    -- La fiche secours, et rien d'autre.
    'secours',
    -- Un etablissement EST une structure d'accueil : c'est ce qui
    -- gouverne la mention accolee aux traitements.
    'structure_accueil',
    'Accès secours',
    v_expire,
    false,
    10,
    true,
    v_rattachement.id,
    p_maintenant,
    v_fonction
  )
  returning id, token into v_id, v_token;

  -- Le parent est prevenu, jamais consulte. Dans la meme transaction :
  -- un acces ouvert sans notification serait le pire des deux mondes.
  if v_parent is not null then
    insert into public.evenements_notification_parent
      (parent_id, enfant_id, type_evenement, donnees)
    values (
      v_parent,
      p_enfant_id,
      'acces_secours_declenche',
      jsonb_build_object('partageId', v_id)
    );
  end if;

  return query select v_id, v_token, v_expire, true;
end;
$$;

revoke all on function
  public.declencher_acces_secours_etablissement(uuid, uuid, timestamptz)
  from public;
revoke all on function
  public.declencher_acces_secours_etablissement(uuid, uuid, timestamptz)
  from anon;
grant execute on function
  public.declencher_acces_secours_etablissement(uuid, uuid, timestamptz)
  to authenticated;

-- =======================================================================
-- 4. Le déclenchement depuis un lien retrouve lui aussi l'existant
-- =======================================================================
--
-- Meme regle, meme raison. Le drapeau `secours_cree` dit a l'appelant
-- s'il doit notifier le parent : sur une reprise, non.

-- On la supprime d'abord : sa colonne de sortie change, et
-- `create or replace` ne sait pas changer un type de retour.
drop function if exists
  public.declencher_acces_secours(uuid, timestamptz);

create or replace function public.declencher_acces_secours(
  p_partage_id uuid,
  p_maintenant timestamptz default now()
)
returns table (
  secours_id uuid,
  secours_token text,
  secours_expire_le timestamptz,
  secours_cree boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_origine public.partages%rowtype;
  v_autorise boolean;
  v_deja uuid;
  v_expire timestamptz;
begin
  select * into v_origine
  from public.partages p
  where p.id = p_partage_id;

  if v_origine.id is null then
    raise exception 'Partage introuvable.';
  end if;

  select e.acces_secours_autorise into v_autorise
  from public.enfants e
  where e.id = v_origine.enfant_id;

  if not coalesce(v_autorise, false) then
    raise exception 'L''acces secours n''a pas ete autorise par le parent.';
  end if;

  if v_origine.declenche_en_secours then
    raise exception 'Un acces secours n''en declenche pas un autre.';
  end if;

  if v_origine.revoque_le is not null then
    raise exception 'Ce partage a ete revoque.';
  end if;

  if not v_origine.permanent
     and v_origine.date_expiration < p_maintenant then
    raise exception 'Ce partage a expire.';
  end if;

  v_deja := public.acces_secours_en_cours(
    v_origine.enfant_id,
    p_maintenant
  );

  if v_deja is not null then
    return query
    select p.id, p.token, p.date_expiration, false
    from public.partages p
    where p.id = v_deja;

    return;
  end if;

  v_expire := p_maintenant + interval '24 hours';

  return query
  insert into public.partages (
    enfant_id,
    type_fiche,
    destinataire,
    nom_destinataire,
    date_expiration,
    permanent,
    appareils_max,
    declenche_en_secours,
    partage_origine_id,
    declenche_le
  )
  values (
    v_origine.enfant_id,
    'secours',
    v_origine.destinataire,
    'Accès secours',
    v_expire,
    false,
    10,
    true,
    v_origine.id,
    p_maintenant
  )
  returning id, token, date_expiration, true;
end;
$$;

revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from public;
revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from anon;
revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from authenticated;

-- =======================================================================
-- 5. Étendre le plafond d'appareils, depuis l'application
-- =======================================================================
--
-- Le detenteur peut ajouter des places sans passer par le parent : une
-- intervention mobilise des gens successifs, et un soignant refuse
-- parce qu'un compteur est plein serait le pire mode d'echec possible.

create or replace function public.etendre_appareils_acces_secours(
  p_partage_id uuid,
  p_etablissement_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partage public.partages%rowtype;
  v_nouveau integer;
begin
  if not public.est_membre_actif(p_etablissement_id) then
    raise exception 'Vous n''etes pas membre actif de cet etablissement.';
  end if;

  select * into v_partage
  from public.partages p
  where p.id = p_partage_id and p.declenche_en_secours;

  if v_partage.id is null then
    raise exception 'Acces secours introuvable.';
  end if;

  if not public.enfant_visible_par_etablissement(v_partage.enfant_id) then
    raise exception 'Cet enfant n''est pas rattache a votre etablissement.';
  end if;

  -- Cinquante est la borne de la contrainte : au-dela, ce n'est plus
  -- une intervention, c'est une fuite.
  v_nouveau := least(v_partage.appareils_max + 5, 50);

  update public.partages
  set appareils_max = v_nouveau
  where id = p_partage_id;

  return v_nouveau;
end;
$$;

revoke all on function
  public.etendre_appareils_acces_secours(uuid, uuid) from public;
revoke all on function
  public.etendre_appareils_acces_secours(uuid, uuid) from anon;
grant execute on function
  public.etendre_appareils_acces_secours(uuid, uuid) to authenticated;

-- =======================================================================
-- 6. Relire un accès secours déjà ouvert
-- =======================================================================
--
-- Le professionnel doit pouvoir remontrer le QR tant que l'acces est
-- valide : un soignant arrive apres les autres, un telephone s'eteint.
-- Sans cette lecture, la seule facon de retrouver le code serait de
-- rappeler la fonction de declenchement — qui en creerait un si aucun
-- n'existait, et notifierait le parent pour rien.

create or replace function public.acces_secours_etablissement(
  p_enfant_id uuid,
  p_etablissement_id uuid,
  p_maintenant timestamptz default now()
)
returns table (
  secours_id uuid,
  secours_token text,
  secours_expire_le timestamptz,
  secours_appareils_max integer,
  secours_fonction text
)
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_deja uuid;
begin
  if not public.est_membre_actif(p_etablissement_id) then
    raise exception 'Vous n''etes pas membre actif de cet etablissement.';
  end if;

  if not public.enfant_visible_par_etablissement(p_enfant_id) then
    raise exception 'Cet enfant n''est pas rattache a votre etablissement.';
  end if;

  v_deja := public.acces_secours_en_cours(p_enfant_id, p_maintenant);

  if v_deja is null then
    return;
  end if;

  return query
  select p.id, p.token, p.date_expiration, p.appareils_max,
         p.declenche_par_fonction
  from public.partages p
  where p.id = v_deja;
end;
$$;

revoke all on function
  public.acces_secours_etablissement(uuid, uuid, timestamptz) from public;
revoke all on function
  public.acces_secours_etablissement(uuid, uuid, timestamptz) from anon;
grant execute on function
  public.acces_secours_etablissement(uuid, uuid, timestamptz)
  to authenticated;
