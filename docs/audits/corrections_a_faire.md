# Corrections notées pendant l'audit, à traiter après la passe 4

Liste vivante, mise à jour au fil des 4 passes de l'audit d'août 2026.
Rien ici n'est corrigé pendant l'audit lui-même — décision explicite de
Fanny : l'audit sert d'abord à établir un état des lieux complet, les
corrections viennent après, avec ses priorités.

**Statut au 19/08/2026 (fin de la phase de corrections) :** les 10
points prioritaires que Fanny a donnés après `inventaire.md` sont tous
faits, testés (`flutter analyze` propre, suite de tests complète) et
appliqués sur le projet Supabase réel (migrations + Edge Functions
déployées) — carrousel de découverte, outils de développement,
Paramètres, section Partages réelle, partage des recommandations
d'activité débloqué, récapitulatif santé complet, validation complète
du questionnaire santé, 6 éléments de code mort supprimés, partage de
la fiche avec un co-parent/tuteur, gestion d'équipe côté
établissement. Ça correspond aux items 14-19 ci-dessous (marqués
résolus) — les items 1, 3-13 restent le backlog ouvert, non liés à
cette liste de 10 points (ils viennent des 4 passes d'audit, pas de
l'inventaire).

**Statut au 19/08/2026 (reprise du backlog, par ordre de gravité) :**
résolus : items 1, 3, 4, 5, 7, 8, 9 ci-dessous, et items 10 et 13
(passe 3, voir plus bas). En attente d'actions côté Fanny dans
Supabase/Brevo, détaillées sur chacun : items 11 et 12. Seul item
restant, reporté par Fanny elle-même (pas un oubli) : item 6.

## Depuis la passe 1 (sécurité et RGPD, 19/08/2026)

1. **RÉSOLU (19/08/2026, commit `46ec829`).** Journal des
   consultations lisible par le parent concerné. Aujourd'hui
   `journal_consultations_fiche` n'a aucune politique de lecture pour
   personne, y compris le parent. Décision de Fanny : le parent doit
   pouvoir voir qui a consulté la fiche de son enfant et quand.
   Nouvelle politique RLS (lecture par `enfant_du_parent(enfant_id)`,
   appliquée sur le projet réel) + nouvel écran
   `ConsultationJournalPage` (fiche enfant → section "Traçabilité").
   Présentation choisie : identifie l'établissement responsable,
   pas la personne précise du personnel qui a consulté.

2. **Bouton "Supprimer le profil" — pas fonctionnel.** Signalé par
   Fanny pendant la passe 1. **Précision de Fanny (19/08/2026) :** le
   constat visait bien le bouton côté **parent**
   (`lib/children/child_profile_page.dart:634-656`), mal étiqueté
   "professionnel" sur le moment — aucune fonctionnalité de gestion
   d'équipe n'a disparu, ce n'est pas une seconde piste à explorer.
   **Statut réel : déjà fonctionnel depuis le commit `4ccbe62`**
   (antérieur à la passe 1) — point clos, rien à corriger ici.

3. **RÉSOLU (19/08/2026, commit `9e456f3`) — 4 tests ajoutés
   (`test/professional_offline_cache_test.dart`).** Test automatisé
   Dart pour la limite de 7 jours du cache hors-ligne côté
   professionnel. `ProfessionalChildRepository` avait la bonne
   logique (`_maxOfflineAge`), mais contrairement au côté parent
   (`test/offline_cache_test.dart`), aucun test ne la vérifiait.
   Couvre : cache récent rechargé normalement, cache de plus de 7
   jours refusé, cas limite à la frontière des 7 jours, aucune
   synchronisation antérieure.

4. **RÉSOLU (19/08/2026).** `partages` : aligner la politique RLS sur
   le pattern SECURITY DEFINER. La policy
   `partages_geres_par_le_parent` utilisait encore une sous-requête
   directe sur `enfants`, héritée de `schema.sql` d'origine, au lieu
   d'une fonction `SECURITY DEFINER` comme partout ailleurs
   (`enfant_du_parent()`). Pas un bug actif, une incohérence de code
   — remplacée et vérifiée sur le projet réel.

5. **RÉSOLU (19/08/2026).** Résidus de préférences de masquage sur
   `activites_recommandations_masquees`. La lecture ne revérifiait
   pas que l'activité est toujours accessible à l'utilisateur au
   moment de la lecture (seule l'écriture le faisait) — quelqu'un qui
   perd l'accès à un établissement gardait ses propres préférences de
   masquage lisibles sur d'anciennes activités. Jamais une fuite de
   donnée (chacun ne voyait que ses propres préférences), juste un
   résidu inutile à nettoyer. Policy de lecture séparée de celle
   d'écriture, revérifiant désormais la visibilité de l'activité à
   chaque lecture ; suppression restée basée sur la seule propriété,
   pour qu'une personne puisse toujours nettoyer sa propre préférence
   même après avoir perdu l'accès.

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

7. **RÉSOLU (19/08/2026, commit `25a60d5`).** Médecin traitant et
   antécédents médicaux absents de "Ce qu'il faut savoir sur...".
   Cette fiche est explicitement pensée (commentaire du code) pour un
   accompagnant qui garde l'enfant plusieurs jours (ex.
   grands-parents) — profil qui aurait plausiblement besoin du
   contact du médecin traitant en cas de problème non urgent.
   Présents sur la fiche secours, absents ici. Nouvelle section
   "Médecin traitant" + antécédents médicaux repliés dans la section
   de vigilance, écran et PDF.

8. **RÉSOLU (19/08/2026, commit `25a60d5`).** Spécialité, lieu
   d'exercice et téléphone du médecin référent d'une pathologie,
   saisis mais jamais affichés nulle part — ni sur la fiche secours,
   ni sur "Ce qu'il faut savoir" (seul le nom apparaissait, sur cette
   dernière uniquement). S'affichent désormais sur les deux fiches.

9. **RÉSOLU (19/08/2026, commit `25a60d5`).** Dispositif médical
   "porté en permanence" — distingué sur "Ce qu'il faut savoir", pas
   sur la fiche secours. Savoir qu'un dispositif est implanté (pompe à
   insuline, etc.) est au moins aussi utile en urgence qu'au
   quotidien. Nouvelle section dédiée sur la fiche secours, écran et
   PDF, séparée des dispositifs à emporter.

## Depuis la passe 3 (parcours bout en bout, 19/08/2026)

10. **RÉSOLU (19/08/2026, commit `f4ea72f`).** Message d'erreur
    technique brut affiché à l'utilisateur lors de la création de
    compte. Testé réellement avec un compte de test : quand Supabase
    rejette une adresse email invalide, l'app affichait directement
    l'exception brute (`AuthApiException(message: Email address "" is
    invalid, statusCode: 400, code: email_address_invalid)`) au lieu
    d'un message clair en français. Nouveau `friendlyAuthErrorMessage`,
    appliqué aux 6 écrans qui touchent à l'authentification.

11. **EN ATTENTE — ne se termine que dans les interfaces Supabase et
    Brevo, pas dans le code (19/08/2026).** Email de code de
    vérification "nouvel appareil" — expéditeur et réponse mal
    configurés côté Brevo. Testé réellement (vrai email reçu et code
    utilisé pour se connecter) : le nom d'expéditeur affiché est
    "KidsRelay" au lieu de "KidsRelay", et l'adresse "répondre à"
    pointe vers l'adresse personnelle de Fanny
    (fannydicaro@hotmail.fr).

    **Déjà fait côté code (commit `a3067c0`)** : les deux fonctions qui
    envoient un email via Brevo (`envoyer-code-verification`,
    `notifier-note-ajoutee`) précisent maintenant explicitement une
    adresse de réponse (`BREVO_REPLY_TO_EMAIL`, nouveau secret
    optionnel — si absent, l'adresse d'expéditeur sert aussi de
    réponse). Déployées.

    **Reste à faire par Fanny, étape par étape :**
    1. Dans Brevo, section "Expéditeurs" : vérifier qu'une adresse
       dédiée au projet existe (pas sa boîte personnelle) — en créer
       une sinon.
    2. Dans Supabase, Project Settings → Edge Functions → Secrets :
       modifier `BREVO_SENDER_EMAIL` avec cette adresse, et
       `BREVO_SENDER_NAME` avec la valeur `KidsRelay`.
    3. (Optionnel) Si les réponses doivent partir vers une adresse
       différente de l'expéditeur : ajouter un secret
       `BREVO_REPLY_TO_EMAIL` avec cette adresse.
    4. Peut aussi être fait en donnant simplement l'adresse/le nom à
       utiliser dans une conversation suivante — la mise à jour des
       secrets peut être faite depuis le code (`supabase secrets set`)
       sans naviguer dans l'interface.

12. **EN ATTENTE — ne se termine que dans l'interface Supabase, pas
    dans le code (19/08/2026).** Limite d'envoi d'emails du service
    d'authentification par défaut de Supabase — à vérifier avant le
    lancement public. Constaté réellement pendant la passe 3 : après
    une poignée d'emails de confirmation d'inscription envoyés en peu
    de temps pendant les tests, Supabase a bloqué toute nouvelle
    inscription avec `AuthApiException(..., code:
    over_email_send_rate_limit)`. Le service d'email intégré par
    défaut de Supabase est volontairement très limité (pensé pour le
    développement, pas pour la production) — la même limite
    s'appliquera aux vraies inscriptions de parents une fois l'app
    publiée, avec le risque qu'un pic d'inscriptions (ex. un
    lancement) bloque les emails de confirmation pour tout le monde.

    **Pourquoi ça ne peut pas être fait depuis le code** : ce réglage
    (SMTP personnalisé pour les emails automatiques de connexion —
    confirmation d'inscription, réinitialisation de mot de passe) vit
    uniquement dans la configuration Supabase, gérée par tableau de
    bord. La CLI a bien une commande pour pousser une configuration
    (`supabase config push`), mais elle demande de partir d'un fichier
    de config local qui n'existe pas encore dans ce projet, et il n'y
    a aucun moyen de vérifier d'abord ce qui est déjà réglé côté
    serveur avant de pousser — un risque réel d'écraser silencieusement
    d'autres réglages de connexion déjà en place, sur un système de
    connexion en production. Pas pris.

    **Reste à faire par Fanny, étape par étape :**
    1. Dans Brevo, section "SMTP & API" → onglet "SMTP" : générer ou
       copier la clé SMTP (différente de la clé API déjà utilisée par
       l'app — il en faut une deuxième).
    2. Dans Supabase, section Authentication → chercher le réglage
       d'envoi d'email personnalisé (SMTP) → l'activer.
    3. Renseigner : serveur `smtp-relay.brevo.com`, port `587`,
       identifiant = adresse de connexion Brevo, mot de passe = la clé
       SMTP de l'étape 1, adresse et nom d'expéditeur = ceux utilisés
       pour le point 11.
    4. Enregistrer, puis retester une inscription pour confirmer que
       la limite ne se déclenche plus.

13. **RÉSOLU (19/08/2026).** Après révocation, la fiche déjà ouverte
    reste affichée côté professionnel jusqu'à rechargement. Testé
    réellement pendant la passe 3 : dès que le parent révoque, l'accès
    réel aux données est coupé immédiatement côté serveur (vérifié par
    impersonation RLS — 0 ligne visible pour le professionnel révoqué),
    donc aucune fuite de donnée nouvelle n'était possible. Mais un
    onglet déjà ouvert continuait d'afficher les informations déjà
    chargées jusqu'à rechargement manuel.

    Nouveau `RevocationGuard` (`lib/professional/revocation_guard.dart`),
    posé sur les 3 fiches accessibles depuis `ProfessionalChildDetailPage`
    et sur le Mode Urgence professionnel : vérification périodique
    (toutes les 20 secondes) de l'accès, via la même règle RLS que le
    reste de l'app. Si l'accès a été perdu (révocation ou expiration),
    une fenêtre "Accès révoqué" s'affiche puis referme la fiche
    jusqu'à l'accueil professionnel — sans action de la part de la
    personne concernée. Une vérification qui échoue simplement (pas
    de réseau) ne ferme jamais la fiche par erreur — seule une
    absence confirmée (RLS) le fait.

## Depuis la passe 4 (écrans et boutons inactifs ou trompeurs, 19/08/2026)

Recherche exhaustive déléguée puis vérification personnelle des
constats les plus sérieux en conditions réelles (navigateur piloté,
pas seulement lecture du code).

14. **RÉSOLU (19/08/2026, commit `10ba610`) — le bouton mène
    maintenant à la création de compte.** Le bouton final du
    carrousel de découverte ne fait rien —
    testé réellement. `lib/demo_page.dart:164-178`. Sur la dernière
    diapositive (6/6) du parcours "Découvrir ce que KidsRelay peut
    faire" (accessible dès l'écran d'accueil, avant toute création de
    compte), le bouton "Créer gratuitement la fiche de mon enfant" a
    pour gestionnaire `() {}` — une fonction vide. Cliqué réellement
    pendant l'audit : l'écran reste identique, aucune réaction. C'est
    le bouton d'appel à l'action principal du parcours de découverte,
    vu par tout nouveau parent curieux avant même de créer un compte —
    sévérité la plus haute de cette passe.

15. **RÉSOLU (19/08/2026, commit `10ba610`) — section supprimée.**
    Section "Outils de développement" visible et sans garde dans un
    build release — confirmé réellement, à deux reprises.
    `lib/particulier_home_page.dart:119-178` (commentaire "Développement
    uniquement" à la ligne 119, mais aucun `kDebugMode` ni équivalent
    ne protège son affichage). Déjà repéré en passe 3, revérifié
    spécifiquement pour la passe 4 : la section apparaît bel et bien
    dans le build web release, pour n'importe quel visiteur de l'écran
    "Espace particulier" — c'est-à-dire dans le parcours normal, pas
    caché derrière un accès spécial. Les deux boutons ("Tester le
    questionnaire Télétransmission" / "Tester le questionnaire
    Activités") ouvrent les vrais formulaires de production, sans
    contexte d'enfant — un visiteur qui y saisit des réponses peut
    croire qu'il vient de créer un profil.

16. **RÉSOLU (19/08/2026, commit `4992a38`) — écran réel construit
    (email, changement de mot de passe, déconnexion).**
    "Paramètres" dans le menu principal — n'ouvre aucun écran.
    `lib/home/home_page.dart:84-95, 291-306`. Le bouton (icône
    engrenage) affiche uniquement un SnackBar : *"Les paramètres sera
    créé à l'étape suivante."* Aucun écran de paramètres n'existe dans
    le code (`lib/settings` n'existe pas). Se présente comme une
    entrée de menu normale, ne mène nulle part.

17. **RÉSOLU (19/08/2026, commit `10ba610`) — supprimé.**
    Écran "Créer une fiche enfant" mort et lui-même cassé.
    `lib/create_child_profile_page.dart`. Confirmé par recherche
    indépendante : ce fichier n'est référencé nulle part ailleurs dans
    l'app (aucune navigation ne pointe vers lui), remplacé depuis par
    le vrai parcours (`CreateChildProfileIntroPage` → `IdentityPage`).
    Sans impact aujourd'hui puisqu'inaccessible, mais contient lui-même
    deux contrôles non fonctionnels (`onChanged: (value) {}` ligne 82,
    `onPressed: () {}` ligne 89) — à supprimer plutôt qu'à corriger,
    pour ne pas laisser un piège si quelqu'un le rebranche par erreur
    plus tard.

18. **RÉSOLU (19/08/2026, commit `10ba610`) — supprimée.**
    Chaîne d'écrans "story_*" entièrement morte (5 fichiers), avec
    un bouton tout aussi trompeur à l'intérieur.
    `lib/story_child_intro_page.dart` et les 4 fichiers `story_*.dart`
    qui le suivent. Confirmé par recherche indépendante : aucune
    navigation vers `StoryChildIntroPage` (le point d'entrée de la
    chaîne) n'existe dans l'app — probablement une version antérieure
    du carrousel de `demo_page.dart`, jamais supprimée. À l'intérieur
    de ce code mort : `lib/story_end_page.dart:45-50` a un bouton
    portant le même texte trompeur ("Créer gratuitement la fiche de
    mon enfant") qui ne fait que fermer les écrans
    (`Navigator.popUntil`), sans rien créer — et les images
    référencées (`assets/story_1.png.png`, etc.) ont un chemin
    incorrect par rapport à `pubspec.yaml`, donc ne se seraient de
    toute façon jamais chargées. Sans impact aujourd'hui puisqu'
    inaccessible ; à supprimer avec le reste du code mort ci-dessus.

19. **RÉSOLU (19/08/2026, commit `10ba610`) — supprimée.**
    Classe `HomePage` en double dans `lib/main.dart` — jamais
    utilisée. `lib/main.dart:114-138` définit sa propre classe
    `HomePage` (texte "Bienvenue dans KidsRelay"), distincte de la
    vraie page d'accueil (`lib/home/home_page.dart`). Confirmé par
    recherche indépendante : les 4 endroits qui naviguent vers
    `HomePage()` importent tous la bonne classe — celle de
    `main.dart` n'est jamais instanciée. Purement cosmétique
    aujourd'hui, mais source de confusion future si un import venait à
    changer par erreur.

## Tests manuels restants côté Fanny (19/08/2026)

Les deux séries — partage avec un co-parent ou tuteur, et gestion
d'équipe côté établissement — ont été **déplacées dans
[`a_verifier_sur_mobile.md`](a_verifier_sur_mobile.md)** le 25/08/2026,
où elles sont devenues les points 11, 12, 22 à 29 avec leur résultat
attendu.

Elles y ont leur place : ce sont des vérifications sur appareil avec
de vrais comptes, pas des corrections à faire.


## Depuis le bouton « Exporter mes données » (23/08/2026)

**Le droit d'accès d'une personne de confiance n'est pas traité.**

L'export RGPD livré le 23/08/2026 est réservé au parent qui possède
les fiches : une personne de confiance en consultation seule n'y a pas
accès, c'est le cadrage décidé et il est testé
(`test/export_section_test.dart`).

Mais une personne de confiance est elle aussi une personne concernée
au sens du RGPD, et l'application détient des données **sur elle** :
son adresse email, la date de son invitation, son niveau d'accès, la
date d'acceptation ou de révocation, et son identifiant de compte.
L'article 15 lui ouvre donc un droit d'accès sur ces données-là.

Aujourd'hui, ces informations ne sortent que dans l'export **du
parent** qui l'a invitée — jamais dans un export à elle, puisqu'elle
n'a pas de bouton.

Ce qu'il faudrait, si le sujet est repris : un export réduit pour un
compte sans enfant, contenant son propre compte et ses rattachements
en tant que personne de confiance, sans aucune donnée d'enfant.

Décision de Fanny le 23/08/2026 : on ne le traite pas maintenant, mais
on ne le perd pas.

**Piège connexe à ne pas oublier** :
`ChildRepository.loadFromSupabase` fait un `select()` sans filtre sur
`enfants`. La liste renvoyée contient donc aussi les enfants sur
lesquels le compte est seulement personne de confiance. Documenté sur
place depuis le 23/08/2026 ; tout futur écran qui affichera
« mes enfants » doit filtrer sur `parent_id`.

## Depuis la conformité RGPD (24/08/2026)

**L'adresse de secours n'a pas de procédure d'usage.**

Le champ existe dans Paramètres et l'adresse est enregistrée. Mais
rien n'écrit ce qui se passe le jour où un parent l'invoque : qui
vérifie quoi, avec quelle preuve d'identité, et par quel canal la
réponse part.

Tant que cette procédure n'existe pas, c'est une donnée collectée dont
l'usage n'est pas documenté — précisément ce que le RGPD demande
d'éviter. Le champ est un prérequis, pas une fonctionnalité complète.

**La durée de conservation des comptes inactifs n'est pas définie.**
Rien n'expire aujourd'hui en dehors des partages (24h après leur date
d'expiration) et du journal de consultations. Un compte abandonné garde
ses données de santé d'enfant indéfiniment.

## Chantier fait le 25/08/2026 : le brouillon de questionnaire

**Enregistrer le brouillon de questionnaire a chaque ecran.** — fait.

Le defaut : rien n'etait ecrit avant la derniere page. Le profil sante
n'etait enregistre qu'a `transition_to_activities_page`, apres le
sixieme ecran ; le profil Activites qu'a `other_information_page`,
apres le onzieme. Un parent qui abandonnait au cinquieme ecran sur onze
perdait les cinq, et la page de transition ecrivait meme « ou revenir
plus tard » — vrai pour le profil sante deja enregistre, trompeur pour
les Activites commencees puis interrompues.

Ce qui a ete fait : le brouillon est ecrit sur l'appareil a chaque
ecran valide, propose a la reprise dans « Mes enfants », jete a la
validation finale et au bout de 30 jours. Detail des quatre decisions
et de leurs raisons dans
[`next_session_pickup.md`](next_session_pickup.md).

Les deux questions restees ouvertes, volontairement :

- **Deux appareils qui reprennent le meme brouillon** : ne peut pas se
  produire, puisque le brouillon ne quitte pas l'appareil. Ce sera la
  question du jour ou une table de brouillons existera en base.
- **Reprendre a l'ecran ou l'on s'etait arrete** : ecarte au profit
  d'une reprise au premier ecran, reponses pre-remplies. Plus simple,
  et cela laisse au parent l'occasion de relire ce qu'il avait saisi.

La decision du 25/08/2026 de **ne rien ecrire a l'ecran sur la perte du
travail en cours** n'a plus d'objet : il n'y a plus de perte a avouer.

## Une saisie numerique incomprise disparait sans un mot (25/08/2026)

**Ou** : `lib/widgets/sk_number_field.dart`, et les deux appels de
`lib/transmission_pages/identity_page.dart` (taille et poids).

`SkNumberField` n'est qu'un `TextFormField` avec un clavier numerique.
Il n'a ni `validator`, ni `inputFormatters`. Ce que le parent tape part
dans `updateHeightCm` / `updateWeightKg`, qui font
`double.tryParse(value.replaceAll(',', '.'))` : une saisie que Dart ne
comprend pas - « 24,5 kg », « environ 25 », « 1m20 » - rend `null`.

**Le champ garde le texte a l'ecran. La valeur enregistree est vide. Le
parent ne l'apprend jamais.** Il n'y a ni message, ni marque rouge, ni
refus au moment de continuer : ces deux champs sont facultatifs, donc
rien ne se declenche.

Sur telephone, le clavier numerique limite la casse. Sur ordinateur, et
avec les claviers qui laissent taper des lettres, non.

**Pourquoi cela compte ici plus qu'ailleurs** : un parent qui croit
avoir renseigne le poids de son enfant et dont la valeur est perdue,
c'est une fiche de sante incomplete sans que personne le sache. Le
poids sert au dosage.

**Decision du 25/08/2026** : a corriger, mais pas dans le chantier du
brouillon. Ce qu'il faudra regarder : refuser la saisie invalide a
l'ecran plutot que de l'avaler, ou l'accepter et le dire. Verifier au
passage si d'autres `SkNumberField` sont dans le meme cas ailleurs dans
l'application.

## Règle permanente sur le contenu des emails (27/08/2026)

Vaut pour les deux mails existants et **pour tous ceux à venir**.

> **Jamais de nom de famille. Jamais le contenu d'une note. Jamais
> aucune donnée de santé. Prénom seul au maximum.**

Ce qui décide, dans chaque cas, c'est la **finalité du mail** — pas le
confort de lecture.

**Notification de note** — prénom de l'enfant **et** nom de
l'établissement : conservés. Sa finalité est de dire au parent qu'une
note vient d'être ajoutée sur un enfant précis par une structure
précise, pour qu'il puisse juger de l'urgence sans ouvrir
l'application en aveugle. Les deux informations servent cette
finalité, donc elles sont justifiées. `messageNoteAjoutee` dans
[`_logique/emails.mts`](../../supabase/functions/_logique/emails.mts) :
**ne pas y toucher.**

**Rappel semestriel des partages permanents** — **pas de prénom.** Sa
finalité est seulement de faire ouvrir l'application pour vérifier les
partages actifs ; la liste complète s'affiche à l'arrivée. Le prénom
n'apporte rien à cette finalité. Un compte sans nom suffit si la
clarté manque : « Vous avez 2 partages permanents toujours actifs. »

Le raisonnement à reproduire pour un mail nouveau : *de quoi ce
message a-t-il besoin pour que le parent sache quoi faire ?* Ce qui
dépasse cette réponse ne part pas.

## Les durées de partage ne sont pas des choix d'ergonomie (27/08/2026)

> **Ne pas modifier la liste des durées proposées sans demander à
> Fanny.**

Chaque entrée correspond à un **usage réel côté parent**, pas à une
progression régulière qu'on pourrait « simplifier ».

Liste arrêtée : **24 heures · 3 jours · 7 jours · 1 mois · 1 an**, plus
une date au calendrier et l'option sans date de fin.

L'erreur commise, et corrigée le jour même : « 3 jours » a été retiré
au motif que c'était « le seul intermédiaire d'une échelle qui
s'arrêtait à une semaine ». C'était raisonner sur l'échelle et non sur
l'usage. **« 3 jours » couvre le week-end chez un proche** — le parent
prépare le lien le vendredi, l'accès couvre vendredi, samedi et
dimanche. Le remplacer par « 7 jours » laisserait l'accès ouvert quatre
jours de plus sans aucune utilité, contre le principe de limitation
appliqué partout ailleurs.

La règle est aussi écrite en tête de `_ShareDuration`, dans
[`create_share_link_page.dart`](../../lib/sharing/create_share_link_page.dart),
et un test vérifie que la mention y reste.

## Une page destinée à l'extérieur doit être ouverte en vrai (27/08/2026)

**Le constat.** La page publique d'un lien de partage — celle que voit
l'accompagnant à qui un parent envoie une fiche — **n'avait jamais été
ouverte dans un navigateur réel**. Elle était couverte par 19 tests en
isolation, et ces tests passaient.

Elle ne s'affichait pas. La passerelle des Edge Functions Supabase
réécrit toute réponse HTML en `text/plain` avec un CSP `sandbox` : le
navigateur montrait le **code source** au lieu de la page. C'est ce
qu'aurait vu la première enseignante à qui Fanny aurait envoyé un lien.

**Ce qui est troublant** : le défaut était noté comme non couvert, dans
le document de vérification du 25/08/2026 lui-même —

> « Le rendu de la page publique… La page est testée en isolation
> (19 tests), mais elle n'a pas été ouverte dans un navigateur sur ces
> trois liens. »

La limite était écrite, et personne n'y est revenu. L'écrire n'a pas
suffi.

> **Règle : toute page destinée à un utilisateur extérieur doit être
> ouverte en vrai, dans un navigateur, avant d'être considérée comme
> faite.** Les tests en isolation vérifient ce que la page contient,
> jamais ce que le navigateur en fait — ni les en-têtes, ni le CSP, ni
> le rendu.

S'applique à la page de partage, à `auth.kidsrelay.fr`, et à la page
intermédiaire du rappel semestriel quand elle existera.

**Corollaire pour les vérifications reportées** : une limite notée dans
un document n'est pas une limite traitée. Quand une vérification est
reportée faute d'outil ou de temps, elle doit entrer dans
`a_verifier_sur_mobile.md`, qui est relu, et pas seulement dans le
document du chantier, qui ne l'est plus une fois le chantier clos.

## Consigne permanente pour la suite de l'audit

Ne plus créer de comptes ou d'enregistrements fictifs dans la base
réelle pour un test, sans demander d'abord à Fanny.
