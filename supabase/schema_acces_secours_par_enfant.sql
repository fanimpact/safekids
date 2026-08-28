-- =======================================================================
-- L'accès secours se décide par enfant, pas par partage — 28/08/2026
-- =======================================================================
--
-- Correction d'un emplacement, décidée par Fanny le jour même où il a
-- été posé.
--
-- La préautorisation était demandée à la création de **chaque**
-- partage. Le parent devait donc y penser à chaque fois — et **le jour
-- où il oublie sera le jour de l'accident**. C'est la mauvaise
-- question posée au mauvais moment.
--
-- Elle se donne désormais **une fois par enfant**, juste après le
-- questionnaire santé, et se modifie ensuite depuis son profil. Elle
-- vaut pour tous ses partages, existants et à venir.
--
-- La distinction par destinataire n'avait pas de sens : aucun parent ne
-- dirait « oui pour que les secours aient les antécédents de mon enfant
-- s'il est à l'école, non s'il est chez la nounou ». L'urgence ne
-- dépend pas de qui garde l'enfant.
--
-- RGPD : une autorisation générale reste valable dès lors qu'elle est
-- explicite, que le parent sait ce qu'il autorise, et qu'il peut
-- revenir dessus à tout moment. Les trois conditions sont tenues.

-- =======================================================================
-- 1. La colonne, sur l'enfant
-- =======================================================================

alter table public.enfants
  add column if not exists acces_secours_autorise boolean not null
    default false;

comment on column public.enfants.acces_secours_autorise is
  'Preautorisation donnee une fois par le parent, apres le '
  'questionnaire sante, et modifiable depuis le profil de l''enfant. '
  'Vaut pour tous ses partages, existants et a venir. Jamais cochee '
  'd''avance.';

-- Reprise de ce qui avait ete pose sur les partages, le temps que
-- l'emplacement change : si un partage l'avait, l'enfant l'obtient.
update public.enfants e
set acces_secours_autorise = true
where exists (
  select 1 from public.partages p
  where p.enfant_id = e.id
    and p.acces_secours_autorise
);

-- =======================================================================
-- 2. Le déclenchement lit l'enfant
-- =======================================================================
--
-- Le controle reste ici, en plus de celui de la fonction serveur :
-- c'est le seul endroit qui tienne si un autre appelant s'adresse un
-- jour a la meme table.

create or replace function public.declencher_acces_secours(
  p_partage_id uuid,
  p_maintenant timestamptz default now()
)
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
  v_autorise boolean;
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
    -- La fiche secours, et rien d'autre.
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

-- =======================================================================
-- 3. La colonne des partages est retirée
-- =======================================================================
--
-- Elle n'a jamais servi en production : le mecanisme n'etait pas encore
-- deploye. La retirer maintenant evite qu'un lecteur futur se demande
-- laquelle des deux fait foi.

alter table public.partages
  drop column if exists acces_secours_autorise;
