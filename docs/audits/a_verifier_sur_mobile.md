# À vérifier visuellement (mobile ou navigateur)

Liste vivante, remplace `2026-08-19-passe-3-a-verifier-sur-mobile.md`
(conservé pour l'historique, plus mis à jour). Regroupe tous les
points qui demandent un œil humain — sur un vrai téléphone ou en
ouvrant l'app — et que ni les tests automatisés ni l'audit de code ne
peuvent couvrir. Chaque nouvelle correction qui a besoin d'une
vérification visuelle vient s'ajouter ici au lieu de rester seulement
dans le fil de discussion.

Rien ici n'est un bug confirmé : ce sont des points à confirmer,
listés au fur et à mesure, jamais retirés avant que Fanny confirme
elle-même les avoir vérifiés.

## Corrections récentes à confirmer visuellement

1. **Mode Urgence — dose du traitement affichée sous la bonne étape
   (19/08/2026).** Théo → Mode Urgence → "Urgence liée à : Epilepsie" :
   l'étape 6 ("Au bout de 5 min administrer BUCCOLAM dans la joue")
   doit maintenant afficher juste en dessous, dans un bloc bien
   visible, "BUCCOLAM — 1 seringue — crise plus de 5 min — dans la
   bouche(joue)". Vérifié par un test automatisé qui reproduit
   exactement ces données, mais jamais regardé à l'écran.

2. **Journal des consultations, nouvel écran (19/08/2026).** Fiche
   d'un enfant → section "Traçabilité" → "Journal des consultations" :
   doit lister, pour un enfant rattaché à un établissement, chaque
   consultation de sa fiche (nom de l'établissement, fiche consultée,
   date et heure), la plus récente en premier. Vérifié par un test de
   décodage des données, jamais ouvert à l'écran avec de vraies
   consultations enregistrées (ex. celles créées pendant les tests de
   la passe 3 avec Théo, si elles existent encore).

## Depuis la passe 3 (audit, jamais vérifié sur un vrai téléphone)

Les tests automatisés de la passe 3 tournaient sur la version web de
l'app (build release, piloté par un vrai navigateur headless — pas une
simulation). Ça couvre fidèlement tout ce qui touche à Supabase
(création de compte, connexion, écriture en base, RLS) et à l'affichage
des écrans. Ça ne peut pas couvrir ce qui dépend spécifiquement du
système d'exploitation mobile, du stockage natif, ou du matériel.

2. **Confiance de l'appareil dans la durée.** Sur le web, chaque
   session de test repart de zéro (pas de stockage persistant entre
   deux lancements du navigateur headless) — impossible donc de
   vérifier qu'un téléphone, une fois reconnu après le premier code de
   vérification, reste "de confiance" durablement (jours/semaines) sans
   redemander de code à chaque ouverture de l'app. À vérifier : se
   connecter une fois, fermer complètement l'app, la rouvrir plusieurs
   heures/jours après — le code ne doit pas être redemandé tant que
   l'appareil reste le même.

3. **Comportement du cache hors-ligne côté professionnel en conditions
   réelles.** La logique de purge à 7 jours sans synchronisation est
   testée par du code, mais jamais avec un vrai appareil dont l'horloge
   avance normalement et qui perd/retrouve une vraie connexion réseau
   (mode avion, zone sans réseau). À vérifier : couper le réseau du
   téléphone, ouvrir l'app, confirmer que les fiches déjà en cache
   restent lisibles ; au bout de plus de 7 jours sans synchronisation
   réussie, confirmer que l'app refuse de faire confiance au cache et
   redemande une connexion.

4. **Purge immédiate du cache après révocation ou expiration.** Même
   limite que le point 3 : à vérifier avec un vrai deuxième appareil
   (le professionnel) qui avait un enfant en cache, une fois son accès
   révoqué ou expiré côté parent.

5. **Rendu de l'email de code de vérification dans une vraie
   application mail mobile** (Gmail, Mail iOS, Outlook...). Le contenu
   a été vérifié par un test web (texte reçu, code lisible), mais pas
   son rendu visuel dans un client mail mobile réel.

6. **Partage du lien public (fiche secours / "ce qu'il faut savoir")
   via les mécanismes natifs du téléphone** (SMS, WhatsApp, partage
   natif iOS/Android) et ouverture par un tiers qui n'a pas l'app
   installée, sur son propre téléphone. Le lien lui-même a été testé
   réellement (voir le rapport de la passe 2, round 2), mais pas le
   parcours de partage natif de bout en bout.

7. **Mode Urgence accessible rapidement, y compris depuis l'écran
   verrouillé si un raccourci est prévu.** À vérifier concrètement :
   combien de temps/d'étapes pour un accompagnant stressé pour arriver
   à la fiche secours d'un enfant précis, sur un vrai téléphone.

8. **Autofill / gestionnaire de mots de passe natif** sur les écrans de
   connexion et de création de compte (suggestion automatique du mot de
   passe, remplissage automatique par le gestionnaire de mots de passe
   du téléphone) — jamais testé, le navigateur headless n'en a pas.

9. **Performance de démarrage sur un téléphone d'entrée/moyenne
   gamme.** Le test web release démarre vite, mais rien ne dit qu'une
   compilation native fait de même sur du matériel modeste — à observer
   simplement à l'usage.

## Hors périmètre pour l'instant

Les notifications push ne sont pas listées ici : décision déjà prise de
les reporter au moment de la préparation de la publication sur les
stores (voir le plan d'espace professionnel), donc pas un sujet pour
cette liste.

## Comment utiliser cette liste

À reprendre point par point dès que Fanny peut faire des vérifications
visuelles (téléphone disponible, ou simplement le temps d'ouvrir
l'app). Un point vérifié et confirmé bon peut être supprimé de la
liste ou marqué comme tel — à la discrétion de Fanny.
