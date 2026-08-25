# À vérifier sur un vrai appareil

Liste vivante, remplace `2026-08-19-passe-3-a-verifier-sur-mobile.md`
(conservé pour l'historique, plus mis à jour). Tout ce qui demande un
œil humain, un vrai téléphone, un second compte ou le passage du temps
— et que ni les tests automatisés ni l'audit de code ne peuvent
couvrir.

Rien ici n'est un bug confirmé : ce sont des points à confirmer.
Aucun n'est retiré avant que Fanny confirme elle-même l'avoir vérifié.

**Refondu le 25/08/2026** : numérotation continue, priorité et
résultat attendu pour chaque point, en vue d'une session unique sur un
appareil Android.

- **70 points** au total.
- **Priorité haute : 14** — à faire en premier, ce sont ceux dont
  l'échec aurait des conséquences réelles.
- **Priorité moyenne : 33**.
- **Priorité basse : 20**.

---

# Ce qu'il faut préparer avant

À faire **avant** d'avoir l'appareil, pour ne pas perdre la session à
de l'installation.

## A. Construire l'APK

```
flutter build apk --release
```

Le fichier sort dans `build/app/outputs/flutter-apk/app-release.apk`
(une trentaine de Mo). Compter dix à quinze minutes la première fois.

Cet APK est **signé avec la clé de débogage** : Android l'installera,
mais il ne pourra jamais être publié ni mis à jour par le Play Store.
C'est sans importance pour des tests ; à refaire proprement au moment
de la publication.

## B. Le transférer sur l'appareil

Le plus simple, sans câble : envoyez-vous l'APK par email à vous-même,
ouvrez la pièce jointe depuis le téléphone. Android demandera
d'autoriser l'installation d'applications de source inconnue — c'est
attendu, une seule fois.

Par câble, si vous préférez : `adb install app-release.apk` (nécessite
d'activer le mode développeur sur le téléphone, sept appuis sur le
numéro de build dans les réglages).

## C. Les comptes à créer d'avance

Cinq comptes sont nécessaires, avec des adresses email **réelles et
distinctes** — chacune doit pouvoir recevoir du courrier, plusieurs
points en dépendent.

| Compte | Rôle dans les tests | Sert aux points |
|---|---|---|
| **Le vôtre** (parent principal) | Théo et Noé, déjà en place | presque tous |
| **Personne de confiance** | invitée sur Théo en consultation seule | 11, 12, 22, 23, 24, 25 |
| **Professionnel n° 1** | directeur d'un établissement de test | 6, 7, 13, 15, 19, 20, 26 à 29, 43 |
| **Professionnel n° 2** | membre de la même équipe | 13, 26, 27, 28, 29 |
| **Destinataire d'un lien** | quelqu'un sans compte KidsRelay | 17, 40 |

Un compte Gmail accepte les adresses `votreadresse+test1@gmail.com` :
elles arrivent toutes dans la même boîte, et Supabase les traite comme
distinctes. C'est la façon la plus rapide d'en avoir cinq.

## D. Un établissement de test

Créez-le depuis le compte professionnel n° 1 **avant la session**, et
rattachez-y Théo par un code depuis votre compte parent. Sans cela,
tous les points professionnels sont bloqués dès le départ.

Nommez-le clairement (« Établissement de test ») : un établissement
ne se supprime pas.

## E. Un second appareil

Plusieurs points demandent deux appareils en même temps : révocation
d'accès vue en direct, ouverture d'un lien par un tiers, cache
hors-ligne. Votre téléphone actuel fera le second — c'est justement
pour cela que l'Android d'occasion sert.

## F. Ce qui n'est pas encore en place

- **SPF / DKIM / DMARC sur `kidsrelay.fr`** : sans eux, les emails
  partiront en indésirables et les points 2, 30 et 39 seront faussés.
  À faire avant la session si possible.
- **`index.html` d'`auth.kidsrelay.fr` chez OVH** : sans dépôt, le
  point 44 ne peut pas être fait.

---

# Priorité haute

## 1. Compte professionnel créé alors qu'un compte parent est connecté
*Authentification, 23/08/2026 · deux comptes*

La décision est testée : déconnexion puis session anonyme neuve avant
rattachement, dans cet ordre, et l'identité change bien. Les tests
s'arrêtent avant l'écriture en base.

C'est le scénario qui avait **fait perdre l'accès à Théo et Noé**.

**Attendu** : après création du compte professionnel, se reconnecter
au compte parent — Théo et Noé sont toujours là, avec leurs profils
complets.

## 2. Lien « mot de passe oublié » ouvert depuis un vrai mobile
*Authentification, 23/08/2026*

La partie logique est testée. Ce qui reste ne peut pas l'être : que le
système d'exploitation ouvre l'application sur le lien reçu par email,
et que Supabase émette l'évènement de récupération à ce moment-là.

**Attendu** : cliquer le lien depuis une vraie boîte mail sur le
téléphone ouvre KidsRelay directement sur l'écran « Nouveau mot de
passe ». Pas le navigateur, pas l'accueil.

## 3. L'annulation d'une suppression de compte restaure tout
*Conformité RGPD, 24/08/2026 · compte de test uniquement*

Le test le plus important du lot RGPD. Un délai de grâce qui ne
restaure pas serait pire qu'une suppression immédiate.

**Attendu** : après demande de suppression puis annulation, tout est
revenu — profils des enfants, liens de partage, rattachements aux
établissements, activités préparées. Rien ne manque.

## 4. Le compte devenu inaccessible l'est vraiment
*Conformité RGPD, 24/08/2026 · compte de test uniquement*

**Attendu** : après la demande, se déconnecter puis se reconnecter
mène à l'écran d'annulation **et rien d'autre**. Pas de menu, pas de
bouton retour, aucune fiche consultable. **Le Mode Urgence n'est plus
atteignable non plus** — c'est volontaire, mais il faut le voir de ses
yeux avant de laisser cela en production.

## 5. Le Mode Urgence ne ralentit jamais
*Compteurs d'usage, 24/08/2026*

La garantie la plus importante du lot des compteurs.

**Attendu** : téléphone en mode avion, le Mode Urgence s'ouvre
**instantanément**, sans le moindre délai perceptible. Si vous sentez
une hésitation, c'est un défaut.

## 6. Fermeture automatique de la fiche après révocation
*Correction du 19/08/2026 · deux appareils*

**Attendu** : le professionnel a la fiche secours ouverte ; le parent
révoque depuis son appareil. Dans les ~20 secondes, une fenêtre
« Accès révoqué » apparaît côté professionnel sans qu'il touche à
rien, et le ramène à l'accueil une fois validée.

## 7. Réseau coupé, la fiche reste ouverte
*Authentification, 23/08/2026 · le revers du point 6*

**Attendu** : couper le réseau du téléphone professionnel pendant
qu'une fiche est ouverte. Elle doit **rester ouverte**. Une fermeture
sur simple perte de réseau serait un défaut grave — un accompagnant
perdrait la fiche au pire moment.

## 8. Le rouge reste dominant dans le Mode Urgence
*Identité visuelle, 23/08/2026*

La règle tenue partout : le rouge `#C0392B` ne sert qu'à l'urgence
vitale, et sa valeur vient de sa rareté ailleurs.

**Attendu**, écran par écran (choix de l'enfant, liste des boutons,
consignes) : le rouge domine visuellement, aucun vert pin ni ambre ne
lui vole l'attention, et un accompagnant qui découvre l'écran comprend
en une seconde qu'il n'est plus dans le reste de l'application. Si le
vert pin des barres de titre affaiblit cet effet, **c'est le Mode
Urgence qui doit gagner**.

## 9. Le Mode Urgence est atteignable vite
*Passe 3*

**Attendu** : comptez les étapes et le temps, pour un accompagnant
stressé, entre l'écran verrouillé et la consigne d'urgence d'un enfant
précis. Notez le chiffre — c'est lui qui dira si le parcours est
acceptable.

## 10. Le blocage d'un compte supprimé tient côté base
*Conformité RGPD, 24/08/2026 · SQL Editor*

L'écran ne protège rien de qui contournerait l'application. Le vrai
blocage est le RLS.

**Attendu** : demander la suppression sur un compte de test, puis lire
`enfants` depuis le SQL Editor en se faisant passer pour ce compte
(`set request.jwt.claims`). **Aucune ligne ne doit sortir.**

## 11. Une personne de confiance en consultation seule ne peut rien modifier
*Co-parent, 19/08/2026 · deux comptes*

**Attendu** : invitée avec le niveau « Consultation seule » (par
défaut), elle voit la fiche — pathologies, allergies, profil
activités, Mode Urgence — mais **aucun bouton de modification ni de
suppression**, et **ni la section Partages ni la section Personnes de
confiance** ne lui apparaissent.

## 12. Une révocation de personne de confiance coupe immédiatement
*Co-parent, 19/08/2026 · deux comptes*

**Attendu** : après révocation depuis le compte parent, la personne
révoquée ne voit plus la fiche dès l'actualisation suivante. Pas au
prochain démarrage — tout de suite.

## 13. Le garde-fou du dernier directeur tient
*Gestion d'équipe, 19/08/2026 · deux comptes professionnels*

**Attendu** : tenter de révoquer ou de rétrograder le **dernier**
directeur ou adjoint actif de l'établissement. Un message d'erreur
clair doit apparaître — **pas un plantage**, pas un silence, et
surtout pas une réussite.

## 14. Le contenu de l'export RGPD, relu par vous
*Export « Mes données », 23/08/2026*

La vérification la plus importante de ce lot, et la seule qui ne soit
pas technique.

**Attendu** : ouvrir le PDF exporté et vérifier que **rien** de ce que
vous avez saisi sur Théo et Noé n'y manque. Le rendu est générique,
donc rien ne devrait être omis — c'est exactement le genre
d'affirmation qu'il faut vérifier une fois.

---

# Priorité moyenne

## 15. Journal des consultations, avec de vraies données
*Correction du 19/08/2026*

**Attendu** : fiche d'un enfant → Traçabilité → Journal des
consultations. Chaque consultation par un établissement rattaché
apparaît avec le nom de l'établissement, la fiche consultée, la date
et l'heure — la plus récente en premier.

## 16. Les deux origines se distinguent dans la traçabilité
*Lien de partage, 25/08/2026 · deux appareils*

Le point de la correction : jusqu'ici seules les consultations
d'établissement y figuraient.

**Attendu** : dans le même écran, deux sortes de lignes cohabitent et
se distinguent d'un coup d'œil —
« **Ouverture d'un lien de partage** » avec une icône de maillon, et
le **nom de l'établissement** avec une icône d'œil. Provoquez les deux
avant de regarder.

## 17. Le rendu de la page publique avec les données réduites
*Lien de partage, 25/08/2026 · appareil sans l'application*

La minimisation est vérifiée côté serveur (voir
[`../migration/minimisation_partage.md`](../migration/minimisation_partage.md)),
mais la page n'a pas été ouverte dans un vrai navigateur depuis.

**Attendu**, sur les trois types de fiche : la page s'affiche
complètement, aucune section n'est vide ni tronquée, et rien n'a
disparu de ce qui doit être lu. En particulier — **la fiche secours
montre bien les consignes d'urgence et le médecin traitant**, et
« Ce qu'il faut savoir » ne les montre pas.

## 18. Deux ouvertures d'un même lien font deux lignes
*Lien de partage, 25/08/2026*

**Attendu** : ouvrir le même lien deux fois, puis Traçabilité — deux
lignes distinctes, avec deux horaires. L'ancienne date unique était
écrasée.

## 19. Purge du cache après révocation ou expiration
*Passe 3 · deux appareils*

**Attendu** : le professionnel avait un enfant en cache ; le parent
révoque. Les fiches de cet enfant disparaissent de l'appareil
professionnel, y compris hors ligne.

## 20. Cache hors-ligne côté professionnel, en vrai
*Passe 3 · deux appareils, et du temps*

**Attendu** : réseau coupé, les fiches déjà en cache restent lisibles.
Au-delà de 7 jours sans synchronisation réussie, l'application refuse
le cache et redemande une connexion.

## 21. Confiance de l'appareil dans la durée
*Passe 3 · plusieurs jours*

**Attendu** : se connecter une fois, saisir le code de vérification,
fermer complètement l'application, la rouvrir plusieurs heures ou
plusieurs jours après — **le code n'est pas redemandé** tant que c'est
le même appareil.

## 22. Absence du bouton d'export pour une personne de confiance
*Export RGPD, 23/08/2026 · deux comptes*

**Attendu** : depuis le compte de la personne de confiance,
Paramètres → Mes données affiche la phrase d'explication et
**aucun bouton**. Le comportement est testé avec un double ; c'est la
valeur venue de la base qui reste à confirmer.

## 23. Une personne de confiance passée en modification peut modifier
*Co-parent, 19/08/2026 · deux comptes*

**Attendu** : après passage au niveau « Consultation et
modification », elle peut ajouter une allergie — et cette
modification apparaît **aussi côté parent**.

## 24. La limite de deux personnes de confiance par enfant
*Co-parent, 19/08/2026*

**Attendu** : la troisième invitation sur le même enfant est refusée,
avec un message clair.

## 25. Deux enfants, deux invitations indépendantes
*Co-parent, 19/08/2026*

**Attendu** : inviter la même personne sur Théo et sur Noé, puis
révoquer sur l'un — l'accès à l'autre reste intact.

## 26. Un membre simple ne gère pas l'équipe
*Gestion d'équipe, 19/08/2026 · deux comptes professionnels*

**Attendu** : un compte avec le rôle « Membre » voit l'équipe mais
n'a **aucune action de gestion** — pas de bouton inviter, changer de
rôle, ni révoquer.

## 27. Nommer un adjoint lui ouvre la gestion
*Gestion d'équipe, 19/08/2026*

**Attendu** : après passage du membre à « Adjoint(e) » depuis un
compte directeur, il peut lui-même inviter et révoquer quelqu'un.

## 28. Révoquer un membre coupe son accès au trombinoscope
*Gestion d'équipe, 19/08/2026*

**Attendu** : immédiatement après révocation, le membre n'accède plus
au trombinoscope de l'établissement.

## 29. Inviter un collègue par email
*Gestion d'équipe, 19/08/2026 · deux comptes professionnels*

**Attendu** : le collègue invité avec le rôle « Membre » apparaît dans
l'équipe une fois connecté avec cette adresse.

## 30. L'email de demande de suppression de compte
*Conformité RGPD, 24/08/2026 · compte de test*

**Attendu** : il arrive (voir la préparation, point SPF/DKIM), il
porte la **bonne date d'effacement**, et le moyen d'annuler est
compréhensible sans être informaticien. C'est le seul endroit où cette
date sort de l'application.

## 31. L'écran de consentement apparaît pour un deuxième enfant
*Conformité RGPD, 24/08/2026*

Le chemin « ajouter un enfant » sautait la page d'introduction ; il
passe maintenant par le consentement.

**Attendu** : l'écran apparaît, l'enchaînement reste fluide, et le
bouton « Continuer » reste inerte tant que la case n'est pas cochée.

## 32. Le consentement n'apparaît jamais en modification
*Conformité RGPD, 24/08/2026*

**Attendu** : ouvrir la fiche de Théo, modifier son poids —
**aucune case n'est redemandée**.

## 33. Les compteurs ne comptent qu'une fois par famille
*Conformité RGPD, 24/08/2026 · SQL Editor*

**Attendu** : après avoir préparé **deux** activités depuis le même
compte, `select mois, fonctionnalite, count(*) from marqueurs_usage
group by 1,2;` rend **1**, pas 2.

## 34. L'adresse de secours ressort dans l'export
*Conformité RGPD, 24/08/2026*

**Attendu** : enregistrer une adresse de secours, puis exporter — elle
figure dans le PDF **et** dans le `.json`.

## 35. Le bouton « Générer le lien » est grisé à l'ouverture
*Lien de partage, 25/08/2026*

**Attendu** : à l'ouverture de l'écran, **aucune des trois fiches
n'est cochée** et le bouton est inactif. La fiche secours était
pré-cochée, et c'est la plus sensible.

## 36. La date d'expiration annoncée est juste
*Lien de partage, 25/08/2026*

**Attendu** : la date s'affiche sous le choix de durée, se met à jour
quand on change de durée, et correspond bien à l'heure réelle plus
24 h / 3 j / 7 j.

## 37. La feuille de partage avec deux fichiers
*Export RGPD, 23/08/2026*

**Attendu** : les deux fichiers (PDF et `.json`) partent **ensemble**
vers une boîte mail. Notez ce qui se passe avec une application qui
n'en accepte qu'un — il faudra le dire au parent.

## 38. Le PDF d'un profil très rempli
*Export RGPD, 23/08/2026*

**Attendu** : les sauts de page tombent au bon endroit, aucun titre de
rubrique ne se retrouve seul en bas d'une page, et le document reste
lisible imprimé en noir et blanc.

## 39. Rendu de l'email de code de vérification
*Passe 3 · vraie application mail*

**Attendu** : dans Gmail, Mail iOS ou Outlook sur mobile, le code est
lisible et la mise en page tient. Testé en web, jamais dans un client
mobile.

## 40. Partage d'un lien par les mécanismes natifs
*Passe 3 · deux appareils*

**Attendu** : partager le lien par SMS, WhatsApp ou le partage natif,
puis l'ouvrir depuis un téléphone **sans l'application installée**. La
fiche s'affiche.

## 41. Messages d'erreur de connexion en français clair
*Correction du 19/08/2026*

**Attendu** : provoquer un échec réel (mauvais mot de passe, email
déjà utilisé) sur les cinq écrans concernés. Le message est une phrase
compréhensible — **jamais** un texte du type
`AuthApiException(message: ..., statusCode: ...)`.

## 42. Créer un lien de partage de bout en bout
*Authentification, 23/08/2026*

**Attendu** : une fiche secours puis une fiche de recommandations
d'activité. Le lien s'affiche et fonctionne une fois ouvert.
L'insertion a changé de fichier — c'était le dernier écran à écrire
directement en base.

## 43. Gérer l'équipe : les deux messages d'erreur
*Authentification, 23/08/2026*

**Attendu** : champ email vide → « Saisissez une adresse email. » ;
adresse déjà invitée → le message du serveur **tel quel**, pas « Une
erreur est survenue. ».

## 44. La page `auth.kidsrelay.fr` aux nouvelles couleurs
*Identité visuelle, 23/08/2026 · après dépôt chez OVH*

**Ne peut pas être fait** tant qu'`index.html` n'est pas déposé —
jusque-là la page en ligne est l'ancienne, en bleu.

**Attendu** une fois déposée : ouvrir un vrai lien reçu par email
depuis le téléphone, la page ressemble à l'application.

## 45. Les deux polices s'affichent sur un vrai téléphone
*Identité visuelle, 23/08/2026*

Sur ordinateur, un fichier manquant serait remplacé sans prévenir par
une police proche : le défaut ne se verrait pas.

**Attendu** : les titres (Plus Jakarta Sans) et le texte courant
(Mulish) ont **deux dessins visiblement différents**, et aucun
caractère accentué ne manque.

## 46. Les fiches PDF exportées
*Identité visuelle, 23/08/2026*

**Attendu**, sur les trois fiches et les deux récapitulatifs : titres
en vert pin, texte lisible aussi à l'impression noir et blanc, bandeau
rouge présent sur les **seules** sections d'urgence, et **apostrophes
courbes correctes** (`l’enfant`, pas `l'enfant`) — la conversion en
ASCII a été retirée, un caractère absent de la police s'afficherait
comme un vide.

## 47. Mode Urgence — dose affichée sous la bonne étape
*Correction du 19/08/2026*

**Attendu** : Théo → Mode Urgence → « Urgence liée à : Epilepsie ».
Sous l'étape 6 (« Au bout de 5 min administrer BUCCOLAM dans la
joue »), un bloc bien visible affiche « BUCCOLAM — 1 seringue — crise
plus de 5 min — dans la bouche (joue) ».

---

# Priorité basse

## 48. Le PDF de plusieurs enfants
*Export RGPD, 23/08/2026*

**Attendu** : on ne peut pas confondre deux enfants en feuilletant —
le prénom reste visible sans revenir au début de la section.

## 49. Le fichier `.json` ouvert sur un ordinateur
*Export RGPD, 23/08/2026 · sur PC*

**Attendu** : il s'ouvre dans un éditeur de texte ordinaire, les
accents sont corrects (« Noé » et non « NoÃ© »), et le `_lisez_moi` en
tête est compréhensible par quelqu'un qui n'est pas informaticien.

## 50. Le temps de génération de l'export
*Export RGPD, 23/08/2026*

**Attendu** : « Préparation en cours… » apparaît assez vite pour qu'on
ne croie pas à un blocage. Notez la durée totale avec les deux profils.

## 51. Les intitulés fabriqués de l'export
*Export RGPD, 23/08/2026*

Un champ absent du dictionnaire sort quand même, sous un intitulé
dérivé de son nom technique.

**Attendu** : notez en lisant le PDF les intitulés qui sonnent faux ou
sont incompréhensibles, pour les ajouter au dictionnaire.

## 52. Les neuf boutons du profil enfant, tous en vert pin
*Identité visuelle, 23/08/2026 · à juger à l'usage*

**Attendu** : si l'écran paraît monotone, ou si vous mettez plus de
temps à retrouver un bouton connu, on rétablira une distinction
**avec la sauge et l'ambre uniquement** — pas de retour aux neuf
couleurs. Le rouge du bouton « Mode Urgence » ne bouge pas.

## 53. Lisibilité du texte blanc sur vert pin
*Identité visuelle, 23/08/2026*

**Attendu** : lisible **en plein soleil** et **en luminosité basse**.
C'est là que ça se joue, pas sur un écran d'ordinateur.

## 54. Lisibilité du texte sur ambre
*Identité visuelle, 23/08/2026*

Le texte y est en ardoise sur fond ambre clair, pas en ambre plein :
c'est délibéré.

**Attendu** : le bandeau **attire quand même l'œil**. C'est ce qui
remplace le réflexe d'utiliser du rouge — s'il ne se voit pas, il ne
sert à rien.

## 55. L'écran de lancement ne saute plus de couleur
*Identité visuelle, 23/08/2026*

**Attendu** : au démarrage à froid (application fermée depuis les
applications récentes), et **en mode nuit activé**, l'écran de
lancement est au lin `#F5F3EF` — pas de flash blanc ni noir avant
l'application.

## 56. Réglages : email affiché et changement de mot de passe
*Authentification, 23/08/2026*

**Attendu** : l'adresse email affichée en haut de l'écran est la
bonne, et le changement de mot de passe fonctionne avec une session
réelle.

## 57. Autofill et gestionnaire de mots de passe natif
*Passe 3*

**Attendu** : sur les écrans de connexion et de création de compte, le
gestionnaire du téléphone propose d'enregistrer puis de remplir. Le
navigateur headless des tests n'en a pas.

## 58. Performance de démarrage sur du matériel modeste
*Passe 3*

**Attendu** : simplement observer. Un Android d'occasion est
précisément le bon banc d'essai.

## 59. « Ce qu'il faut savoir » — médecin traitant et antécédents
*Correction du 19/08/2026*

**Attendu** : sur un enfant avec un médecin traitant et au moins un
événement médical, les sections « Médecin traitant » et les lignes
« Antécédent : … » apparaissent — à l'écran **et** dans le PDF.

## 60. Fiche secours — médecin référent complet
*Correction du 19/08/2026*

**Attendu** : pour Théo (Epilepsie suivie par Dr Cabasson, neurologue
au CHU de Pau), la ligne du médecin référent affiche **spécialité,
lieu d'exercice et téléphone**, pas seulement le nom. Un dispositif
porté en permanence apparaît dans une section séparée de ceux à
emporter.

## 61. Une fiche de recommandations d'activité dans la traçabilité
*Lien de partage, 25/08/2026*

Ce type manquait à la contrainte SQL et au libellé.

**Attendu** : après ouverture d'un lien de ce type, la ligne apparaît
avec le libellé « Recommandations d'activité » — pas un code
technique, pas une ligne vide.

## 62. L'effacement définitif au bout de 7 jours
*Conformité RGPD, 24/08/2026 · compte de test uniquement*

Ne se vérifie qu'en attendant, ou en avançant
`suppression_effective_le` à la main dans la base.

**Attendu** : au passage de la tâche de 4h, la ligne `auth.users`
disparaît et tout ce qui en dépend avec.
**Ne pas faire sur Théo ou Noé.**

## 63. La consolidation mensuelle des compteurs
*Conformité RGPD, 24/08/2026 · SQL Editor*

Ne se voit qu'au 1er du mois, ou en appelant
`select public.consolider_compteurs_usage();` à la main.

**Attendu** : après quoi `marqueurs_usage` et `sels_usage` sont vides
pour le mois consolidé, et `compteurs_usage` porte un entier.

## 64. L'adresse de secours refuse un format invalide
*Conformité RGPD, 24/08/2026*

**Attendu** : une saisie sans arobase est refusée ; une adresse
inhabituelle mais valide (`prenom.nom+kidsrelay@…`) est acceptée.


## 65. La longueur de l'écran de création d'un lien
*Lien de partage, 25/08/2026 · à juger à l'usage*

L'écran a gagné trois sous-titres longs et un encart ambre avec les
explications du 25/08/2026. Il compte maintenant cinq sections, et sur
un petit téléphone le bouton « Générer le lien » se retrouve loin sous
la ligne de flottaison.

**Attendu** : jugez si le parcours reste supportable — combien de
défilement entre l'ouverture de l'écran et le bouton, et si l'on perd
le fil en chemin.

**Solution de repli si c'est pénible** : n'afficher le sous-titre que
sous la **fiche sélectionnée**, les deux autres restant réduites à leur
intitulé. Le texte reste disponible au moment où il sert — quand on
hésite entre deux fiches, on les coche tour à tour — mais l'écran
retrouve sa hauteur.

Ce qu'il ne faut **pas** faire : raccourcir les textes. Ils disent ce
qu'on vient de décider qu'il fallait dire.


## 66. La longueur des en-têtes de questionnaire
*Couche explicative, 25/08/2026 · à juger à l'usage*

Chaque écran du profil Activités a gagné un sous-titre propre et une
ligne de consigne, là où il n'y avait qu'une phrase courte. L'en-tête
prend deux à trois lignes de plus, avant la première question.

**Attendu** : sur un petit écran, jugez s'il faut faire défiler avant
d'atteindre la première question, et si cela devient pénible sur onze
écrans d'affilée.

**Solution de repli si c'est le cas** : la consigne (« Toutes les
questions oui / non sont à renseigner ») n'a besoin d'apparaître que
sur le **premier** écran du parcours — le régime ne change pas ensuite.
Les sous-titres, eux, ne se raccourcissent pas : ils disent ce qu'on
vient de décider qu'il fallait dire.

## 67. La numérotation « sur 11 » suppose un parcours fixe
*Couche explicative, 25/08/2026 · veille, pas vérification*

« Étape 9 sur 11 » est exact aujourd'hui : les onze écrans du profil
Activités sont toujours parcourus dans le même ordre, aucun n'est
sauté, et aucune question filtre ne raccourcit le parcours depuis la
correction du 19/08/2026. Le questionnaire santé, de même, fait
toujours six écrans.

**À revérifier** le jour où une question filtre est ajoutée, ou un
écran rendu conditionnel : le compteur mentirait, et il mentirait
silencieusement — aucun test ne peut le détecter, puisque le total est
écrit en dur dans chaque écran.

**Ce n'est pas une vérification à faire sur l'appareil** : c'est une
note pour le jour où le parcours changera.

## 68. La reprise d'un questionnaire commencé
*Brouillon de questionnaire, 25/08/2026 · priorité haute*

Le vrai test, celui qu'aucun test automatique ne fait : commencer le
questionnaire santé d'un enfant, s'arrêter au troisième ou quatrième
écran, **tuer l'application** (pas seulement la mettre en arrière-plan
— la faire glisser hors de la liste des applications récentes), la
rouvrir, aller dans « Mes enfants ».

**Attendu** : une carte ambre « Reprendre le profil de Théo, commencé
le 25/08 », avec dessous « Ce profil n'est pas encore enregistré.
Terminez le questionnaire pour qu'il le soit. » En la touchant, le
questionnaire repart **au premier écran**, avec les réponses déjà
saisies pré-remplies — c'est délibéré : le parent relit ce qu'il avait
répondu.

Refaire la même chose sur le profil Activités, à partir d'un enfant
déjà enregistré : la ligne « Profil Activités : à compléter » de sa
carte devient un bouton de reprise.

**Ce qui serait un défaut** : la carte n'apparaît pas ; ou elle
apparaît mais les réponses sont vides ; ou le prénom manque alors
qu'il avait été saisi.

## 69. Le brouillon disparaît quand le questionnaire va au bout
*Brouillon de questionnaire, 25/08/2026 · priorité haute*

Terminer un questionnaire santé jusqu'à l'enregistrement de l'enfant,
puis revenir sur « Mes enfants ».

**Attendu** : l'enfant apparaît dans la liste, et **aucune carte
ambre** ne subsiste à côté. Un brouillon qui survivrait à la
validation ferait croire au parent qu'il lui reste du travail, et
laisserait des données de santé sur l'appareil sans raison.

Même chose au bout du profil Activités : le bouton de reprise doit
avoir disparu de la carte de l'enfant.

## 70. Un brouillon abandonné 30 jours
*Brouillon de questionnaire, 25/08/2026 · priorité basse · demande du temps*

Un questionnaire commencé et laissé de côté est effacé de l'appareil
au bout de 30 jours — il contient des pathologies, des allergies et
des traitements, il n'a pas à y rester indéfiniment. La règle et le
tri sont testés ; ce qui ne l'est pas, c'est le passage réel du temps
sur un vrai téléphone.

**Attendu**, si l'occasion se présente : la carte ambre a disparu
d'elle-même, sans que rien n'ait été touché.

**Raccourci possible** : avancer la date de l'appareil de 31 jours,
puis rouvrir « Mes enfants ». À faire sur l'appareil de test
uniquement.

---

# Ce qui n'a plus besoin d'être vérifié à la main

**Couvert par des tests depuis le 23/08/2026** — démarrage à froid
sans session, filtre des évènements de session, traduction des erreurs
d'authentification, ordre des opérations du compte séparé, droits du
propriétaire sur la fiche enfant, empilement d'écrans et fermeture de
l'abonnement. Chacun de ces tests a été vérifié en cassant
volontairement le code qu'il protège.

**Vérifié en production le 25/08/2026** — la minimisation des données
envoyées par un lien de partage. Faite sur trois liens réels de Théo,
un par type de fiche : aucune fuite. Elle se contrôle en lisant la
réponse du serveur sur ordinateur, pas à l'œil sur un téléphone. Voir
[`../migration/minimisation_partage.md`](../migration/minimisation_partage.md).

---

# Hors périmètre

Les notifications push : décision prise de les reporter au moment de
la préparation de la publication sur les stores.

# Comment utiliser cette liste

Dans l'ordre des priorités, pas dans l'ordre des numéros. Un point
vérifié et confirmé bon peut être supprimé ou marqué comme tel — à la
discrétion de Fanny.

Les points qui demandent **deux appareils ou deux comptes** : 1, 6, 7,
11, 12, 13, 16, 17, 18, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 40, 43.

Les points qui demandent le **SQL Editor** : 10, 33, 62, 63.

Les points qui demandent **du temps** (jours) : 20, 21, 62, 70.
