# Audit KidsRelay — Passe 2/4 : Moteur de recommandations

**Date** : 19/08/2026
**Méthode** : lecture exhaustive et croisée de chaque champ des profils santé et activités contre (a) les 14 fichiers de règles, (b) la fiche secours, (c) "Ce qu'il faut savoir sur...", (d) le récapitulatif du profil activités — déléguée à deux recherches en parallèle (une par profil), puis les deux constats les plus sévères revérifiés personnellement par lecture directe du code. Complétée par une vérification indépendante du mécanisme de criticité/masquage (construit cette session, donc déjà bien connu).
**Statut** : en attente de validation avant la passe 3.

## Résumé

- **1 bug de présélection confirmé**, vérifié personnellement — le même problème corrigé deux fois ailleurs dans l'app, jamais appliqué à la dernière page du questionnaire activités.
- **1 recommandation dupliquée confirmée**, vérifiée personnellement — "effort physique" peut apparaître deux fois sur la même fiche.
- **6 recommandations manquantes** : des données saisies par le parent qui ne produisent jamais de recommandation, dans certaines conditions plausibles.
- **7 incohérences** entre la fiche de recommandations, la fiche secours et "Ce qu'il faut savoir sur...".
- **1 lot de champs morts** (jamais lus, jamais vrais) à nettoyer.
- **14/14 recommandations critiques confirmées non masquables** partout — moteur, écran professionnel, PDF — y compris dans un cas limite qu'aucun test ne couvrait encore.

## 1. Bug de présélection — dernière page du questionnaire activités

**Vérifié personnellement, pas seulement par la recherche déléguée.**

`lib/models/other_information_data.dart:2` déclare `bool hasOtherInformation` (non nullable, défaut `false`) — pas `bool?` comme partout ailleurs après les corrections du 16/08. `lib/activity_profile_pages/other_information_page.dart:25,51-52` reprend cette valeur directement dans un `late bool` non nullable, passé tel quel à `SkYesNoField`. Résultat : la question *"Y a-t-il une autre information importante... ?"* s'affiche avec **"Non" présélectionné** dès l'ouverture de la page.

Plus grave : `_finish()` (lignes 256-315) ne bloque jamais sur une question sans réponse — contrairement à **toutes** les autres pages du même questionnaire (habillage, toilettes, transitions, sécurité...), qui empêchent "Continuer" tant que le champ est `null`. Un parent peut donc terminer tout le questionnaire sans jamais toucher cette question, et l'app enregistre silencieusement "Non" — c'est-à-dire "il n'y a rien d'autre d'important à signaler".

C'est exactement le même défaut corrigé le 16/08 dans les commits `d0cb2f9` et `85e71b1`/`7a60abf` — ni l'un ni l'autre ne touche ce fichier. C'est la seule page du questionnaire où ce nettoyage n'a jamais été fait.

## 2. Recommandation dupliquée — "effort physique"

**Vérifié personnellement, pas seulement par la recherche déléguée.**

Deux règles distinctes, déclenchées par la même condition d'activité (`activity.hasSignificantPhysicalEffort == true`), à partir de deux champs différents du profil :

- `environment_rules.dart` (profil santé, facteur déclenchant `physicalEffort`) → id `trigger_physical_effort_vigilance`, texte *"Effort physique signalé comme facteur déclenchant : vigilance particulière."*, **critique**.
- `walking_effort_rules.dart` (profil activités, `intensePhysicalEffortRequiresVigilance`) → id `intense_physical_effort_vigilance`, texte *"Effort physique intense : vigilance particulière."*, non critique.

Si un parent a répondu "oui" aux deux questions (plausible — ce sont deux questionnaires différents demandant conceptuellement la même chose), les deux textes apparaissent l'un sous l'autre sur la fiche : la déduplication du moteur (`recommendation_engine.dart:185-199`) ne fonctionne que par identifiant, pas par contenu, donc ne rattrape rien ici. Fait notable : le code contient déjà, ailleurs (`water_rules.dart:33-38`), un commentaire explicite expliquant pourquoi une règle voisine évite délibérément ce genre de doublon — la même précaution n'a pas été prise ici.

## 3. Recommandations manquantes

Données saisies par le parent qui ne produisent jamais de recommandation dans des cas plausibles :

1. **Mal des transports sans mode de transport coché.** La page transport ne bloque pas "Continuer" si le parent répond "oui" au mal des transports mais ne coche aucun mode concerné — la règle ne lit que la liste des modes, jamais le "oui" global. Le récapitulatif affiche pourtant la réponse "oui".
2. **Allergie ou pathologie sans traitement d'urgence lié.** Le moteur ne lit ces données QUE via les traitements d'urgence qui les référencent, pour construire une précision entre parenthèses. Une allergie ou pathologie sans traitement lié (allergie légère, pathologie ne nécessitant pas de traitement de secours) n'apparaît dans aucune recommandation, alors qu'elle est bien affichée sur les deux fiches.
3. **Dispositif médical utilisé seulement le jour.** La seule règle qui lit `medicalDevices` est celle de la nuitée (`overnight_stay_rules.dart`) — un dispositif nécessaire en journée, non lié à un usage nocturne, ne génère jamais de rappel, quelle que soit l'activité.
4. **Alimentation électrique nécessaire, mais coupure jugée "non critique" ou non renseignée.** La recommandation nuitée sur l'alimentation de secours exige `requiresElectricity` ET `powerFailureIsCritical` ET la question "coupure possible ?" sur l'activité. Si `powerFailureIsCritical` est à "non" ou jamais répondu, rien n'est généré — pas même un simple rappel "l'appareil a besoin d'électricité".
5. **Condition d'administration d'un traitement d'urgence, jamais reprise dans le rappel.** `EmergencyTreatmentData.administrationCondition` (dans quelle situation donner le traitement) est affiché sur les deux fiches mais jamais lu par `emergency_medication_rules.dart` — le rappel "pensez à emporter" ne mentionne que le nom et le dosage, jamais la condition d'utilisation.
6. **Consignes d'urgence détaillées, absentes de la fiche secours.** `PathologyData.emergencyInstructionSteps` et `AllergyData.emergencyInstructionSteps` (les étapes numérotées écrites par le parent) n'existent que dans le Mode Urgence interactif — la fiche secours, censée être imprimable/transmissible à quelqu'un qui découvre l'enfant, ne les montre jamais. C'est le constat le plus sérieux de cette passe : ce sont potentiellement les informations les plus utiles en urgence, absentes du seul document pensé pour être remis à un tiers.

## 4. Incohérences entre les trois destinations

1. **"Prévenir le maître-nageur" disparaît justement quand il n'y a pas de maître-nageur prévu.** La règle n'affiche cette recommandation que si l'activité a déjà un maître-nageur (`swimmingSupervisedByLifeguard == true`) — dans le cas contraire (pas de surveillance prévue), rien ne prévient que l'enfant en aurait justement besoin. "Ce qu'il faut savoir" montre pourtant ce besoin sans condition.
2. **Toilettes vs habillage, deux besoins similaires traités différemment.** L'assistance aux toilettes s'affiche sur **toute** activité, sans condition. L'assistance à l'habillage n'apparaît que si l'activité a explicitement coché "changement de tenue nécessaire" — une sortie imprévue (accident, météo) sans cette case cochée ne déclenchera aucun rappel d'assistance à l'habillage.
3. **Communication : le récapitulatif distingue deux faits, la recommandation les fusionne.** Le parent peut cocher séparément "peut donner l'impression d'avoir compris" et "vérifier individuellement" — le récapitulatif les affiche comme deux lignes distinctes, la règle les fusionne en une seule phrase générique ("Vérifier sa compréhension"), perdant la nuance.
4. **Un commentaire du code revendique une source unique de texte qui n'existe pas réellement.** `environment_rules.dart:104-109` affirme que ses méthodes sont "utilisées par la fiche Ce qu'il faut savoir... plutôt que de dupliquer ces textes à un second endroit" — en réalité, ni la fiche secours ni "Ce qu'il faut savoir" n'appellent ce code : les deux réécrivent leurs propres textes en dur, avec des formulations qui ont déjà dérivé (hauteur, animaux, eau, photosensibilité — sens préservé, mais les mots diffèrent, et rien ne garantit qu'ils resteront alignés).
5. **Médecin traitant, antécédents médicaux et observations : sur la fiche secours, absents de "Ce qu'il faut savoir".** Cette dernière fiche est pourtant explicitement pensée (commentaire du code) pour un accompagnant qui garde l'enfant plusieurs jours (ex. grands-parents) — un profil qui aurait plausiblement besoin du contact du médecin traitant en cas de problème non urgent.
6. **Spécialité, lieu d'exercice et téléphone du médecin référent d'une pathologie : saisis, jamais affichés nulle part**, ni sur l'une ni sur l'autre fiche (seul le nom apparaît, sur "Ce qu'il faut savoir" uniquement).
7. **Dispositif "porté en permanence" : distingué sur "Ce qu'il faut savoir", pas sur la fiche secours.** Savoir qu'un dispositif est implanté (pompe à insuline, etc.) semble pourtant au moins aussi utile en urgence qu'au quotidien — la fiche secours liste tous les dispositifs indifféremment, sans cette précision.

## 5. Champs morts, sans impact fonctionnel

`requiresAdaptations` sur `TransportData`, `SafetyData`, `OvernightStayData`, `AquaticActivityData` : reliquat d'un ancien filtre supprimé le 16/08, jamais à `true` en pratique (aucune page ne l'écrit), jamais lu par aucune règle. Sans risque aujourd'hui, mais à nettoyer pour ne pas induire en erreur un futur développement.

## 6. Vérification des 14 recommandations critiques

Vérifiée directement, indépendamment de la recherche déléguée (mécanisme construit dans cette même session) :

- Les 14 identifiants marqués `isCritical: true` correspondent exactement à la liste validée le 18/08 — confirmé par recherche exhaustive (`grep`) sur les 14 fichiers de règles.
- Aucun autre endroit du code ne construit un objet `Recommendation` — les seules 14 sources possibles sont les fichiers de règles eux-mêmes, `activity_recommendations_page.dart` ne fait que les afficher.
- Sur l'écran professionnel, une recommandation critique ne peut jamais recevoir l'icône de masquage (elle ne s'affiche même pas pour elle) — vérifié dans `_buildRecommendationLine`.
- Dans le PDF généré, une recommandation critique est **toujours** incluse, quel que soit le contenu du masquage de l'utilisateur — vérifié dans `_printableResult` : la condition `recommendation.isCritical || ...` court-circuite avant même de consulter la liste des masquages.
- Cas limite vérifié : même si une préférence de masquage existait déjà en base pour un identifiant qui deviendrait critique après une future mise à jour (aujourd'hui hypothétique), elle resterait sans effet — la vérification de criticité passe toujours en premier.
- **Point annexe relevé pendant cette vérification** : la criticité n'a aujourd'hui aucune traduction visuelle sur les fiches (secours, "ce qu'il faut savoir", PDF) — une recommandation critique se présente exactement comme les autres. Pas une non-conformité au regard de "non masquable", mais une piste si tu veux un jour distinguer visuellement les points vraiment vitaux.

## Ce qui n'a pas pu être testé

Rien dans cette passe n'a nécessité de compte ou d'enregistrement fictif en base — c'est un audit de code et de règles, pas d'accès. Aucune limitation à signaler.

## Méthode détaillée

Recherche exhaustive déléguée à deux explorations en parallèle (une par profil : santé, activités), avec consigne de citer précisément fichier et ligne pour chaque constat — pas de résumé générique. Les deux constats les plus sévères (§1 et §2) ont ensuite été revérifiés à la main, par lecture directe des fichiers cités, avant d'entrer dans ce rapport. La vérification de la criticité/masquage (§6) a été faite entièrement à la main, sans délégation, sur du code écrit dans cette même session.

## Corrections apportées — round 2 (18/08/2026)

Suite à validation de la passe 2, deux rounds de corrections ont été faits. Le premier (commit `09ff61c`) traitait les points 1 à 4 de la validation (consignes d'urgence sur la fiche secours, allergies/pathologies sans traitement toujours visibles, alimentation électrique toujours signalée, les 3 recommandations manquantes restantes) plus la préselection et le doublon "effort physique". Ce round-2 (commit `7767454`) traite les points 1, 2 et 3 restants.

### 1. Source unique de formulation (les 7 incohérences du §4)

Pas traité comme 7 correctifs séparés, comme demandé. Le vrai problème : `EnvironmentRules` avait déjà des méthodes publiques (`heightRecommendations`, `animalRecommendations`, `waterTriggerRecommendations`, etc.) conçues pour être réutilisées par les deux fiches, mais aucune des deux ne les appelait — chacune réécrivait son propre texte, qui avait dérivé.

Correction structurelle :
- `UniversalTriggerRules` (photosensibilité, chaleur, stress, fatigue, "autre") a été réécrite sur le même modèle qu'`EnvironmentRules` : chaque règle expose maintenant une méthode publique qui retourne directement l'objet `Recommendation`.
- `emergency_info_sheet_page.dart` (fiche secours) et `care_info_sheet_page.dart` ("Ce qu'il faut savoir") appellent maintenant ces méthodes et affichent `.text` — elles ne réécrivent plus aucun texte elles-mêmes pour ces facteurs déclenchants. Le commentaire de `environment_rules.dart` qui prétendait déjà ça (item 4 du §4) décrit maintenant la réalité.

Deux décisions de fond te revenaient, tranchées par toi :
- **Préfixe de catégorie** ("Hauteur : ...", "Eau : ...", "Animaux : ...", "Effort physique : ...", "Autre : ...") appliqué partout, y compris sur la fiche de recommandations d'activité qui ne l'avait pas avant → texte identique aux 3 endroits.
- **Photosensibilité** : toujours deux lignes distinctes (vigilance + lunettes si nécessaires), jamais fusionnées, sur les 3 fiches.

Deux simplifications mineures que j'ai tranchées seul, sous ton seuil de validation, à te signaler :
- J'ai retiré la mention "signalé par la famille" du texte des deux facteurs "eau" (`mayJumpIntoWater`, `cannotSwim`), pour rester cohérent avec le style "Catégorie : fait." utilisé partout ailleurs. Le texte dit maintenant "Eau : risque de se jeter dans l'eau." au lieu de "Facteur déclenchant signalé par la famille : risque de se jeter dans l'eau."
- Pour la case "autre, détail libre" (hauteur/animaux/eau), j'ai gardé le comportement du moteur (n'affiche rien si le champ texte est vide) plutôt que celui, plus permissif, des deux fiches (qui affichaient une phrase de repli "vigilance particulière" même sans texte) — léger changement de comportement si un parent avait coché "autre" sans rien écrire.

Les 3 autres incohérences du §4 (médecin traitant/antécédents absents de "Ce qu'il faut savoir", spécialité du médecin référent jamais affichée, dispositif "porté en permanence" absent de la fiche secours) ne sont pas des divergences de texte mais des données absentes d'une fiche — hors du périmètre de cette correction structurelle, à traiter séparément si tu le souhaites.

### 2. Champs morts `requiresAdaptations`

Supprimés sur les 4 modèles concernés (`TransportData`, `SafetyData`, `OvernightStayData`, `AquaticActivityData`) : le champ, son paramètre de constructeur, et ses entrées `toJson`/`fromJson`. Vérifié qu'aucune autre référence ne subsistait (fixtures de démo, tests) avant de committer. Les champs `requiresAdaptations` de `CommunicationData` et `TransitionsData` sont conservés — ce sont de vraies questions posées à l'écran, pas des champs morts.

### 3. Test réel du lien de partage public sur Théo

Ligne `partages` temporaire créée sur Théo (`type_fiche = 'secours'`, expiration 1h), avec son autorisation explicite pour ce cas précis. Théo a de vraies consignes d'urgence enregistrées pour son épilepsie (6 étapes, de "Eloigner objets risquant de blesser" à "Au bout de 5 min administrer BUCCOLAM dans la joue").

Résultat du test réel (capture d'écran du rendu effectif de la page publique, pas juste une réponse JSON) : la section "Consignes d'urgence" apparaît bien en tête de la fiche secours publique, encadrée en rouge, avec les 6 étapes numérotées telles qu'écrites. Fonctionne comme prévu.

Nettoyage effectué immédiatement après : ligne `partages` supprimée (`delete from partages where id = 'b55c31c2-42c2-43e7-aa8e-0358eb2fe82e'`). Vérifié ensuite : `select count(*) from partages where enfant_id = '<Théo>'` renvoie 0, et une nouvelle tentative d'accès avec le même token renvoie "Lien expiré ou invalide." (404). Aucune trace résiduelle. Aucune autre donnée de Théo (profil santé, pathologies) n'a été créée ni modifiée pour ce test — seule la ligne de partage a existé, temporairement.

### Vérification

`flutter analyze` : aucun problème. `flutter test` : 130/130 passent (2 assertions de test mises à jour pour refléter le nouveau préfixe "Eau : "/"Autre : ", conforme au comportement voulu — pas des régressions).
