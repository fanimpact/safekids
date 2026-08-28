-- =======================================================================
-- Le QR de partage — 28/08/2026
-- =======================================================================
--
-- Partager la fiche en présentiel : le parent affiche un code, le
-- destinataire le scanne avec son téléphone, et repart avec l'accès.
--
-- **Ce n'est pas un second mécanisme.** Un code à scanner est la même
-- ligne `partages` qu'un lien : même jeton, même page publique, même
-- verrou, mêmes places, même révocation par marquage, même ligne dans
-- la liste du parent, même journal de consultation.
--
-- La seule chose qui n'existait pas, c'est **une fenêtre pendant
-- laquelle le jeton peut être réclamé pour la première fois**.
--
-- =======================================================================
-- Deux durées, deux colonnes, jamais mélangées
-- =======================================================================
--
--   - `utilisable_jusqu_a` : cinq minutes. Le temps que le code reste
--     scannable. Elle ne dit rien de la durée de l'accès.
--   - `date_expiration` / `permanent` : la durée choisie par le parent
--     avant d'afficher le code, dans la liste déjà existante — 24 h,
--     3 jours, 7 jours, 1 mois, 1 an, une date au calendrier, ou sans
--     date de fin.
--
-- Dès qu'une place est prise, la fenêtre ne compte plus. L'accès vit
-- sur sa propre échéance, exactement comme un lien envoyé par SMS.
--
-- Nulle = un lien ordinaire, sans fenêtre. Les lignes existantes
-- restent valides sans rien migrer.

alter table public.partages
  add column if not exists utilisable_jusqu_a timestamptz;

comment on column public.partages.utilisable_jusqu_a is
  'Jusqu''a quand ce code peut etre scanne pour la PREMIERE fois. '
  'Sans rapport avec date_expiration, qui porte la duree de l''acces '
  'une fois accorde. Nulle pour un lien ordinaire.';

-- =======================================================================
-- Ce code a-t-il déjà été scanné ?
-- =======================================================================
--
-- « Scanne » n'est pas une notion nouvelle : c'est le verrou qui
-- l'ecrit, en prenant une place dans `appareils_partage`. On ne compte
-- pas les tentatives, on regarde s'il y a un detenteur.

create or replace function public.code_partage_scanne(p_partage_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.appareils_partage a
    where a.partage_id = p_partage_id
  );
$$;

grant execute on function public.code_partage_scanne(uuid)
  to authenticated, anon;

-- =======================================================================
-- Afficher un code, et le rafraîchir
-- =======================================================================
--
-- Une seule operation pour deux gestes qui n'en font qu'un : ouvrir la
-- fenetre a la creation, et la rouvrir chaque fois que le parent
-- revient sur l'ecran.
--
-- **Le jeton tourne a chaque rafraichissement.** Se contenter de
-- repousser la fenetre laisserait le meme jeton, et une photo du code
-- precedent redeviendrait valable — ce qui viderait la regle des cinq
-- minutes de son sens.
--
-- **Et seulement tant que rien n'a ete scanne.** Apres, faire tourner
-- le jeton couperait le destinataire, qui n'a rien demande.
--
-- `security invoker` : c'est la politique RLS `partages_geres_par_le_parent`
-- qui autorise, et elle le fait deja bien. Une fonction `definer`
-- ici remplacerait un rempart eprouve par un controle ecrit a la main.

create or replace function public.rafraichir_code_partage(
  p_partage_id uuid,
  p_maintenant timestamptz default now()
)
returns table (
  code_token text,
  code_utilisable_jusqu_a timestamptz,
  code_deja_scanne boolean
)
language plpgsql
-- `extensions` en plus de `public` : pgcrypto y vit, et sans lui
-- `gen_random_bytes` reste introuvable — le defaut de la colonne
-- `token` le trouvait, pas cette fonction.
set search_path = public, extensions
as $$
declare
  v_partage public.partages%rowtype;
begin
  -- RLS filtre : un parent ne voit que les partages de ses enfants.
  select * into v_partage
  from public.partages p
  where p.id = p_partage_id;

  if v_partage.id is null then
    raise exception 'Partage introuvable.';
  end if;

  if v_partage.revoque_le is not null then
    raise exception 'Ce partage a ete revoque.';
  end if;

  if public.code_partage_scanne(p_partage_id) then
    -- Rien a rafraichir : le code a servi. Le parent doit le savoir
    -- plutot que de continuer a tendre son telephone.
    return query
    select v_partage.token, v_partage.utilisable_jusqu_a, true;

    return;
  end if;

  -- Cinq minutes, et c'est ici que ce nombre vit. L'application lit la
  -- date rendue et compte a rebours dessus : elle n'a pas sa propre
  -- idee de la duree.
  return query
  update public.partages
  set token = encode(gen_random_bytes(24), 'hex'),
      utilisable_jusqu_a = p_maintenant + interval '5 minutes'
  where id = p_partage_id
  returning token, utilisable_jusqu_a, false;
end;
$$;

revoke all on function
  public.rafraichir_code_partage(uuid, timestamptz) from public;
revoke all on function
  public.rafraichir_code_partage(uuid, timestamptz) from anon;
grant execute on function
  public.rafraichir_code_partage(uuid, timestamptz) to authenticated;
