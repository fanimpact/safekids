-- =====================================================================
-- SafeKids - la LECTURE des preferences de masquage individuel
-- (activites_recommandations_masquees) revalide desormais que
-- l'activite concernee est toujours accessible a l'utilisateur au
-- moment de la lecture, pas seulement a l'ecriture -- corrections de
-- l'audit passe 1, item 5. Jamais une fuite de donnee (chacun ne
-- pouvait deja voir que ses propres preferences), juste un residu
-- inutile qui restait lisible apres avoir perdu l'acces a un
-- etablissement.
--
-- La policy "for all" d'origine appliquait la meme regle (ownership
-- seul) a la lecture ET a l'ecriture, avec la verification de
-- visibilite seulement dans le "with check" (ecriture). Remplacee ici
-- par des policies separees par commande, pour que la lecture ait sa
-- propre regle, plus stricte. La suppression reste basee sur la seule
-- propriete (sans revisibilite) : une personne doit toujours pouvoir
-- nettoyer sa propre preference, meme apres avoir perdu l'acces.
--
-- Script idempotent. A executer dans Supabase : Dashboard -> SQL
-- Editor -> coller -> Run. Necessite
-- schema_espace_professionnel_activites.sql (deja execute).
-- =====================================================================

drop policy if exists "masquages_du_lecteur"
  on public.activites_recommandations_masquees;

drop policy if exists "masquages_lecture"
  on public.activites_recommandations_masquees;
drop policy if exists "masquages_ecriture"
  on public.activites_recommandations_masquees;
drop policy if exists "masquages_ecriture_insert"
  on public.activites_recommandations_masquees;
drop policy if exists "masquages_ecriture_update"
  on public.activites_recommandations_masquees;
drop policy if exists "masquages_suppression"
  on public.activites_recommandations_masquees;

create policy "masquages_lecture"
  on public.activites_recommandations_masquees
  for select
  using (
    user_id = auth.uid()
    and exists (
      select 1 from public.activites_preparees a
      where a.id = activite_id
        and (
          a.parent_id = auth.uid()
          or (
            a.etablissement_id is not null
            and public.est_membre_actif(a.etablissement_id)
          )
        )
    )
  );

-- L'app ecrit via upsert (INSERT ... ON CONFLICT DO UPDATE) : les
-- deux commandes doivent etre autorisees avec la meme regle.
create policy "masquages_ecriture_insert"
  on public.activites_recommandations_masquees
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.activites_preparees a
      where a.id = activite_id
        and (
          a.parent_id = auth.uid()
          or (
            a.etablissement_id is not null
            and public.est_membre_actif(a.etablissement_id)
          )
        )
    )
  );

create policy "masquages_ecriture_update"
  on public.activites_recommandations_masquees
  for update
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.activites_preparees a
      where a.id = activite_id
        and (
          a.parent_id = auth.uid()
          or (
            a.etablissement_id is not null
            and public.est_membre_actif(a.etablissement_id)
          )
        )
    )
  );

-- Toujours permise sur la base de la seule propriete : une personne
-- doit pouvoir nettoyer sa propre preference meme apres avoir perdu
-- l'acces a l'etablissement concerne.
create policy "masquages_suppression"
  on public.activites_recommandations_masquees
  for delete
  using (user_id = auth.uid());
