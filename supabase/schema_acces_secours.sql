-- =======================================================================
-- L'accès secours — 28/08/2026
-- =======================================================================
--
-- Le problème qu'il règle, en trois situations réelles.
--
-- 1. Théo fait une crise à l'école. Les pompiers arrivent. La maîtresse
--    a la fiche sur son téléphone et aucun moyen de la leur donner :
--    pas d'imprimante, pas le temps de taper une adresse. Elle lit à
--    voix haute, sous stress.
-- 2. Aux urgences, les informations ne se transmettent pas d'un
--    soignant à l'autre. Chaque médecin repose les mêmes questions. La
--    fiche doit pouvoir être remontrée à chaque nouvelle personne, pas
--    seulement au premier maillon.
-- 3. Celle qui bloquait tout : ce n'est pas la maîtresse qui
--    accompagne. Elle ne peut pas quitter sa classe, c'est l'ATSEM qui
--    monte dans l'ambulance — et elle n'a aucun accès. Le parent est
--    prévenu mais il conduit. La demande d'accès pour un tiers ne règle
--    pas ce cas, puisqu'elle attend une réponse.
--
-- =======================================================================
-- Ce que c'est, et ce que ce n'est pas
-- =======================================================================
--
-- Une **préautorisation donnée à froid** par le parent, à la création
-- du partage, jamais cochée d'avance. Elle ouvre au détenteur du lien
-- deux gestes en situation d'urgence, sans attendre de réponse :
-- montrer la fiche secours à un soignant, et transmettre l'accès à la
-- personne qui accompagne l'enfant.
--
-- Le parent est **notifié, pas consulté**. Il voit tout dans ses
-- partages et peut couper à tout moment.
--
-- Fondement : intérêt vital, article 6.1.d et 9.2.c du RGPD, renforcé
-- par la préautorisation explicite. Ce n'est pas un contournement du
-- consentement, c'est le cas que le règlement prévoit.
--
-- =======================================================================
-- Pourquoi un partage dérivé, et non un mode sur le partage existant
-- =======================================================================
--
-- L'activation crée **une nouvelle ligne `partages`**, rattachée à
-- celle d'origine. Tout le reste fonctionne alors sans une ligne de
-- code de plus : les places et le verrou, la révocation par marquage,
-- l'expiration, le journal des ouvertures, l'affichage dans la liste du
-- parent.
--
-- Et cela donne gratuitement ce qui compte le plus : **une horloge
-- indépendante**. L'accès secours tient ses 24 heures même si le
-- partage d'origine expire entre-temps — sinon le mécanisme lâcherait
-- précisément au mauvais moment.

-- =======================================================================
-- 1. La préautorisation, et le lien de filiation
-- =======================================================================

alter table public.partages
  add column if not exists acces_secours_autorise boolean not null
    default false,
  add column if not exists declenche_en_secours boolean not null
    default false,
  add column if not exists partage_origine_id uuid
    references public.partages (id) on delete cascade,
  add column if not exists declenche_le timestamptz;

comment on column public.partages.acces_secours_autorise is
  'Preautorisation donnee a froid par le parent, jamais cochee '
  'd''avance. Sans elle, aucun acces secours ne peut etre declenche.';

comment on column public.partages.declenche_en_secours is
  'Cette ligne EST un acces secours, derive d''un partage d''origine. '
  'Ne donne que la fiche secours, et 24 heures.';

comment on column public.partages.partage_origine_id is
  'Le partage dont celui-ci derive. Rend l''arbre lisible dans la '
  'liste du parent, et fait suivre la revocation de la souche.';

-- Un accès secours a jusqu'à dix appareils, extensibles par le
-- détenteur sans passer par le parent : une intervention mobilise des
-- gens successifs — pompiers, SMUR, accueil, urgentiste, pédiatre. Un
-- soignant refusé parce qu'un compteur est plein serait le pire mode
-- d'échec possible.
--
-- Les partages ordinaires restent à 1, 2 ou 5 : pas de saisie libre.
alter table public.partages
  drop constraint if exists appareils_max_propose;

alter table public.partages
  add constraint appareils_max_propose check (
    (declenche_en_secours = false and appareils_max in (1, 2, 5))
    or
    (declenche_en_secours = true and appareils_max between 1 and 50)
  );

-- Un accès secours porte toujours sa filiation et sa date de
-- déclenchement : sans elles, le parent ne saurait ni d'où il vient ni
-- quand son horloge a démarré.
alter table public.partages
  drop constraint if exists secours_porte_sa_filiation;

alter table public.partages
  add constraint secours_porte_sa_filiation check (
    declenche_en_secours = false
    or (partage_origine_id is not null and declenche_le is not null)
  );

-- =======================================================================
-- 2. Le déclenchement
-- =======================================================================
--
-- `security definer`, et appelée par la fonction serveur avec la clé de
-- service : celui qui déclenche n'est pas authentifié — c'est une
-- maîtresse qui tient un lien, pas un titulaire de compte.
--
-- Les contrôles tiennent ici et nulle part ailleurs :
--   - le partage d'origine existe, n'est ni révoqué ni expiré ;
--   - le parent a donné la préautorisation ;
--   - un accès secours n'en déclenche pas un autre.
--
-- La vérification que l'appelant détient bien une place se fait avant,
-- côté fonction serveur, qui seule connaît le secret présenté.

create or replace function public.declencher_acces_secours(
  p_partage_id uuid,
  p_maintenant timestamptz default now()
)
-- Colonnes de sortie prefixees : sans cela, `id` et `token` masquent
-- les colonnes de `partages` dans le corps de la fonction, et Postgres
-- refuse la reference comme ambigue.
returns table (
  secours_id uuid,
  secours_token text,
  secours_expire_le timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_origine public.partages%rowtype;
  v_expire timestamptz;
begin
  select * into v_origine
  from public.partages p
  where p.id = p_partage_id;

  if v_origine.id is null then
    raise exception 'Partage introuvable.';
  end if;

  if not v_origine.acces_secours_autorise then
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

  -- 24 heures a partir de l'activation, et non de la creation du
  -- partage d'origine. L'horloge est independante : elle survit a
  -- l'expiration de la souche.
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
    -- La fiche secours, et rien d'autre. Decision du 27/08/2026.
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
  returning
    public.partages.id,
    public.partages.token,
    public.partages.date_expiration;
end;
$$;

revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from public;
revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from anon;
revoke all on function public.declencher_acces_secours(uuid, timestamptz)
  from authenticated;

comment on function public.declencher_acces_secours(uuid, timestamptz) is
  'Cree un acces secours derive d''un partage. Appelee par la fonction '
  'serveur avec la cle de service : celui qui declenche n''est pas '
  'authentifie. Exige la preautorisation du parent.';

-- =======================================================================
-- 3. Le type d'événement de notification
-- =======================================================================
--
-- Le parent est prevenu immediatement. Le mail reste pauvre — « Un
-- acces secours vient d'etre ouvert pour Theo » — et le detail vit dans
-- l'application : les noms des professionnels n'ont pas a circuler par
-- courrier.

alter table public.evenements_notification_parent
  drop constraint if exists evenements_notification_parent_type_evenement_check;

alter table public.evenements_notification_parent
  add constraint evenements_notification_parent_type_evenement_check
  check (type_evenement = any (array[
    'note_ajoutee',
    'expiration_rattachement_7_jours',
    'rappel_mise_a_jour_profil',
    'rappel_partages_permanents',
    'acces_secours_declenche'
  ]));
