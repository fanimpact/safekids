# Corrections notées pendant l'audit, à traiter après la passe 4

Liste vivante, mise à jour au fil des 4 passes de l'audit d'août 2026.
Rien ici n'est corrigé pendant l'audit lui-même — décision explicite de
Fanny : l'audit sert d'abord à établir un état des lieux complet, les
corrections viennent après, avec ses priorités.

## Depuis la passe 1 (sécurité et RGPD, 19/08/2026)

1. **Journal des consultations lisible par le parent concerné.**
   Aujourd'hui `journal_consultations_fiche` n'a aucune politique de
   lecture pour personne, y compris le parent. Décision de Fanny : le
   parent doit pouvoir voir qui a consulté la fiche de son enfant et
   quand. Nécessite une nouvelle politique RLS (lecture par
   `enfant_du_parent(enfant_id)`) + un écran côté parent pour
   l'afficher (n'existe pas aujourd'hui).

2. **Bouton "Supprimer le profil" côté professionnel — pas
   fonctionnel.** Signalé par Fanny pendant la passe 1, à traiter
   juste après l'audit complet (pas un sujet RGPD/RLS à proprement
   parler, mais une action utilisateur cassée).

3. **Test automatisé Dart pour la limite de 7 jours du cache
   hors-ligne côté professionnel.** `ProfessionalChildRepository`
   (`lib/professional/professional_child_repository.dart`) a la bonne
   logique (`_maxOfflineAge`), mais contrairement au côté parent
   (`test/offline_cache_test.dart`), aucun test ne la vérifie. À
   construire sur le même modèle : écrire une date de synchronisation
   artificiellement ancienne dans le cache mocké, vérifier que
   `loadFromLocalCacheIfAvailable()` refuse bien de la charger.

4. **`partages` : aligner la politique RLS sur le pattern
   SECURITY DEFINER.** La policy `partages_geres_par_le_parent`
   utilise encore une sous-requête directe sur `enfants`
   (`enfant_id in (select id from enfants where parent_id =
   auth.uid())`), héritée de `schema.sql` d'origine, au lieu d'une
   fonction `SECURITY DEFINER` comme partout ailleurs dans le code
   plus récent (`enfant_du_parent()` existe déjà et fait exactement
   ça). Pas un bug actif aujourd'hui, juste une incohérence à
   corriger pour la cohérence du code.

5. **Résidus de préférences de masquage sur
   `activites_recommandations_masquees`.** La lecture ne revérifie
   pas que l'activité est toujours accessible à l'utilisateur au
   moment de la lecture (seule l'écriture le fait) — quelqu'un qui
   perd l'accès à un établissement garde ses propres préférences de
   masquage sur d'anciennes activités. Jamais une fuite de donnée
   (chacun ne voit que ses propres préférences), juste un résidu
   inutile à nettoyer.

## Depuis la passe 2 (moteur de recommandations, 19/08/2026)

6. **Distinction visuelle des recommandations critiques.** Aujourd'hui
   une recommandation critique (`isCritical: true`) est non masquable
   partout (vérifié), mais s'affiche exactement comme les autres sur
   les fiches et le PDF — aucune mise en forme ne la distingue. Décision
   de Fanny : reportée, à ne pas traiter maintenant.

(Les autres constats de la passe 2 — bug de présélection, doublon
"effort physique", recommandations manquantes — ont été corrigés
directement le 19/08/2026 plutôt que reportés ici : Fanny a demandé un
traitement immédiat pour ceux-là, contrairement aux items 1-5 de la
passe 1. Voir l'historique git pour le détail des commits.)

## Consigne permanente pour la suite de l'audit

Ne plus créer de comptes ou d'enregistrements fictifs dans la base
réelle pour un test, sans demander d'abord à Fanny.
