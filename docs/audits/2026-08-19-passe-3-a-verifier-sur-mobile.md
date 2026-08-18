# Passe 3 — ce qu'il faudra vérifier sur un vrai téléphone

Liste vivante, mise à jour au fil de la passe 3. Fanny n'a pas encore
l'application installée sur son téléphone — tout ce qui suit est donc
non testé pour l'instant, à vérifier dès qu'un vrai device est
disponible. Rien ici n'est un bug confirmé : ce sont des points que le
pilotage automatisé (Chromium headless via Playwright, web build) ne
peut structurellement pas couvrir, ou des comportements qui peuvent
différer entre navigateur et application native.

## Pourquoi une liste séparée

Les tests automatisés de cette passe tournent sur la version web de
l'app (build release, pilotée par un vrai navigateur headless — pas
une simulation). Ça couvre fidèlement tout ce qui touche à Supabase
(création de compte, connexion, écriture en base, RLS) et à l'affichage
des écrans. Ça ne peut pas couvrir ce qui dépend spécifiquement du
système d'exploitation mobile, du stockage natif, ou du matériel.

## À vérifier sur téléphone (Android et/ou iOS)

1. **Confiance de l'appareil dans la durée.** Sur le web, chaque
   session de test repart de zéro (pas de stockage persistant entre
   deux lancements du navigateur headless) — impossible donc de
   vérifier qu'un téléphone, une fois reconnu après le premier code de
   vérification, reste "de confiance" durablement (jours/semaines) sans
   redemander de code à chaque ouverture de l'app. À vérifier : se
   connecter une fois, fermer complètement l'app, la rouvrir plusieurs
   heures/jours après — le code ne doit pas être redemandé tant que
   l'appareil reste le même.

2. **Comportement du cache hors-ligne côté professionnel en conditions
   réelles.** La logique de purge à 7 jours sans synchronisation est
   testée par du code, mais jamais avec un vrai appareil dont l'horloge
   avance normalement et qui perd/retrouve une vraie connexion réseau
   (mode avion, zone sans réseau). À vérifier : couper le réseau du
   téléphone, ouvrir l'app, confirmer que les fiches déjà en cache
   restent lisibles ; au bout de plus de 7 jours sans synchronisation
   réussie, confirmer que l'app refuse de faire confiance au cache et
   redemande une connexion.

3. **Purge immédiate du cache après révocation ou expiration.** Même
   limite que le point 2 : à vérifier avec un vrai deuxième appareil
   (le professionnel) qui avait un enfant en cache, une fois son accès
   révoqué ou expiré côté parent.

4. **Rendu de l'email de code de vérification dans une vraie
   application mail mobile** (Gmail, Mail iOS, Outlook...). Le contenu
   a été vérifié par un test web (texte reçu, code lisible), mais pas
   son rendu visuel dans un client mail mobile réel.

5. **Partage du lien public (fiche secours / "ce qu'il faut savoir")
   via les mécanismes natifs du téléphone** (SMS, WhatsApp, partage
   natif iOS/Android) et ouverture par un tiers qui n'a pas l'app
   installée, sur son propre téléphone. Le lien lui-même a été testé
   réellement (voir le rapport de la passe 2, round 2), mais pas le
   parcours de partage natif de bout en bout.

6. **Mode Urgence accessible rapidement, y compris depuis l'écran
   verrouillé si un raccourci est prévu.** À vérifier concrètement :
   combien de temps/d'étapes pour un accompagnant stressé pour arriver
   à la fiche secours d'un enfant précis, sur un vrai téléphone.

7. **Autofill / gestionnaire de mots de passe natif** sur les écrans de
   connexion et de création de compte (suggestion automatique du mot de
   passe, remplissage automatique par le gestionnaire de mots de passe
   du téléphone) — jamais testé, le navigateur headless n'en a pas.

8. **Performance de démarrage sur un téléphone d'entrée/moyenne
   gamme.** Le test web release démarre vite, mais rien ne dit qu'une
   compilation native fait de même sur du matériel modeste — à observer
   simplement à l'usage.

## Hors périmètre pour l'instant (pas dans cette liste)

Les notifications push ne sont pas listées ici : décision déjà prise de
les reporter au moment de la préparation de la publication sur les
stores (voir le plan d'espace professionnel), donc pas un sujet pour
cette passe.

## Comment utiliser cette liste

Dès que l'app est installée sur un téléphone réel, reprendre chaque
point un par un. Rien n'a besoin d'être fait avant — l'installation
elle-même n'a pas été lancée pendant cette passe, à la demande de
Fanny.
