-- =======================================================================
-- Les notes d'activité, vues par le parent — 25/08/2026
-- =======================================================================
--
-- Le problème que ce script règle.
--
-- Un membre d'établissement peut écrire une note sur un enfant. Le
-- parent en est prévenu par email, et l'email lui dit « Connectez-vous
-- à l'application KidsRelay pour la consulter ». Or aucun écran ne les
-- affiche : les notes ne sont chargées que dans l'espace professionnel.
-- Le parent était convoqué devant une porte fermée.
--
-- Le RLS de `notes_activite` lui donne pourtant déjà le droit de lire
-- les notes rattachées à son enfant. Ce qui lui manque, c'est le
-- CONTEXTE : le nom de l'activité, sa date, l'établissement, la
-- qualité de l'auteur. Ces colonnes vivent dans `activites_preparees`
-- et `membres_etablissement`, deux tables de l'espace professionnel
-- qu'un parent ne peut pas lire — et une activité d'établissement a
-- `parent_id` à null par construction (contrainte `un_seul_proprietaire`),
-- donc la policy « activites_du_parent » ne peut jamais l'atteindre.
--
-- =======================================================================
-- Pourquoi une fonction, et pas deux policies
-- =======================================================================
--
-- Ouvrir `activites_preparees` et `membres_etablissement` en lecture au
-- parent aurait marché. Ç'aurait aussi été trop.
--
-- Le RLS travaille à la ligne, jamais à la colonne : donner accès à la
-- ligne d'un membre, c'est donner accès à son adresse email
-- professionnelle — que le parent n'a jamais eu à voir nulle part
-- ailleurs dans l'application, et dont il a été décidé le 25/08/2026
-- qu'il n'a pas à la voir ici non plus. Seule la QUALITÉ de l'auteur
-- sort : direction, direction adjointe, ou membre de l'équipe.
--
-- Une fonction `security definer` ne rend donc que les six colonnes
-- décidées, et rien d'autre ne devient lisible au passage.
--
-- =======================================================================
-- Ce qui garde la porte
-- =======================================================================
--
-- `security definer` contourne le RLS. La clause
-- `public.enfant_du_parent(p_enfant_id)` est donc le SEUL contrôle de
-- droit de cette fonction. Si elle disparaît, n'importe quel compte
-- authentifié lit les notes de n'importe quel enfant.
--
-- Elle vérifie deux choses à la fois (voir schema_conformite_rgpd.sql) :
-- que l'enfant appartient bien à l'appelant, et que son compte n'est
-- pas en cours de suppression.
--
-- **Un enfant qui n'est pas le sien rend zéro ligne, pas une erreur.**
-- Volontaire : une exception distinguerait « cet enfant existe mais
-- n'est pas à vous » de « cet enfant n'a pas de note », ce qui
-- renseigne un curieux sur l'existence d'un identifiant.
--
-- Trois choses restent hors de portée, et doivent le rester :
--   - les notes générales au groupe (`enfant_id is null`), qui ne
--     concernent pas un enfant en particulier ;
--   - les notes portant sur les AUTRES enfants de la même activité ;
--   - l'adresse email de l'auteur, et toute autre colonne de
--     `membres_etablissement`.
--
-- Le filtre `n.enfant_id = p_enfant_id` porte les deux premières.
--
-- **Personne de confiance : délibérément exclue.** `enfant_du_parent`
-- teste `parent_id = auth.uid()`, donc le propriétaire seul. Une
-- personne de confiance ne voit pas ces notes. C'est un choix, pas un
-- oubli : le droit d'accès d'une personne de confiance est une
-- question ouverte notée dans corrections_a_faire.md, et il vaut mieux
-- l'ouvrir exprès un jour que par accident aujourd'hui.

-- =======================================================================
-- La fonction
-- =======================================================================

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
  role_auteur text
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
      select m.role
      from public.membres_etablissement m
      where m.etablissement_id = a.etablissement_id
        and m.user_id = n.auteur_id
      order by m.accepte_le asc nulls last
      limit 1
    ) as role_auteur
  from public.notes_activite n
  join public.activites_preparees a
    on a.id = n.activite_id
  -- `left join` sur les deux : un établissement supprimé, ou un auteur
  -- dont la ligne de membre a disparu, ne doit pas faire disparaître la
  -- note elle-même. L'écran sait afficher un auteur inconnu ; il ne
  -- saurait pas afficher une note qu'il n'a pas reçue.
  left join public.etablissements e
    on e.id = a.etablissement_id
  where n.enfant_id = p_enfant_id
    and public.enfant_du_parent(p_enfant_id)
  order by n.cree_le desc;
$$;

-- Le rôle `anon` n'a rien à faire ici : une note sur un enfant ne se
-- lit pas sans être connecté. `revoke from public` d'abord, parce que
-- `create function` accorde execute à tout le monde par défaut.
revoke all on function public.notes_enfant_pour_parent(uuid) from public;
revoke all on function public.notes_enfant_pour_parent(uuid) from anon;
grant execute on function public.notes_enfant_pour_parent(uuid) to authenticated;

comment on function public.notes_enfant_pour_parent(uuid) is
  'Notes d''activite concernant un enfant, pour son parent. Rend le '
  'contexte (activite, etablissement, qualite de l''auteur) sans '
  'ouvrir les tables de l''espace professionnel. L''adresse email de '
  'l''auteur ne sort jamais. Zero ligne si l''enfant n''est pas celui '
  'de l''appelant.';
