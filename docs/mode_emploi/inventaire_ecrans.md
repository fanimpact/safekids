# Inventaire des écrans — besoin d'explication

Établi le 24/08/2026. **75 écrans** parcourus : espace parent, espace
professionnel, et les écrans communs (connexion, présentation).

Objet : décider où poser une explication **sur l'écran lui-même**. Pas
de carrousel, pas d'écran d'aide séparé.

Aucun texte d'explication n'est proposé ici, et aucun écran n'a été
modifié. C'est un état des lieux.

---

## Ce que j'ai trouvé avant d'entrer dans le détail

**Un emplacement d'explication existe déjà, et il est gâché.** Les 18
écrans de questionnaire passent par `widgets/questionnaire_page.dart`,
qui affiche un titre et un **sous-titre**. Sur les 11 écrans du profil
Activités, ce sous-titre vaut « Répondez aux questions concernant votre
enfant. » — la même phrase partout, qui n'apprend rien. Le gisement est
là, prêt à l'emploi.

**Cinq écrans du questionnaire santé n'ont pas de titre du tout.**
`contacts_page`, `diagnosed_pathologies_page`, `medical_events_page`,
`treatments_page` et `trigger_factors_page` passent `title: ""` et ne
gardent que le sous-titre. Le parent ne sait pas où il en est.

**Le déséquilibre est net entre les deux espaces.** Côté parent, les
écrans de partage sont bien expliqués (`create_establishment_link_page`
porte plusieurs paragraphes). Côté professionnel, presque rien : la
plupart des écrans se contentent d'un titre.

**Trois écrans sont déjà des écrans d'explication à part entière** :
`concept_page`, `create_child_profile_intro_page`,
`saved_activities_info_page`. Ils fonctionnent, et montrent le registre
attendu.

---

## Groupe 1 — Explication indispensable

Sans explication, la personne se trompe, abandonne, ou croit avoir
compris alors que non.

### `sharing/create_share_link_page.dart` — « Créer un lien de partage »

**Ce qu'on y fait** : produire un lien à envoyer à un accompagnant.

**Explications présentes** : aucune sur la nature du lien. Uniquement
des messages d'erreur et le texte de partage.

**Pas évident** :
- **le choix du type de fiche** (secours / ce qu'il faut savoir /
  recommandations d'activité) : trois fiches aux contenus très
  différents, aucune ne dit ce qu'elle contient ;
- **le choix du destinataire** (particulier / structure d'accueil) :
  ce choix change la mention accolée aux traitements — « selon le PAI »
  ou « selon les indications du parent ». Rien ne le dit ;
- **la date d'expiration** : ce qui se passe après n'est écrit nulle
  part ;
- **le fait que le lien s'ouvre sans compte**, donc que quiconque le
  reçoit voit la fiche.

**Verdict : oui, et c'est le plus urgent de l'application.** C'est
l'écran où un parent décide ce qu'il transmet sur la santé de son
enfant, et à qui.

### `professional/claim_attachment_page.dart` — « Rattacher un enfant »

**Ce qu'on y fait** : saisir le code transmis par un parent.

**Explications présentes** : « Saisissez le code transmis par le
parent. » et une phrase de contexte.

**Pas évident** : ce que le rattachement donne comme accès, sa durée,
ce que le parent voit de son côté, et ce qui se passe à l'échéance.

**Verdict : oui.** Un professionnel qui ne sait pas ce qu'il obtient ne
saura pas non plus ce qu'il n'a pas le droit de faire.

### `professional/add_activity_note_page.dart` — « Ajouter une note »

**Ce qu'on y fait** : écrire une note sur une activité, éventuellement
rattachée à un enfant.

**Explications présentes** : « Le parent de cet enfant sera notifié par
email… », déjà bien.

**Pas évident** : **qu'une note sans enfant rattaché ne prévient
personne**. C'est un piège exact — le professionnel croit avoir informé
le parent alors que non.

**Verdict : oui.** Une seule phrase manque, mais son absence peut faire
qu'une information importante n'arrive jamais.

### `consentement/consentement_sante_page.dart` — « Votre accord »

**Ce qu'on y fait** : donner le consentement aux données de santé.

**Explications présentes** : trois paragraphes, écrits le 23/08/2026.

**Pas évident** : rien. Il est déjà bien.

**Verdict : oui — et c'est fait.** Repris ici comme référence de
registre pour les autres écrans.

### `settings/settings_page.dart` — « Paramètres »

**Ce qu'on y fait** : mot de passe, adresse de secours, export,
suppression du compte.

**Explications présentes** : bonnes sur les trois sections récentes
(secours, export, suppression).

**Pas évident** : rien dans ces trois-là. En revanche l'écran est
devenu long et sans structure : quatre sujets sans séparation
thématique.

**Verdict : oui, mais pour une raison différente** — ce n'est pas une
explication qui manque, c'est un découpage.

### `sharing/consultation_journal_page.dart` — « Journal de consultation »

**Ce qu'on y fait** : voir qui a consulté la fiche d'un enfant.

**Explications présentes** : **aucune.** Une liste de lignes brutes.

**Pas évident** : tout. Ce qui est journalisé, ce qui ne l'est pas, la
durée de conservation, et surtout — un parent qui voit « fiche secours
— 12/08/2026 à 09h14 » ne sait pas si c'est normal ou alarmant.

**Verdict : oui.** C'est un écran de surveillance sans mode d'emploi.

---

## Groupe 2 — Explication utile

La personne s'en sort, mais plus lentement, ou en se posant une
question qu'on aurait pu éviter.

### Les 11 écrans du profil Activités
`aquatic_activity_page`, `clothing_page`, `communication_page`,
`meals_page`, `other_information_page`, `overnight_stay_page`,
`safety_page`, `toilets_page`, `transitions_page`, `transport_page`,
`walking_effort_page`

**Ce qu'on y fait** : décrire les besoins de l'enfant, section par
section.

**Explications présentes** : le même sous-titre partout — « Répondez
aux questions concernant votre enfant. »

**Pas évident** : **à quoi sert chaque section**. Pourquoi on demande
si l'enfant sait nager, ce que l'application en fera, et sur quelle
fiche cela ressortira. `meals_page` fait exception : elle porte un
encart qui explique pourquoi les allergies ne sont pas redemandées.

**Verdict : oui pour les onze.** Le sous-titre existe, il suffit de
l'utiliser. C'est le meilleur rapport effort/résultat de tout
l'inventaire.

### Les 5 écrans du questionnaire santé sans titre
`contacts_page`, `diagnosed_pathologies_page`, `medical_events_page`,
`treatments_page`, `trigger_factors_page`

**Explications présentes** : un sous-titre sous forme de question
(« Quels sont les traitements actuellement prescrits ? »), plutôt bon.

**Pas évident** : où l'on se situe dans le parcours, et pourquoi cette
question-là. Le titre vide n'aide pas.

**Verdict : oui**, en commençant par remettre un titre.

### `sharing/establishment_attachments_page.dart` — « Mes rattachements »

**Explications présentes** : uniquement dans les confirmations de
révocation.

**Pas évident** : la différence entre un rattachement **en attente**
(code non encore saisi) et **actif**. Et ce que révoquer coupe
exactement.

**Verdict : oui.**

### `professional/team_management_page.dart` — « Gérer l'équipe »

**Pas évident** : les trois rôles (directeur, adjoint, membre) et ce
que chacun permet. Le garde-fou du dernier directeur actif n'apparaît
qu'au moment où on le heurte.

**Verdict : oui.** Trois lignes suffiraient.

### `professional/establishment_child_list_page.dart` — « Enfants rattachés »

**Pas évident** : que la liste ne contient que les enfants dont un
parent a transmis un code, et qu'un enfant en disparaît à l'échéance.

**Verdict : oui.**

### `activity_pages/activity_recommendations_page.dart` — « Recommandations »

**Ce qu'on y fait** : lire les recommandations générées, les masquer,
imprimer, partager.

**Explications présentes** : aucune sur l'écran (beaucoup de
commentaires dans le code, invisibles pour l'utilisateur).

**Pas évident** : **d'où viennent ces recommandations** — elles sont
calculées à partir du profil et des caractéristiques de l'activité,
jamais saisies. Et **ce que masquer veut dire** : geste réversible,
côté professionnel, invisible du parent.

**Verdict : oui.** C'est l'écran qui produit la valeur de
l'application, et rien n'explique comment.

### `emergency_mode/emergency_mode_button_list_page.dart` — « Mode Urgence »

**Explications présentes** : les replis sont bien écrits (« Aucune
consigne particulière renseignée par le parent — appelez les
secours. »).

**Pas évident** : que les consignes affichées ont été **écrites par le
parent**, et n'ont aucune valeur médicale en soi.

**Verdict : oui, mais avec prudence.** Toute explication ajoutée ici
allonge un écran qu'on lit en situation d'urgence. Une ligne, pas
davantage.

### `care_info/care_info_sheet_page.dart` — « Ce qu'il faut savoir sur… »
### `emergency_info/emergency_info_sheet_page.dart` — « Informations essentielles »

**Pas évident** : la différence entre les deux fiches. L'une est pour
les secours, l'autre pour la vie quotidienne — le titre le suggère,
sans le dire.

**Verdict : oui**, une ligne sous le titre.

### `professional/establishment_onboarding_page.dart` — « Créer mon établissement »

**Explications présentes** : « Vous devenez automatiquement directeur
ou directrice… », déjà bien.

**Pas évident** : qu'un établissement ne se supprime pas, et ce qui se
passe si on en crée un par erreur.

**Verdict : utile, pas urgent.**

### `activity_pages/activity_session_start_page.dart` — « Créer une activité »

**Pas évident** : que le **nom** de l'activité ne sert qu'à la
retrouver, et que les recommandations viennent des caractéristiques.
C'est exactement ce que `saved_activities_info_page` explique — mais
sur un autre écran, qu'on ne voit pas forcément avant.

**Verdict : oui**, une ligne qui reprend ce point.

### `sharing/create_establishment_link_page.dart` — « Rattacher à un établissement »

**Explications présentes** : plusieurs paragraphes, les meilleurs de
l'application.

**Verdict : non, sauf relecture.** Cité comme modèle.

---

## Groupe 3 — Se comprennent seuls

Aucune explication à ajouter. Le titre et les champs suffisent.

| Écran | Titre affiché |
|---|---|
| `welcome_page` | (écran de lancement, 2 s) |
| `concept_page` | présentation — **est déjà l'explication** |
| `profile_choice_page` | « Que souhaitez-vous faire ? » |
| `particulier_home_page` | « Espace particulier » |
| `demo_page` | démonstration — **est déjà l'explication** |
| `login_page` | « Se connecter » |
| `register_page` | « Créer un compte » |
| `forgot_password_page` | « Mot de passe oublié » |
| `auth/set_new_password_page` | « Nouveau mot de passe » |
| `auth/device_verification_page` | « Nouvel appareil » |
| `home/home_page` | « Accueil » |
| `children/children_page` | « Mes enfants » |
| `child_profile_pages/create_child_profile_intro_page` | **est déjà l'explication** |
| `transmission_pages/identity_page` | « Identité de l'enfant » |
| `transmission_pages/transition_to_activities_page` | palier — **est déjà l'explication** |
| `activity_profile_pages/activity_profile_entry_page` | redirection, sans interface |
| `activity_pages/activities_home_page` | « Activités » |
| `activity_pages/saved_activities_page` | « Activités enregistrées » |
| `activity_pages/saved_activities_info_page` | **est déjà l'explication** |
| `activity_pages/activity_child_selection_page` | « Quels enfants participeront ? » |
| `activity_pages/activity_session_complete_page` | « Activité complétée » |
| Les 9 `activity_pages/activity_*_page` du questionnaire d'activité | « Eau », « Transport »… — questions explicites |
| `emergency_info/emergency_info_child_picker_page` | choix d'un enfant |
| `emergency_mode/emergency_mode_child_picker_page` | choix d'un enfant |
| `emergency_mode/emergency_mode_instructions_page` | consignes numérotées |
| `professional/professional_emergency_mode_child_picker_page` | choix d'un enfant |
| `professional/professional_entry_page` | « Espace professionnel » |
| `professional/professional_login_page` | connexion |
| `professional/professional_register_page` | création de compte |
| `professional/establishment_home_page` | « Espace professionnel » |
| `professional/professional_child_detail_page` | trois sections déjà légendées |
| `professional/activity_note_page` | « Note sur l'activité » |
| `questionnaire_recap/medical_questionnaire_recap_page` | « Questionnaire santé » |
| `questionnaire_recap/activity_questionnaire_recap_page` | « Profil Activités » |
| `children/child_profile_page` | fiche de l'enfant |
| `suppression/suppression_en_cours_page` | **est déjà l'explication** |

Deux remarques sur ce groupe :

- `child_profile_page` est classé ici pour son **contenu**, mais c'est
  l'écran le plus chargé de l'application : neuf boutons d'action, tous
  du même vert depuis le chantier d'identité visuelle. Le problème y
  est de repérage, pas de compréhension.
- `medical_questionnaire_recap_page` affiche 44 blocs de texte sans
  aucune légende. Il se comprend, mais il se lit mal.

---

## Ce que je ferais, dans cet ordre

1. **Les 11 sous-titres du profil Activités.** Un emplacement qui
   existe, une phrase inutile à remplacer, onze écrans améliorés.
2. **`create_share_link_page`.** Le plus à risque : c'est là qu'on
   décide de transmettre des données de santé.
3. **Les 5 titres manquants du questionnaire santé**, avec leur
   sous-titre revu.
4. **`consultation_journal_page`.** Un écran de surveillance sans mode
   d'emploi ne sert à personne.
5. **Le piège de la note sans enfant**, côté professionnel. Une phrase.
6. **Le reste du groupe 2**, au fil de l'eau.

## Ce que cet inventaire ne couvre pas

- Les **boîtes de dialogue** et les messages transitoires : ils n'ont
  pas été recensés écran par écran.
- Les **messages d'erreur**, qui sont une couche explicative à part
  entière et mériteraient leur propre passe.
- Les **états vides** (« Aucun enfant enregistré… »), qui sont souvent
  le meilleur endroit pour expliquer, et qui sont déjà plutôt bons.
- L'**ordre des écrans** : certaines incompréhensions viennent du
  parcours, pas de l'écran. `saved_activities_info_page` explique une
  chose qu'il aurait fallu dire sur `activity_session_start_page`.
