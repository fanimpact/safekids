-- =======================================================================
-- La reprise d'accès, et le déverrouillage par le parent — 28/08/2026
-- =======================================================================
--
-- Le défaut, tel qu'il se manifeste.
--
-- Le secret du verrou vit dans le `localStorage` du navigateur qui a
-- ouvert la fiche. Or ce cloisonnement n'est pas le nôtre : c'est celui
-- du système. Un lecteur de QR ou une messagerie qui ouvre la page dans
-- **son propre navigateur intégré** range le secret là, et si la
-- personne rouvre plus tard depuis Safari ou Chrome, elle se présente
-- comme une inconnue.
--
-- Le moment où ça se voit est le pire possible : une maîtresse rouvre
-- la fiche parce qu'il se passe quelque chose avec l'enfant.
--
-- =======================================================================
-- Ce qui est retenu, et pourquoi
-- =======================================================================
--
-- **La reprise explicite.** Au lieu d'un refus sec, la page propose de
-- reprendre l'accès, en prévenant que le parent en sera informé.
--
-- Ce n'est pas un affaiblissement en trompe-l'oeil : aujourd'hui, une
-- reprise dans les quinze minutes est **déjà** possible, et elle est
-- **silencieuse**. On remplace donc un mur qui se contourne sans trace
-- par un passage qui en laisse une.
--
-- Décision de Fanny : **aucun compteur, aucun délai minimum entre deux
-- reprises**. « La notification et la révocation suffisent. » C'est le
-- même arbitrage que pour l'accès secours.

-- =======================================================================
-- 1. La trace, distincte d'un refus et d'une tolérance
-- =======================================================================
--
-- `toleree` disait deja « laissee passer sans consommer de place ». Une
-- reprise l'est aussi, mais elle est **demandee** : le parent ne lit pas
-- la meme chose selon qu'un lien a ete rouvert tout seul dans le quart
-- d'heure ou que quelqu'un a repris la main des heures apres.

alter table public.tentatives_partage_refusees
  add column if not exists reprise boolean not null default false;

comment on column public.tentatives_partage_refusees.reprise is
  'Quelqu''un a demande a reprendre l''acces, apres un refus. Distinct '
  'de toleree, qui couvre la reouverture silencieuse dans la fenetre '
  'de quinze minutes.';

-- =======================================================================
-- 2. Le parent en est informé
-- =======================================================================

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
      -- Sans elle, la reprise serait un affaiblissement muet. C'est
      -- la notification qui la rend acceptable.
      'acces_repris'
    ])
  );

-- =======================================================================
-- 3. Le déverrouillage par le parent — réparation
-- =======================================================================
--
-- Le bouton « autoriser son nouvel appareil » appelait `libererVerrou`,
-- qui remettait a zero `verrou_empreinte` et `verrou_pose_le`. Ces deux
-- colonnes ne sont plus lues par personne depuis la refonte du
-- 27/08/2026 : la decision se prend sur `appareils_partage`.
--
-- Le bouton ne faisait donc **rien**, et affichait pourtant « Le
-- prochain appareil qui ouvrira ce lien pourra le consulter ». Une
-- personne refusee n'avait aucune issue, ni par elle-meme, ni par le
-- parent.
--
-- **La place la plus recemment prise**, et une seule. C'est celle du
-- navigateur fantome dans le cas qui nous occupe, et c'est la seule
-- quand le parent a choisi un appareil — ce qui est le defaut. Liberer
-- toutes les places evincerait des lecteurs legitimes que le parent
-- n'a pas vises.
--
-- `security definer` : le parent n'a que le droit de LIRE
-- `appareils_partage` (politique `appareils_lisibles_par_le_parent`).
-- Lui ouvrir un droit de suppression sur la table entiere pour ce seul
-- geste serait disproportionne.

create or replace function public.liberer_place_partage(
  p_partage_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enfant uuid;
  v_place uuid;
begin
  select p.enfant_id into v_enfant
  from public.partages p
  where p.id = p_partage_id;

  if v_enfant is null then
    raise exception 'Partage introuvable.';
  end if;

  -- Le seul controle qui compte : c'est bien l'enfant de l'appelant.
  if not public.enfant_du_parent(v_enfant) then
    raise exception 'Ce partage n''est pas le votre.';
  end if;

  select a.id into v_place
  from public.appareils_partage a
  where a.partage_id = p_partage_id
  order by a.pris_le desc
  limit 1;

  if v_place is null then
    -- Aucune place occupee : il n'y a rien a liberer, et le prochain
    -- appareil entrera de toute facon. Ce n'est pas une erreur.
    return 0;
  end if;

  delete from public.appareils_partage where id = v_place;

  return 1;
end;
$$;

revoke all on function public.liberer_place_partage(uuid) from public;
revoke all on function public.liberer_place_partage(uuid) from anon;
grant execute on function public.liberer_place_partage(uuid)
  to authenticated;
