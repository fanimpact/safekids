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

7. **Médecin traitant et antécédents médicaux absents de "Ce qu'il faut
   savoir sur...".** Cette fiche est explicitement pensée (commentaire
   du code) pour un accompagnant qui garde l'enfant plusieurs jours
   (ex. grands-parents) — profil qui aurait plausiblement besoin du
   contact du médecin traitant en cas de problème non urgent. Présents
   sur la fiche secours, absents ici. Confirmé par Fanny (19/08/2026) :
   à corriger, pas un simple constat.

8. **Spécialité, lieu d'exercice et téléphone du médecin référent d'une
   pathologie, saisis mais jamais affichés nulle part** — ni sur la
   fiche secours, ni sur "Ce qu'il faut savoir" (seul le nom apparaît,
   sur cette dernière uniquement). Confirmé par Fanny (19/08/2026) : à
   corriger.

9. **Dispositif médical "porté en permanence" — distingué sur "Ce
   qu'il faut savoir", pas sur la fiche secours.** Savoir qu'un
   dispositif est implanté (pompe à insuline, etc.) est au moins aussi
   utile en urgence qu'au quotidien — la fiche secours liste tous les
   dispositifs indifféremment, sans cette précision. Confirmé par
   Fanny (19/08/2026) : à corriger.

## Depuis la passe 3 (parcours bout en bout, 19/08/2026)

10. **Message d'erreur technique brut affiché à l'utilisateur lors de
    la création de compte.** Testé réellement avec un compte de test :
    quand Supabase rejette une adresse email invalide, l'app affiche
    directement l'exception brute
    (`AuthApiException(message: Email address "" is invalid,
    statusCode: 400, code: email_address_invalid)`) au lieu d'un
    message clair en français. À remplacer par un message utilisateur
    compréhensible, quelle que soit la cause du rejet côté Supabase.

11. **Email de code de vérification "nouvel appareil" — expéditeur et
    réponse mal configurés côté Brevo.** Testé réellement (vrai email
    reçu et code utilisé pour se connecter) : le nom d'expéditeur
    affiché est "KidsRelay" au lieu de "SafeKids", et l'adresse
    "répondre à" pointe vers l'adresse personnelle de Fanny
    (fannydicaro@hotmail.fr) — un utilisateur qui répond à cet email
    automatique atterrit directement dans sa boîte perso. Il faut une
    adresse de réponse dédiée au projet (pas l'adresse personnelle de
    Fanny), et corriger le nom d'expéditeur pour qu'il dise "SafeKids".
    À vérifier/corriger dans la configuration du template Brevo.

12. **Limite d'envoi d'emails du service d'authentification par défaut
    de Supabase — à vérifier avant le lancement public.** Constaté
    réellement pendant la passe 3 : après une poignée d'emails de
    confirmation d'inscription envoyés en peu de temps pendant les
    tests, Supabase a bloqué toute nouvelle inscription avec
    `AuthApiException(..., code: over_email_send_rate_limit)`. Le
    service d'email intégré par défaut de Supabase est volontairement
    très limité (pensé pour le développement, pas pour la production) —
    la même limite s'appliquera aux vraies inscriptions de parents une
    fois l'app publiée, avec le risque qu'un pic d'inscriptions (ex. un
    lancement) bloque les emails de confirmation pour tout le monde. À
    vérifier avant le lancement : (1) quelle est la limite exacte
    configurée sur le projet, (2) faire passer les emails
    d'authentification (confirmation d'inscription, réinitialisation de
    mot de passe) par un fournisseur SMTP externe — Brevo, déjà utilisé
    pour les emails "métier" (code de vérification, notifications) — au
    lieu du service email intégré de Supabase, qui lève cette limite.

13. **Après révocation, la fiche déjà ouverte reste affichée côté
    professionnel jusqu'à rechargement.** Testé réellement pendant la
    passe 3 : dès que le parent révoque, l'accès réel aux données est
    coupé immédiatement côté serveur (vérifié par impersonation RLS —
    0 ligne visible pour le professionnel revoqué), donc aucune fuite
    de donnée nouvelle n'est possible. Mais un onglet déjà ouvert sur
    la fiche secours au moment de la révocation continue d'afficher les
    informations déjà chargées tant que l'utilisateur ne recharge pas
    ou ne resynchronise pas manuellement — l'écran ne réagit pas de
    lui-même à la révocation. Confirmé par Fanny (19/08/2026) : à
    corriger, pour que la fiche disparaisse rapidement même sans action
    du professionnel (ex. vérification périodique de l'accès pendant
    que l'écran est ouvert, ou écoute en temps réel du changement de
    statut du rattachement).

## Consigne permanente pour la suite de l'audit

Ne plus créer de comptes ou d'enregistrements fictifs dans la base
réelle pour un test, sans demander d'abord à Fanny.
