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

3. **Messages d'erreur de connexion/création de compte, reformulés en
   français clair (19/08/2026).** Écrans concernés : création de
   compte (particulier et professionnel), connexion (particulier et
   professionnel), changement de mot de passe (réglages et lien "mot
   de passe oublié"). À vérifier avec un scénario d'échec réel (ex.
   mauvais mot de passe, email déjà utilisé) : le message affiché doit
   être une phrase compréhensible, plus jamais un texte du type
   `AuthApiException(message: ..., statusCode: ..., code: ...)`.
   Vérifié par un test qui simule plusieurs codes d'erreur Supabase,
   jamais déclenché pour de vrai à l'écran.

4. **"Ce qu'il faut savoir sur..." — nouvelles sections Médecin
   traitant et Antécédents médicaux (19/08/2026).** Ouvrir la fiche
   d'un enfant avec un médecin traitant renseigné et au moins un
   événement médical (antécédent) : les sections "Médecin traitant"
   et les lignes "Antécédent : ..." doivent apparaître, à l'écran et
   dans le PDF exporté. Vérifié par un test, jamais regardé à l'écran
   ni dans un vrai PDF généré.

5. **Fiche secours — médecin référent complet et dispositifs
   permanents distingués (19/08/2026).** Pour Théo (pathologie
   Epilepsie suivie par Dr Cabasson, neurologue au CHU Pau) : la ligne
   du médecin référent doit maintenant afficher la spécialité, le lieu
   d'exercice et le téléphone, pas seulement le nom. S'il a un
   dispositif médical porté en permanence, une section dédiée doit
   apparaître, séparée des dispositifs à emporter. Vérifié par un
   test, jamais regardé à l'écran avec ses vraies données.

6. **Fermeture automatique de la fiche professionnelle après révocation
   (19/08/2026).** À vérifier avec un vrai deuxième appareil/compte
   professionnel : ouvrir la fiche secours (ou une consigne du Mode
   Urgence) d'un enfant, laisser l'écran ouvert, puis révoquer l'accès
   depuis le compte parent. Une fenêtre "Accès révoqué" doit apparaître
   sur l'écran professionnel dans les ~20 secondes, sans action de sa
   part, et ramener à l'accueil une fois validée. Vérifié par un test
   qui simule l'échec réseau (ne doit jamais fermer par erreur), jamais
   testé avec une vraie révocation en conditions réelles.

## Chantier d'abstraction de l'authentification (23/08/2026)

Le 23/08/2026, les 30 appels au SDK Supabase dispersés dans 12 fichiers
ont été regroupés derrière `AuthProvider`. Neuf vérifications manuelles
avaient été listées, faute de tests sur ce câblage.

**Six ont été couvertes par des tests automatisés le 23/08/2026** (39
tests : `auth_translation_test.dart`, `auth_wiring_test.dart`,
`account_separate_account_test.dart`, plus `auth_error_message_test.dart`
déjà existant). Elles sont retirées de cette liste.

Chacun de ces tests a été vérifié **en cassant volontairement le code
qu'il protège**, pour s'assurer qu'il échoue bien — un test de câblage
peut sinon passer pour de mauvaises raisons.

Ce qui reste ci-dessous demande un **vrai appareil, un vrai serveur, ou
un second compte** : aucun test ne peut s'y substituer.

### Priorité haute

1. **Lien « mot de passe oublié » ouvert depuis un vrai mobile
   (23/08/2026).** *La partie logique est désormais testée* — le filtre
   d'évènements et l'ouverture de l'écran de nouveau mot de passe le
   sont, y compris le fait que les autres évènements n'ouvrent rien.

   **Ce qui reste à vérifier ne l'est pas et ne peut pas l'être** : que
   le système d'exploitation ouvre bien l'application sur le lien reçu
   par email, et que Supabase émette réellement l'évènement de
   récupération à ce moment-là. C'est la chaîne email → OS → SDK, hors
   de portée d'un test. À faire depuis un téléphone où l'app est
   installée, en cliquant le lien dans une vraie boîte mail.

2. **Création d'un compte professionnel alors qu'un compte parent est
   connecté, sur un vrai serveur (23/08/2026).** *La décision est
   testée* : déconnexion puis session anonyme neuve avant rattachement,
   dans cet ordre, et l'identité change bien.

   **Ce qui reste** : confirmer contre la vraie base que le compte
   parent conserve effectivement ses enfants après l'opération. Les
   tests s'arrêtent avant l'écriture en base. C'est le scénario qui
   avait fait perdre l'accès à Théo et Noé — il mérite une confirmation
   réelle.

### Priorité moyenne

3. **Créer un lien de partage (23/08/2026).** Une fiche secours, puis
   une fiche de recommandations d'activité : le lien doit s'afficher et
   fonctionner une fois ouvert. L'insertion a changé de fichier — c'était
   le dernier écran à écrire directement en base. Non automatisable :
   demande une écriture réelle dans `partages` et l'ouverture du lien
   servi par l'Edge Function.

4. **Gérer l'équipe (23/08/2026).** Deux cas, deux chemins désormais
   distincts :
   - champ email **vide** → « Saisissez une adresse email. » ;
   - adresse **déjà invitée** → le message du serveur doit s'afficher
     **tel quel**, pas « Une erreur est survenue. ».

   Non automatisable : le second cas exige qu'une fonction RPC lève
   réellement son message, et l'écran charge l'équipe au démarrage.

### Priorité basse

5. **Réglages (23/08/2026).** L'adresse email affichée en haut de
   l'écran, et le changement de mot de passe. La lecture de l'email
   passe par le nouveau fournisseur ; l'écran a besoin d'une session
   réelle pour s'afficher entièrement.

6. **Révocation d'accès, deux cas opposés (23/08/2026).** La requête de
   surveillance a quitté le widget pour rejoindre le dépôt :
   - accès révoqué depuis un autre appareil → la fiche doit se fermer
     dans les ~20 secondes ;
   - **réseau coupé** → elle doit **rester ouverte**.

   Non automatisable en l'état : demande un second appareil, une vraie
   révocation, et le passage du temps. Recoupe le point 6 de la section
   précédente.

### Ce qui n'a plus besoin d'être vérifié à la main

Couvert par des tests depuis le 23/08/2026 :

- **Démarrage à froid sans session** — l'ouverture d'une session
  anonyme, et surtout le fait qu'une session existante n'en déclenche
  pas une seconde (ce qui changerait `auth.uid()` et ferait perdre les
  enfants).
- **Filtre des évènements de session** — les 3 évènements traités
  passent, les 5 autres du SDK sont filtrés, et `passwordRecovery`
  ouvre bien l'écran attendu.
- **Traduction des erreurs d'authentification** — les 8 codes Supabase
  connus donnent le bon message français, de bout en bout, et un code
  inconnu retombe sur un message générique plutôt qu'un message précis
  et faux.
- **Ordre des opérations du compte séparé** — déconnexion avant
  rattachement, et conversion sans déconnexion pour une session
  anonyme.
- **Fiche enfant, droits du propriétaire** — déjà exercé par les tests
  d'écran existants.
- **Empilement d'écrans et fermeture de l'abonnement** — deux
  évènements de récupération n'ouvrent pas deux écrans, et rien ne se
  déclenche après démontage.

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

## Identité visuelle (23/08/2026)

Sept commits ont changé l'apparence de toute l'application sans
toucher à son comportement : palette, polices embarquées, fiches PDF,
page `auth.kidsrelay.fr`. Les tests garantissent que rien ne s'est
cassé — ils ne disent rien de ce que ça donne à l'œil. Ces points-là
ne peuvent être tranchés qu'en usage réel.

1. **Les neuf boutons d'action du profil enfant sont tous en vert
   pin.** Ils avaient chacun leur couleur (bleu, vert, sarcelle,
   indigo, brun, gris-bleu, violet, orange) ; le codage par couleur a
   disparu avec le passage à une palette de cinq teintes. Décision
   prise de garder ainsi pour l'instant.

   **À juger à l'usage** : si l'écran paraît monotone ou si l'on met
   plus de temps à retrouver un bouton connu, on rétablira une
   distinction **avec la sauge et l'ambre uniquement** — pas de retour
   aux neuf couleurs. Le rouge du bouton « Mode Urgence », lui, ne
   bouge pas : c'est sa rareté sur l'écran qui le rend visible.

2. **Lisibilité du texte blanc sur vert pin.** Concerne les barres de
   titre de tous les écrans, les boutons pleins et le bouton
   « Ouvrir l'application » de la page web. Le contraste est
   théoriquement bon (vert pin `#1F4A3F` est sombre), mais à confirmer
   **en plein soleil et sur un écran de téléphone en luminosité
   basse** — c'est là que ça se joue, pas sur un écran d'ordinateur.

3. **Lisibilité du texte sur ambre.** Concerne le bandeau « données
   hors ligne » de l'accueil, l'encart d'erreur de la page
   `auth.kidsrelay.fr`, et le bandeau des sections d'urgence dans les
   PDF. Le texte y est en ardoise sur fond ambre clair `#FBF1DF`, pas
   en ambre plein : c'est délibéré, l'ambre vif sur fond clair passe
   mal. **À vérifier** que le bandeau attire quand même l'œil — c'est
   ce qui remplace le réflexe d'utiliser du rouge, et s'il ne se voit
   pas, il ne sert à rien.

4. **Le rouge doit rester dominant dans le Mode Urgence.** C'est le
   point le plus important de la liste. La règle tenue partout est que
   le rouge `#C0392B` ne sert qu'à l'urgence vitale — sa valeur vient
   entièrement de sa rareté ailleurs.

   **À vérifier écran par écran du Mode Urgence** (choix de l'enfant,
   liste des boutons, consignes) : que le rouge domine visuellement,
   qu'aucun vert pin ni ambre ne lui vole l'attention, et qu'un
   accompagnant qui découvre l'écran comprenne en une seconde qu'il
   n'est plus dans le reste de l'application. Si le vert pin des
   barres de titre affaiblit cet effet, c'est le Mode Urgence qui doit
   gagner.

5. **Les deux polices s'affichent bien sur un vrai téléphone.** Plus
   Jakarta Sans pour les titres, Mulish pour le texte, embarquées dans
   l'application. Sur ordinateur, si un fichier manquait, le système
   remplacerait sans prévenir par une police proche : le défaut ne se
   verrait pas. **À vérifier sur téléphone** que les titres et le
   texte courant ont bien deux dessins différents, et qu'aucun
   caractère accentué ne manque.

6. **Les fiches PDF exportées.** Imprimer ou partager les trois fiches
   (secours, garde, activité) et les deux récapitulatifs de
   questionnaire. **À vérifier** : titres en vert pin, texte lisible à
   l'impression noir et blanc aussi, bandeau rouge présent sur les
   seules sections d'urgence, et **apostrophes courbes correctes**
   (`l’enfant` avec une apostrophe courbe, et non `l'enfant` avec une
   droite) — la conversion en ASCII a été retirée, et un caractère
   absent de la police s'afficherait comme un vide.

7. **L'écran de lancement ne fait plus de saut de couleur.** Il était
   blanc sur Android en mode clair, noir en mode nuit, blanc sur iOS.
   Il est maintenant au lin `#F5F3EF`, comme le fond de
   l'application. **À vérifier au démarrage à froid** (application
   fermée depuis les applications récentes), et en **mode nuit
   activé** sur le téléphone.

8. **La page `auth.kidsrelay.fr` aux nouvelles couleurs.** À ne
   vérifier **qu'après avoir déposé `index.html` chez OVH** — jusque-là
   la page en ligne est encore l'ancienne, en bleu, et
   `verifier-deploiement.mjs` signalera un écart sur ce fichier. Une
   fois déposée : ouvrir un vrai lien reçu par email depuis un
   téléphone, et vérifier que la page ressemble à l'application.

## Export « Mes données » — droit d'accès RGPD (23/08/2026)

Le bouton vit dans **Paramètres → Mes données**. Il produit deux
fichiers en même temps : un PDF lisible et un `.json` réutilisable.

Ce qui suit ne peut être tranché ni par les 69 tests du chantier, ni
par `flutter analyze`.

1. **La feuille de partage avec deux fichiers**, sur un vrai
   téléphone. Android et iOS ne présentent pas la même chose, et
   certaines applications de destination n'acceptent qu'un seul
   fichier — auquel cas il faut savoir laquelle, pour le dire au
   parent. **À vérifier** : que les deux fichiers partent bien
   ensemble vers une boîte mail, et ce qui se passe avec une
   application qui n'en prend qu'un.

2. **Le PDF d'un profil très rempli.** Les tests garantissent que la
   génération ne casse pas ; ils ne disent rien de la mise en page.
   **À vérifier** : que les sauts de page tombent au bon endroit,
   qu'aucun titre de rubrique ne se retrouve seul en bas d'une page,
   et que le document reste lisible imprimé en noir et blanc.

3. **Le PDF de plusieurs enfants.** Chaque enfant démarre sa propre
   page, c'est testé. **À vérifier à l'œil** : qu'on ne puisse pas
   confondre deux enfants en feuilletant — notamment que le prénom
   soit visible sans revenir au début de la section.

4. **Le fichier `.json` ouvert sur un ordinateur.** **À vérifier** :
   qu'il s'ouvre dans un éditeur de texte ordinaire, que les accents
   sont corrects (« Noé » et non « NoÃ© »), et que le `_lisez_moi` en
   tête est compréhensible par quelqu'un qui n'est pas informaticien.

5. **L'absence du bouton pour une personne de confiance.** Demande un
   **second compte**, invité en consultation seule sur la fiche de
   Théo ou de Noé. **À vérifier** : que la section « Mes données »
   affiche la phrase d'explication et aucun bouton. Le comportement
   est testé avec un double, mais la valeur qui décide vient de la
   base — c'est cette chaîne-là qui reste à confirmer en vrai.

6. **Le temps de génération** sur un profil réel. **À vérifier** : que
   « Préparation en cours… » apparaisse assez vite pour qu'on ne croie
   pas à un blocage, et combien de temps l'ensemble prend avec les
   deux profils de test.

7. **Le contenu, relu par vous.** C'est la vérification la plus
   importante et la seule qui ne soit pas technique : **est-ce que
   l'export est réellement complet ?** Ouvrir le PDF et vérifier que
   rien de ce que vous avez saisi sur Théo et Noé n'y manque. Le rendu
   est générique, donc rien ne devrait être omis — mais c'est
   exactement le genre d'affirmation qu'il faut vérifier une fois.

8. **Les intitulés fabriqués.** Un champ absent du dictionnaire de
   `export_libelles.dart` sort quand même, sous un intitulé dérivé de
   son nom technique. **À noter en lisant le PDF** : les intitulés qui
   sonnent faux ou incompréhensibles, pour les ajouter au
   dictionnaire.

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
