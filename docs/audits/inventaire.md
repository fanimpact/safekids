# Inventaire complet de l'application SafeKids

Date : 19/08/2026. Ce document n'est pas un audit : c'est un état des
lieux, écran par écran, de ce qui existe aujourd'hui dans l'application
— ce qu'il contient, ce qui y est incomplet, et ce qui était prévu mais
n'a jamais été construit. Rien n'est corrigé ici. Les bugs déjà
recensés dans les 4 passes d'audit (`docs/audits/corrections_a_faire.md`)
ne sont pas répétés en détail, seulement référencés quand pertinent.

Méthode : lecture exhaustive du code (164 fichiers Dart), organisée par
parcours utilisateur plutôt que par ordre alphabétique de fichier, pour
suivre la façon dont un parent ou un professionnel traverse réellement
l'application.

---

## 1. Vue d'ensemble — ce qui manque au niveau de l'application entière

### Présentation de l'application

- **Aucune mention légale, aucune politique de confidentialité, aucune
  CGU nulle part dans l'application.** Recherche exhaustive dans tout
  `lib/` : zéro occurrence de "mentions légales", "politique de
  confidentialité", "CGU", "conditions générales". Pour une application
  qui traite des données de santé d'enfants, c'est une absence
  structurelle, pas un détail — au-delà de l'aspect légal, c'est aussi
  l'endroit normal où expliquer à un parent ce que l'app fait de ses
  données.
- **Le pitch de l'application existe, mais à un seul endroit et
  incomplet.** `lib/concept_page.dart` porte l'unique explication du
  "à quoi ça sert" avant la création de compte. Le carrousel de
  découverte (`lib/demo_page.dart`) prolonge cette présentation avec 6
  écrans illustrés, mais son bouton final ne mène nulle part (voir
  §3.1) — un visiteur curieux qui va au bout du pitch se retrouve
  bloqué, sans moyen de continuer depuis cet écran.
- **Le texte d'accroche de `create_child_profile_intro_page.dart`
  promet une fonctionnalité qui n'existe pas.** Ce texte annonce qu'un
  abonnement futur permettra "d'inviter jusqu'à deux personnes de
  confiance à gérer les profils de vos enfants" — une fonctionnalité de
  co-parent/tuteur. Cette fonctionnalité n'existe nulle part dans le
  code, et n'apparaît même pas dans le plan de développement de
  l'espace professionnel — elle n'est pas seulement non construite,
  elle n'est planifiée nulle part ailleurs que dans ce texte. Un parent
  qui lit cet écran se voit promettre quelque chose qui n'est ni
  construit ni au programme.
- **Métadonnées de l'application jamais personnalisées** :
  `pubspec.yaml` (`description: "A new Flutter project."`) et
  `web/manifest.json` (même description par défaut) portent encore le
  texte générique de création d'un projet Flutter. Le titre de l'onglet
  web est juste "safekids" en minuscules, sans description.

### Design et présentation des pages

- **Icône de l'application : jamais remplacée, sur aucune plateforme.**
  Vérifié directement : `web/icons/Icon-512.png` et
  `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` sont tous les
  deux le logo Flutter par défaut (le triangle bleu à trois teintes).
  Ni le web ni Android n'ont d'icône SafeKids — c'est ce qu'un
  utilisateur verrait sur son écran d'accueil ou dans son navigateur.
  Non vérifié côté iOS (dossier `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  présent mais son contenu réel n'a pas été inspecté).
- **Style visuel cohérent mais sans identité de marque forte.** Palette
  Material bleu/rouge (rouge réservé aux actions d'urgence), cartes
  arrondies, mise en page fonctionnelle et propre sur tous les écrans
  testés — mais rien qui distingue visuellement SafeKids d'une
  application Material générique, en dehors des 6 illustrations du
  carrousel de découverte.
- **États vides et de chargement inégaux d'un écran à l'autre.**
  Exemples concrets trouvés : `EstablishmentAttachmentsPage` (mes
  rattachements) a un état de chargement en simple roue qui tourne,
  sans squelette, un état d'erreur en texte plat sans bouton "réessayer" ;
  `ChildrenPage` a un véritable état vide travaillé (icône + texte +
  bouton d'action) ; d'autres écrans n'ont pas été vérifiés
  spécifiquement sur ce point mais le contraste entre ces deux exemples
  suggère une attention inégale, pas une norme appliquée partout.

### Illustrations

- **Six images au total dans toute l'application**, situées dans
  `lib/assets/story_1.png.png` à `story_6.png.png`, et utilisées à un
  seul endroit visible : le carrousel `demo_page.dart`. Les mêmes 6
  images étaient à l'origine prévues pour la chaîne d'écrans `story_*`
  aujourd'hui morte (voir §5) — `demo_page.dart` les réutilise avec le
  bon chemin, la chaîne morte a un chemin cassé qui n'aurait de toute
  façon jamais fonctionné. Aucune illustration nulle part ailleurs dans
  l'app : pas sur les écrans de questionnaire, pas sur les états vides,
  pas sur les écrans professionnels. Tout le reste du contenu visuel
  est composé d'icônes Material et de texte.

### Textes d'aide

- **Concentrés sur quelques écrans d'introduction, absents du
  questionnaire lui-même.** Les écrans d'intro
  (`create_child_profile_intro_page.dart`,
  `transition_to_activities_page.dart`, `saved_activities_info_page.dart`)
  portent des paragraphes explicatifs conséquents. En revanche, aucune
  des ~30 pages de questionnaire (santé + activités) n'a d'icône d'aide
  contextuelle, de tooltip, ou d'exemple systématique sur les questions
  elles-mêmes — quelques champs "détail libre" ont un texte d'exemple
  en indice (ex. "Bouchons d'oreilles..."), mais ce n'est pas
  systématique. Un parent qui hésite sur le sens d'une question n'a nulle
  part où trouver une explication supplémentaire sans quitter l'écran.
- **Messages d'erreur techniques exposés à l'utilisateur, sur tous les
  écrans d'authentification, pas seulement l'inscription.** Déjà noté
  pour l'inscription (`corrections_a_faire.md` item 10), mais le même
  motif existe aussi sur `login_page.dart`
  ("Connexion refusée : $error"), `register_page.dart`
  ("Impossible de créer le compte : $error"), et
  `set_new_password_page.dart`
  ("Impossible de mettre à jour le mot de passe : $error") — un
  problème de fond sur l'ensemble des écrans de compte, pas un cas
  isolé.

---

## 2. Écrans côté parent

### 2.1 Découverte et entrée dans l'application

**`welcome_page.dart`** — écran de démarrage, 2 secondes, texte
"Bienvenue dans SafeKids" fixe, redirige automatiquement vers
`ConceptPage`. Aucune interaction possible, aucun manque identifié.

**`concept_page.dart`** — page de présentation du concept : icône,
titre, un paragraphe explicatif, bouton "Continuer" vers
`ProfileChoicePage`. Complet, statique.

**`profile_choice_page.dart`** — choix "Professionnel" / "Particulier".
Écran de routage simple, complet.

**`particulier_home_page.dart`** — menu d'entrée côté parent :
"Découvrir ce que SafeKids peut faire" (→ carrousel), "Créer un
compte", "Se connecter". **Sous ces trois boutons, une section "Outils
de développement" non protégée s'affiche dans le build de production**
(déjà signalé passe 4, `corrections_a_faire.md` item 15) — deux
boutons ouvrant les vrais formulaires de production sans contexte
d'enfant.

**`demo_page.dart`** — carrousel de 6 diapositives illustrées.
**Le bouton final ("Créer gratuitement la fiche de mon enfant") ne
fait rien** (déjà signalé passe 4, item 14) — c'est un cul-de-sac,
aucune navigation nulle part, ni vers l'inscription ni vers la création
de profil.

### 2.2 Authentification

**`login_page.dart`** — email + mot de passe, gestion de spinner,
"Mot de passe oublié ?", "Créer un compte". Fonctionnel, réellement
branché sur Supabase (`AccountService.signIn`), vérifie la
reconnaissance de l'appareil et route vers `HomePage` ou
`DeviceVerificationPage`. Incomplet : message d'erreur technique brut
exposé à l'utilisateur (voir §1).

**`register_page.dart`** — email + mot de passe + confirmation,
validation client (longueur, correspondance). Convertit la session
anonyme existante en compte réel (`AccountService.createAccount`),
conforme au plan initial. Pas de case à cocher de consentement/CGU
(cohérent avec l'absence de CGU relevée en §1). Message d'erreur brut
également exposé.

**`forgot_password_page.dart`** — email, envoi du lien de
réinitialisation, message de confirmation volontairement identique
que l'adresse existe ou non (anti-énumération). Complet, pas de
manque identifié.

**`lib/auth/device_verification_page.dart`** — code à 6 chiffres reçu
par email, réutilisé par les parcours parent et professionnel. Pas
d'affichage du temps restant avant expiration (annoncé "valable 10
minutes" dans le texte, mais aucun compte à rebours visible). Message
d'erreur générique quelle que soit la cause réelle du refus.

**`lib/auth/set_new_password_page.dart`** — nouveau mot de passe après
clic sur le lien reçu par email, atteint via un lien profond. Complet,
même motif de message d'erreur brut.

**`lib/auth/account_service.dart`** (service commun aux comptes parent
et professionnel) — gère création de compte, connexion, déconnexion,
reconnaissance d'appareil, demande/vérification de code, réinitialisation
de mot de passe. **Ce qui manque structurellement** : aucune méthode de
suppression de compte (distincte de la suppression d'un profil
enfant) ; aucun écran pour lister ou révoquer les appareils reconnus
d'un compte (la table `appareils_reconnus` existe côté base, mais rien
côté client n'expose "voir mes appareils" ou "déconnecter cet
appareil") ; pas de fusion de comptes si un parent crée un second
compte avec un email déjà utilisé ailleurs (décision déjà actée comme
hors périmètre).

### 2.3 Accueil et menu

**`lib/home/home_page.dart`** — écran d'accueil principal une fois
connecté. Bandeau hors-ligne conditionnel, boutons "Mode Urgence" /
"Préparer une activité" / "Informations pour les secours", bouton
"Menu" ouvrant une feuille avec 5 entrées : "Mes enfants", "Créer un
lien de partage", "Rattacher à un établissement", "Mes rattachements
établissement", **"Paramètres" (n'ouvre aucun écran, juste un message
"sera créé à l'étape suivante" — déjà signalé passe 4, item 16)**.

Incohérence relevée : les boutons "Mode Urgence" et "Informations pour
les secours" vérifient s'il existe au moins un enfant avant de
naviguer (sinon message d'invite à créer un profil) ; le bouton
"Préparer une activité" ne fait pas cette vérification.

### 2.4 Profil enfant : liste et fiche

**`lib/children/children_page.dart`** ("Mes enfants") — liste des
enfants avec état vide travaillé (icône + texte + bouton), une carte
par enfant (nom, résumé santé, statut de complétion des deux
questionnaires). Incohérence relevée : le premier enfant créé passe
par l'écran d'introduction explicatif
(`CreateChildProfileIntroPage`) ; les enfants suivants, créés via
"Créer un autre profil enfant", sautent directement au questionnaire
sans cette explication.

**`lib/children/child_profile_page.dart`** — écran central d'un
enfant : pathologies/allergies en résumé, 5 actions d'usage (préparer
une activité, mode urgence, fiche secours, récapitulatifs santé et
activités), accès à "Ce qu'il faut savoir sur...", statut de
complétion, section modification, section gestion (suppression).

**Trouvé pendant cet inventaire — un manque important, jamais signalé
avant** : la section "Partages" de cet écran affiche en permanence
"Aucun partage actif" avec un texte statique, et un appui dessus
affiche seulement "La gestion des partages sera ajoutée prochainement."
Cette section ne lit aucune donnée réelle et ne mène nulle part —
alors que les vrais écrans de partage et de rattachement
(`CreateShareLinkPage`, `CreateEstablishmentLinkPage`,
`EstablishmentAttachmentsPage`) existent et fonctionnent réellement,
mais uniquement accessibles depuis le Menu de l'accueil, jamais depuis
cette fiche enfant. Un parent qui cherche "à qui ai-je partagé le
profil de cet enfant précis" depuis sa fiche tombe sur un message
trompeur qui suggère qu'aucun partage n'existe, même s'il y en a.

Le bouton "Supprimer le profil" de cette page est fonctionnel (point
précisé par Fanny, voir `corrections_a_faire.md` item 2, clos).

**`lib/child_profile_pages/create_child_profile_intro_page.dart`** —
écran d'explication avant le premier questionnaire. Contient le texte
sur l'abonnement et l'invitation de "deux personnes de confiance" déjà
signalé en §1.

### 2.5 Questionnaire santé ("informations essentielles")

Sept écrans en `lib/transmission_pages/`, dans l'ordre : identité,
pathologies diagnostiquées, événements médicaux, facteurs
déclenchants, traitements, contacts, puis transition vers le profil
activités.

**`identity_page.dart`** — prénom, nom, date de naissance, taille,
poids, date de mesure conditionnelle. Aucune validation avant de
continuer (contrairement à tout le reste du questionnaire) : un parent
peut passer à l'étape suivante avec tous les champs vides. Un champ du
modèle (`hasDiagnosedPathologies`) a toute sa logique de mise à jour
écrite dans le contrôleur mais n'est jamais appelé depuis cet écran ni
aucun autre — code mort, sans effet aujourd'hui.

**`diagnosed_pathologies_page.dart`** — pathologies et allergies
répétables, avec professionnel référent optionnel et consignes
d'urgence numérotées par item. Validation correcte, complet.

**`medical_events_page.dart`** — événements médicaux et observations
médicales répétables, médecin traitant. **Seule page du questionnaire
sans aucune validation avant de continuer**, et son `initState`
insère automatiquement une entrée vide dans chaque liste dès l'arrivée
sur la page — un parent peut traverser cet écran sans répondre à rien,
et une entrée vide reste enregistrée silencieusement. Conséquence
concrète : le texte de repli "Aucun événement médical renseigné." du
récapitulatif ne peut quasiment jamais s'afficher en pratique, puisque
la liste n'est jamais vraiment vide une fois la page visitée.

**`trigger_factors_page.dart`** — 8 questions oui/non à plat (lumières
clignotantes, chaleur, fatigue, bruit, foule, espaces confinés, effort
physique, stress) plus 3 blocs structurés (eau, animaux, hauteur) et un
champ "autre". Validation correcte. Un champ du modèle
(`hasTriggerFactors`) a toute une logique de question-filtre avec
effacement en cascade des réponses écrite dans le contrôleur, mais
jamais utilisée par cette page, qui pose chaque question à plat sans
filtre — code mort, vestige d'une approche différente jamais
supprimée.

**`treatments_page.dart`** — 4 filtres indépendants (traitements
réguliers, arrêtés, d'urgence, dispositifs médicaux), chacun avec ses
propres entrées répétables et liaison aux pathologies/allergies
déclarées. Validation correcte, complet. Une classe de modèle
orpheline découverte pendant cette lecture : `lib/models/treatment_data.dart`
(`TreatmentData`) n'est utilisée nulle part dans l'application, remplacée
par les classes réellement utilisées (`DailyTreatmentData`,
`EmergencyTreatmentData`, `DiscontinuedTreatmentData`) — reliquat
d'une version antérieure du modèle.

**`contacts_page.dart`** — 2 contacts pré-remplis (parents), contacts
supplémentaires possibles. **Le champ `isPrimaryContact` du modèle
n'est jamais réglable depuis cet écran** — aucune case à cocher
"contact principal" n'existe. Ce champ est pourtant utilisé ailleurs
dans l'application (fiche secours et "Ce qu'il faut savoir" trient les
contacts par `isPrimaryContact`) : en pratique, ce tri ne peut jamais
s'appliquer pour un vrai utilisateur, seules les données de démo
définissent ce champ à `true`.

**`transition_to_activities_page.dart`** — écran de transition/
confirmation après la fin du questionnaire santé, propose de continuer
vers le profil activités ou de s'arrêter là. Complet, pas de manque.

### 2.6 Questionnaire profil activités

Onze écrans en `lib/activity_profile_pages/`.

**`activity_profile_entry_page.dart`** — son nom suggère un écran
d'accueil du questionnaire, mais c'est en réalité un simple relais qui
affiche directement la première vraie page (`AquaticActivityPage`) —
pas de sommaire, pas de vue de progression.

**`aquatic_activity_page.dart`** — gilet de flottaison, adulte dédié,
équipement spécial, surveillance adaptée, autre adaptation. Deux
facteurs déclenchants venant du profil santé sont traités de façon
asymétrique : "risque de se jeter dans l'eau" génère seulement une
note informative sans question de suivi, alors que "ne sait pas nager"
génère la même note **et** déclenche une vraie question sur le gilet
de flottaison — pas documenté comme volontaire, à confirmer si c'est
voulu.

**`transport_page.dart`** — mal des transports par mode de transport,
médicament associé, équipement et attention particulière. Validation
complète, bien couplée au moteur de recommandations (correction
documentée du 19/08 empêchant un "oui" sans aucun mode coché).

**`overnight_stay_page.dart`** — dispositif utilisé la nuit (référencé
depuis les dispositifs déjà déclarés côté santé, pas resaisi), besoin
d'électricité, criticité d'une coupure, supervision nocturne adaptée.
Complet. Petite incohérence de forme : le champ de détail de la
supervision nocturne n'a pas de limite de caractères ni de texte
d'exemple, contrairement aux champs de détail équivalents sur presque
toutes les autres pages.

**`communication_page.dart`** et **`transitions_page.dart`** —
conservent volontairement une question-filtre (décision actée) qui
conditionne l'affichage des sous-questions. Complets, comportement
voulu, pas un manque.

**`safety_page.dart`** — risque de quitter le groupe brusquement,
équipement de sécurité. Complet.

**`walking_effort_page.dart`** — deux questions oui/non à plat, sans
aucun champ de détail — la section la plus sommaire du questionnaire
activités : impossible de préciser la nature de la vigilance
nécessaire.

**`clothing_page.dart`** et **`toilets_page.dart`** — une seule
question oui/non chacune, aucun champ de détail. Cohérent avec un
modèle de données qui ne prévoit qu'un seul champ pour ces deux
sections — pas un manque, juste des sections volontairement minimales.

**`other_information_page.dart`** — jusqu'à 4 champs de texte libre
progressifs, avertissement sur le matériel à fournir par le parent.
Dernière étape du questionnaire, sauvegarde le profil activités
complet. Deux corrections déjà documentées et closes le 19/08 (garde
de validation manquante, présélection involontaire de "Non").

### 2.7 Récapitulatifs

**`lib/questionnaire_recap/medical_questionnaire_recap_page.dart`** —
récapitulatif imprimable/partageable du questionnaire santé complet.
**Deux manques concrets trouvés** : les consignes d'urgence numérotées
par pathologie/allergie (bien saisies dans le questionnaire) n'apparaissent
jamais dans ce récapitulatif ; les liaisons traitement ↔ pathologie/allergie
(cochées dans le questionnaire) non plus. Le commentaire du code de cet
écran affirme pourtant couvrir "chaque question posée" — ce n'est pas
exact en l'état.

**`lib/questionnaire_recap/activity_questionnaire_recap_page.dart`** —
équivalent pour le profil activités. Vérifié champ par champ contre le
modèle de données : **aucun manque trouvé**, tous les champs sont
représentés.

### 2.8 Préparation d'activité

**`lib/activity_pages/activities_home_page.dart`** — menu d'entrée
(préparer une activité / activités enregistrées), réutilisé tel quel
côté professionnel.

Questionnaire en 7 étapes (`activity_session_start_page.dart` puis eau,
marche/effort, transport, nuitée, sécurité, facteurs déclenchants,
habillage) — parcours linéaire complet, sans manque identifié.

**`activity_session_complete_page.dart`** — écran de routage après le
questionnaire, différent selon parent ou professionnel et selon
création ou modification d'une activité existante. Complet.

**`activity_child_selection_page.dart`** — sélection des enfants
concernés, "Tout sélectionner"/"Tout désélectionner". Généralisé pour
servir aussi bien le parcours parent que professionnel.

**`activity_recommendations_page.dart`** (1885 lignes, l'écran le plus
riche de l'application) — récapitulatif de l'activité, section
"Points importants", recommandations groupées par situation,
médicaments d'urgence, matériel à prévoir, et — **uniquement côté
professionnel** — une section "Notes complémentaires" avec ajout de
note. Impression/export PDF présent. Menu d'édition (enfants
concernés, caractéristiques de l'activité) réservé au professionnel.
Masquage individuel des recommandations non critiques réservé au
professionnel. Rien d'incomplet trouvé dans ce qui est implémenté.

**`saved_activities_page.dart`** / **`saved_activities_info_page.dart`** —
liste des activités réellement sauvegardées en base (le manque de
persistance identifié dans le plan initial est comblé), recalcul des
recommandations en direct à la réouverture. Le bouton flottant
"Préparer une activité" de cette page fait un simple retour en
arrière plutôt qu'une navigation directe — fonctionnel mais indirect.

### 2.9 Mode Urgence, fiche secours, "Ce qu'il faut savoir"

**`emergency_mode_child_picker_page.dart`** → **`emergency_mode_button_list_page.dart`**
→ **`emergency_mode_instructions_page.dart`** — un bouton par
pathologie/allergie avec consignes enregistrées, plus un bouton
générique "Autre urgence". Purement d'affichage, aucun appel réseau,
complet. Réutilisé tel quel côté professionnel.

**`emergency_info_child_picker_page.dart`** → **`emergency_info_sheet_page.dart`**
(fiche secours) — inclut désormais les consignes d'urgence numérotées
(correction du 19/08, déjà testée réellement en passe 2/3). Complet.

**`care_info_sheet_page.dart`** ("Ce qu'il faut savoir sur...") — pensé
pour un accompagnant sur plusieurs jours, ordre de priorité documenté
dans le code. Complet, aucun manque trouvé lors de cette lecture.

### 2.10 Partage et rattachement

**`create_share_link_page.dart`** (lien ponctuel anonyme, mécanisme
préexistant à l'espace professionnel) — limité à 2 types de fiche
partageable (secours, ce qu'il faut savoir). **Le code contient un
commentaire expliquant qu'un 3e type ("recommandations d'activité")
n'est pas proposé faute de persistance des activités — ce commentaire
est aujourd'hui dépassé**, puisque la persistance des activités côté
parent a depuis été construite (§2.8, confirmé aussi en passe 3) : la
raison invoquée pour ne pas proposer ce type de partage n'existe plus,
mais l'écran n'a pas été mis à jour en conséquence.

**`create_establishment_link_page.dart`** — génération du code de
rattachement à durée obligatoire, conforme au plan. Complet.

**`establishment_attachments_page.dart`** — liste des rattachements
par enfant avec révocation, conforme au plan. États de chargement/erreur
sommaires (voir §1).

---

## 3. Écrans côté professionnel

### 3.1 Entrée et authentification

**`professional_entry_page.dart`**, **`professional_login_page.dart`**,
**`professional_register_page.dart`** — parcours de connexion/inscription
réel, branché sur le même `AccountService` que le côté parent, avec
garde explicite contre l'écrasement d'une session parent existante
(bug réel déjà corrigé par le passé, documenté dans le code). Complet.

### 3.2 Création d'établissement

**`establishment_onboarding_page.dart`** — nom + type d'établissement,
devient automatiquement directeur. **Le texte de l'écran promet
"vous pourrez ensuite inviter votre équipe" — aucun écran d'invitation
n'existe** (voir §3.6 ci-dessous).

### 3.3 Accueil et menu établissement

**`establishment_home_page.dart`** — 3 tuiles (préparer une activité,
mode urgence, fiche secours et données de l'enfant), conforme au plan.
Un seul établissement par compte pour l'instant, par choix documenté
dans le code ("l'écran de choix entre plusieurs établissements viendra
si besoin") — pas un manque, une limitation assumée en l'état actuel.

### 3.4 Trombinoscope et fiche enfant

**`establishment_child_list_page.dart`** — liste des enfants
rattachés, bandeau hors-ligne. Complet.

**`professional_child_detail_page.dart`** — 3 tuiles (fiche secours,
ce qu'il faut savoir, profil activités), chaque ouverture journalise la
consultation (RGPD, vérifié réellement en passe 3). Pas de section
notes ici (déplacée vers le parcours de préparation d'activité, par
choix documenté). Complet.

**`professional_emergency_mode_child_picker_page.dart`** — équivalent
du sélecteur parent, sourcé depuis le trombinoscope de l'établissement.
Complet.

### 3.5 Rattacher un enfant

**`claim_attachment_page.dart`** — saisie du code reçu du parent,
réclamation réelle. Complet.

### 3.6 Ce qui manque structurellement côté professionnel

**Aucune fonctionnalité de gestion d'équipe n'existe.** Recherche
exhaustive dans les 14 fichiers de `lib/professional/` et dans
`establishment_service.dart` : aucun écran, aucun bouton, aucune
méthode de service ne permet d'inviter un collègue, de nommer ou
retirer un adjoint, ou de révoquer l'accès d'un membre de l'équipe
(à distinguer de la révocation d'un enfant, qui elle fonctionne, côté
parent). La colonne `role` existe déjà en base
(`directeur`/`adjoint`/`membre`) avec un commentaire explicite "prêts
pour la phase 3, même si..." et `establishment_service.dart` précise
lui-même "phase 2 ne crée que des directeurs, les autres rôles arrivent
en phase 3." C'est une phase entière du plan initial (rôles et
invitations) qui n'a jamais démarré, cohérent avec le fait qu'elle
n'apparaît pas dans la liste des phases livrées. Le texte de
`establishment_onboarding_page.dart` qui promet "vous pourrez ensuite
inviter votre équipe" anticipe une fonctionnalité qui n'a pas encore
été construite.

**Écran du journal de consultation : toujours absent, par choix déjà
acté.** Seuls l'écriture (`professional_child_repository.dart`) et le
point d'appel (`professional_child_detail_page.dart`) existent ; aucun
écran ne permet de le consulter — cohérent avec la décision explicite
de ne pas construire cet écran tant qu'un besoin réel ne se présente
pas (§9 du plan). Pas un manque non anticipé.

**Notifications push : aucune trace de code, comme prévu.** Aucun
paquet, aucun fichier lié aux notifications push nulle part dans le
projet. La table `evenements_notification_parent` a une colonne
`statut_push` valant par défaut littéralement "non_branché", avec un
commentaire du code confirmant que c'est volontaire (reporté au moment
de la publication sur les stores). Conforme à la décision déjà prise.

**Abonnement/paiement : juste un drapeau, jamais utilisé côté
client.** Aucune occurrence de `abonnement_active` dans le code Dart
(seulement dans le schéma SQL), aucun paquet de paiement dans le
projet, aucun écran ne vérifie ce drapeau. Conforme à la décision déjà
actée ("hors périmètre pour cette étape").

**Notifications d'expiration de rattachement (7 jours avant échéance)
: jamais construites.** Confirmé en listant les Edge Functions
déployées (`consulter-partage`, `envoyer-code-verification`,
`notifier-note-ajoutee`, `verifier-code`, `voir-partage`) : aucune ne
gère l'expiration. Aucune tâche planifiée ne l'envoie non plus. C'est
la dernière étape du plan initial jamais commencée (elle était prévue
en toute fin d'ordre de construction).

---

## 4. Écrans et code inaccessibles depuis aucun écran

Confirmé indépendamment pour chacun (recherche du nom de la classe
dans tout `lib/`, aucune application ne définissant de routes nommées
— donc cette recherche est une vérification complète, pas partielle) :

| Fichier(s) | Constat |
|---|---|
| `lib/create_child_profile_page.dart` | Écran mort, remplacé par `CreateChildProfileIntroPage` → `IdentityPage`. Contient lui-même un menu déroulant et un bouton "Continuer" non fonctionnels. |
| `lib/story_child_intro_page.dart`, `story_activity_page.dart`, `story_emergency_page.dart`, `story_transmission_page.dart`, `story_end_page.dart` | Chaîne de 5 écrans entièrement morte, ancienne version du carrousel de découverte remplacée par `demo_page.dart`. Contient un bouton portant le même texte trompeur que le carrousel actuel ("Créer gratuitement la fiche de mon enfant"), qui ne fait que fermer les écrans sans rien créer. Chemins d'images cassés en plus. |
| `lib/main.dart:114-138` | Classe `HomePage` dupliquée, jamais instanciée — tous les vrais appels utilisent la bonne classe (`lib/home/home_page.dart`). Purement cosmétique. |
| `lib/activity_pages/new_activity_page.dart` | Écran mort, ancienne version de `ActivitySessionStartPage`. |
| `lib/activity_pages/activity_characteristics_page.dart` | Écran mort, seul appelant étant lui-même l'écran mort ci-dessus. Son propre bouton "Continuer" est un message d'attente sans suite ("sera ajoutée à l'étape suivante") — cul-de-sac même s'il était atteint. |
| `lib/models/treatment_data.dart` | Classe de modèle orpheline, jamais utilisée, remplacée par `DailyTreatmentData`/`EmergencyTreatmentData`/`DiscontinuedTreatmentData`. |

Recommandation implicite pour plus tard (pas une action à prendre
maintenant) : ces six éléments sont candidats à la suppression plutôt
qu'à la correction, puisqu'ils ne sont accessibles depuis nulle part.

---

## 5. Champs de données jamais montrés à l'écran

Trouvés en comparant systématiquement chaque écran de questionnaire à
son modèle de données sous-jacent :

- `IdentityData.hasDiagnosedPathologies` — a une méthode de mise à
  jour complète dans le contrôleur, jamais appelée par aucun écran.
- `TriggerFactorData.hasTriggerFactors` — a toute une logique de
  question-filtre avec effacement en cascade écrite dans le
  contrôleur, jamais utilisée par l'écran des facteurs déclenchants.
- `ContactData.isPrimaryContact` — aucune case à cocher pour le régler
  sur l'écran des contacts, alors que la fiche secours et "Ce qu'il
  faut savoir" trient les contacts par ce champ (le tri ne peut donc
  jamais s'appliquer pour un vrai utilisateur, seules les données de
  démonstration en tirent parti).
- Consignes d'urgence par pathologie/allergie, et liaisons
  traitement ↔ pathologie/allergie — saisies dans le questionnaire,
  absentes du récapitulatif santé imprimable (§2.7).

---

## Note méthodologique

Ce document a été construit par lecture exhaustive du code (recherche
déléguée en parallèle sur trois zones de l'application, puis synthèse
et vérifications croisées personnelles — notamment l'icône de
l'application, les métadonnées, l'absence de mentions légales), sans
test en conditions réelles cette fois (ce n'était pas l'objet d'un
état des lieux). Les constats des 4 passes d'audit précédentes ne sont
pas reproduits ici en détail, sauf quand ils éclairent directement un
écran décrit — se référer à `docs/audits/corrections_a_faire.md` pour
la liste complète des corrections déjà actées.
