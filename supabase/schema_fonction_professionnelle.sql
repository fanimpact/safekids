-- =======================================================================
-- La fonction du professionnel, telle que le parent la lira — 25/08/2026
-- =======================================================================
--
-- Le problème que ce script règle.
--
-- Une note écrite sur un enfant s'affiche désormais dans la fiche de cet
-- enfant, côté parent. Restait à dire QUI l'a écrite. La seule
-- information disponible était `membres_etablissement.role` —
-- `directeur`, `adjoint`, `membre` — et vérification faite, elle ne
-- décrit pas la personne :
--
--   - `directeur` désigne simplement qui a créé le compte de
--     l'établissement, pas la direction de l'école ;
--   - `adjoint` veut dire « deuxième personne autorisée à gérer les
--     invitations », et rien de plus : les deux valeurs sont
--     indiscernables dans tout le code (`role in ('directeur',
--     'adjoint')`, toujours ensemble) ;
--   - `membre` est tout le monde : la maîtresse, la cantine, le
--     périscolaire, le stagiaire.
--
-- Surtout, le rôle ne gouverne RIEN de ce qui concerne les enfants.
-- Lire une fiche, écrire une note, créer une activité passent tous par
-- `est_membre_actif`, qui ne regarde que `statut = 'actif'`.
--
-- Un parent qui lit une observation sur son enfant doit savoir si elle
-- vient de la maîtresse, de la cantine ou de la direction. Le rôle ne
-- pouvait pas le lui dire ; ce script ajoute ce qui le peut.
--
-- =======================================================================
-- Pourquoi sur le rattachement, et pas sur le compte
-- =======================================================================
--
-- La même personne peut être maîtresse dans une école et animatrice
-- dans un centre de loisirs. La fonction appartient donc au couple
-- (personne, établissement), c'est-à-dire à `membres_etablissement` —
-- là où `role` vit déjà, ce qui évite au passage une jointure de plus
-- dans `notes_enfant_pour_parent`.
--
-- Conséquence à connaître : elle ne peut pas être saisie à
-- l'inscription. À ce moment-là le professionnel n'est rattaché à rien.
--
-- =======================================================================
-- Ce que la colonne contient
-- =======================================================================
--
-- Le libellé exact que le parent lira. Pas un code, pas une clé : ce
-- que la personne a choisi dans la liste, ou ce qu'elle a écrit sous
-- « Autre ». Aucun accord n'est ajouté par l'application — elle écrit
-- ce qu'elle est.
--
-- Pas de `check` sur un vocabulaire fermé, donc : « Autre » l'interdit.
-- Seules la longueur et le fait d'être non vide sont contrôlés, dans
-- `rpc_definir_ma_fonction`.
--
-- Nullable, et sans valeur par défaut : on n'invente pas une fonction
-- pour les comptes existants. Les notes déjà écrites afficheront
-- « Fonction non précisée » ; les notes nouvelles seront impossibles
-- tant que la fonction manque (contrôle côté application). Le trou se
-- referme à la première note de chacun, il n'est pas un repli
-- permanent.

alter table public.membres_etablissement
  add column if not exists fonction text;

comment on column public.membres_etablissement.fonction is
  'Fonction declaree par la personne elle-meme, telle que le parent la '
  'lira sous une note. Libelle libre : « Autre » interdit un '
  'vocabulaire ferme. Jamais renseignee par celui qui invite.';

-- =======================================================================
-- Chacun déclare la sienne, et seulement la sienne
-- =======================================================================
--
-- `membres_etablissement` n'a aucune policy d'écriture directe : tout
-- passe par des `rpc`. Celle-ci ne fait pas exception, et son `where`
-- porte `user_id = auth.uid()` — une personne ne peut toucher qu'à sa
-- propre ligne.
--
-- **Jamais renseignée par celui qui invite.** Il devinerait, et une
-- fonction fausse sous une observation qui parle d'un enfant est
-- exactement ce qu'on cherche à éviter.

create or replace function public.rpc_definir_ma_fonction(
  p_etablissement_id uuid,
  p_fonction text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fonction text;
  v_lignes integer;
begin
  v_fonction := trim(coalesce(p_fonction, ''));

  if v_fonction = '' then
    raise exception 'Indiquez votre fonction.';
  end if;

  -- 60 caracteres : la ligne s'affiche sous une note, sur un telephone.
  -- Au-dela elle deborde, et une fonction qui deborde n'informe plus.
  if length(v_fonction) > 60 then
    raise exception 'La fonction ne doit pas depasser 60 caracteres.';
  end if;

  update public.membres_etablissement
  set fonction = v_fonction
  where etablissement_id = p_etablissement_id
    and user_id = auth.uid()
    and statut = 'actif';

  get diagnostics v_lignes = row_count;

  if v_lignes = 0 then
    raise exception
      'Vous n''etes pas membre actif de cet etablissement.';
  end if;
end;
$$;

revoke all on function public.rpc_definir_ma_fonction(uuid, text) from public;
revoke all on function public.rpc_definir_ma_fonction(uuid, text) from anon;
grant execute on function public.rpc_definir_ma_fonction(uuid, text)
  to authenticated;

-- =======================================================================
-- La fonction du fondateur, à la création de l'établissement
-- =======================================================================
--
-- `drop` obligatoire avant de recréer : ajouter un paramètre ne
-- remplace pas la fonction, il en crée une seconde, et un appel à deux
-- arguments deviendrait ambigu.
--
-- Le nouveau paramètre a une valeur par défaut : une version de
-- l'application qui appelle encore à deux arguments continue de
-- fonctionner, elle laisse simplement la fonction vide.

drop function if exists public.rpc_creer_etablissement(text, text);

create or replace function public.rpc_creer_etablissement(
  p_nom text,
  p_type text,
  p_fonction text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_email text;
  v_fonction text;
begin
  if p_nom is null or length(trim(p_nom)) = 0 then
    raise exception 'Le nom de l''etablissement est obligatoire.';
  end if;

  v_email := auth.jwt() ->> 'email';
  v_fonction := nullif(trim(coalesce(p_fonction, '')), '');

  if v_fonction is not null and length(v_fonction) > 60 then
    raise exception 'La fonction ne doit pas depasser 60 caracteres.';
  end if;

  insert into public.etablissements (nom, type_etablissement, created_by)
  values (trim(p_nom), p_type, auth.uid())
  returning id into v_id;

  insert into public.membres_etablissement
    (etablissement_id, email, user_id, role, statut, invite_par,
     accepte_le, fonction)
  values
    (v_id, coalesce(v_email, ''), auth.uid(), 'directeur', 'actif',
     auth.uid(), now(), v_fonction);

  return v_id;
end;
$$;

revoke all on function public.rpc_creer_etablissement(text, text, text)
  from public;
revoke all on function public.rpc_creer_etablissement(text, text, text)
  from anon;
grant execute on function public.rpc_creer_etablissement(text, text, text)
  to authenticated;

-- =======================================================================
-- Ce que le parent reçoit désormais
-- =======================================================================
--
-- `role_auteur` disparaît de la sortie, et c'est délibéré : il ne
-- voulait rien dire pour un parent, et le laisser aurait laissé une
-- porte ouverte pour le réafficher un jour par mégarde. `fonction_auteur`
-- le remplace.
--
-- `drop` obligatoire : on ne change pas le type de retour d'une
-- fonction avec `create or replace`.
--
-- Tout le reste est identique au script du 25/08/2026
-- (schema_notes_visibles_parent.sql), garde-fou compris :
-- `enfant_du_parent(p_enfant_id)` reste le seul contrôle de droit de
-- cette fonction, qui contourne le RLS.

drop function if exists public.notes_enfant_pour_parent(uuid);

create or replace function public.notes_enfant_pour_parent(
  p_enfant_id uuid
)
returns table (
  id uuid,
  note text,
  cree_le timestamptz,
  nom_activite text,
  date_activite timestamptz,
  nom_etablissement text,
  fonction_auteur text
)
language sql
security definer
stable
set search_path = public
as $$
  select
    n.id,
    n.note,
    n.cree_le,
    a.nom_activite,
    a.date_activite,
    e.nom,
    -- Sous-requête et non jointure : `membres_etablissement` est unique
    -- par (etablissement_id, email), pas par (etablissement_id,
    -- user_id). Une même personne réinvitée sous une autre adresse
    -- dupliquerait la note. `limit 1` garantit une ligne par note.
    (
      select m.fonction
      from public.membres_etablissement m
      where m.etablissement_id = a.etablissement_id
        and m.user_id = n.auteur_id
      order by m.accepte_le asc nulls last
      limit 1
    ) as fonction_auteur
  from public.notes_activite n
  join public.activites_preparees a
    on a.id = n.activite_id
  -- `left join` : un établissement supprimé ne doit pas faire
  -- disparaître la note elle-même. L'écran sait afficher un auteur
  -- inconnu ; il ne saurait pas afficher une note qu'il n'a pas reçue.
  left join public.etablissements e
    on e.id = a.etablissement_id
  where n.enfant_id = p_enfant_id
    and public.enfant_du_parent(p_enfant_id)
  order by n.cree_le desc;
$$;

revoke all on function public.notes_enfant_pour_parent(uuid) from public;
revoke all on function public.notes_enfant_pour_parent(uuid) from anon;
grant execute on function public.notes_enfant_pour_parent(uuid) to authenticated;

comment on function public.notes_enfant_pour_parent(uuid) is
  'Notes d''activite concernant un enfant, pour son parent. Rend le '
  'contexte (activite, etablissement, fonction declaree de l''auteur) '
  'sans ouvrir les tables de l''espace professionnel. L''adresse email '
  'de l''auteur ne sort jamais, son role administratif non plus. Zero '
  'ligne si l''enfant n''est pas celui de l''appelant.';
