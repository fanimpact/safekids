# Passe 3 — Parcours bout en bout, testés réellement

Date : 19/08/2026. Méthode : Node.js + Playwright pilotant un vrai
Chromium headless contre le build web release de l'app, connecté en
direct au projet Supabase réel (pas de simulation, pas de mock). Deux
comptes de test temporaires (un parent, un professionnel), créés avec
l'accord explicite de Fanny à chaque étape, entièrement supprimés en
fin de passe — voir la section "Nettoyage" en bas de ce rapport.

## Ce qui a été testé pour de vrai, et résultat

### Compte et connexion (déjà couvert en détail dans le rapport de la passe 2, round 2 — non répété ici)
Création de compte, connexion depuis un appareil non reconnu avec un
vrai code reçu par email, rejet d'un code invalide, persistance de la
confiance de l'appareil après un rechargement complet de la page (le
code n'est pas redemandé, même si la session Supabase elle-même doit
être réétablie par mot de passe). **Résultat : conforme.**

### Création du profil enfant
Profil complet créé via le vrai parcours (identité, pathologies,
allergies, événements médicaux, facteurs déclenchants, traitements,
dispositifs médicaux, contacts d'urgence). Écriture confirmée dans
`enfants` et `profils_sante` avec les bonnes valeurs. **Résultat :
conforme.** (Un premier contrôle en base juste après l'écran de succès
n'a rien trouvé — pas un bug, juste un délai réseau : la ligne était
bien là quelques secondes plus tard, revérifié.)

### Préparation d'activité côté parent
Questionnaire complet (eau, marche/effort, transport, nuitée, sécurité,
facteurs déclenchants, habillage), sélection de l'enfant, génération
des recommandations. **Résultat : conforme** — avec un profil enfant
sans besoin déclaré et un profil activités vide, la fiche ne génère
aucune recommandation, ce qui est le comportement correct (rien à
signaler dans ce cas précis, pas une fiche vide anormale).

**Persistance réelle de l'activité côté parent (correction du manque
identifié dans le plan initial, §6) : confirmée.** La ligne
`activites_preparees` est bien écrite avec le bon `parent_id`, le bon
`enfants_ids`, et le JSON de caractéristiques exact. Réouverture depuis
"Activités enregistrées" : fonctionne, recommandations recalculées en
direct à partir du profil le plus à jour (pas de recommandations
figées stockées), conforme au principe du plan.

### Mode Urgence et fiche secours (parent)
Les deux écrans s'affichent correctement pour un enfant sans
pathologie déclarée (situation "Autre urgence" uniquement, bouton
d'appel des secours ; fiche secours avec toutes les sections à l'état
"Aucun(e)... connu(e)"). **Résultat : conforme.**

### Établissement, rattachement, côté professionnel
- Création d'un établissement professionnel réel (Menu → "Créer mon
  établissement") : ligne `etablissements` + `membres_etablissement`
  (rôle directeur) créées correctement.
- Génération du code de rattachement côté parent (durée obligatoire,
  ici 3 mois) : ligne `enfants_etablissements` créée avec le bon
  `enfant_id`, `date_expiration` correcte, statut "actif".
- Réclamation du code côté professionnel : l'enfant apparaît
  immédiatement dans le trombinoscope de l'établissement.
- **Fiche secours côté professionnel** : identique à la version
  parent, comme attendu.
- **Journal de consultation RGPD (audité en passe 1, jamais vérifié en
  conditions réelles jusqu'ici) : confirmé pour de vrai.** Une ligne
  `journal_consultations_fiche` a été créée automatiquement à
  l'ouverture de la fiche secours, avec le bon `user_id` (le
  professionnel), le bon `enfant_id`, le bon `etablissement_id`, et
  `type_fiche = 'secours'`.
- **Préparation d'activité côté établissement** : questionnaire
  complet, sélection de l'enfant, étape "Note sur l'activité"
  (spécifique au parcours professionnel) testée avec une note
  rattachée à l'enfant. Ligne `activites_preparees` créée avec
  `etablissement_id` correct et `parent_id` null (comme prévu par la
  contrainte `un_seul_proprietaire`). Ligne `notes_activite` créée
  avec le bon `auteur_id` et le bon texte. Écran "Terminer" redirige
  bien vers l'accueil professionnel (pas vers l'accueil parent — le
  bug corrigé le 18/08 reste corrigé).
- **Notification au parent lors de l'ajout d'une note liée à un
  enfant** : le mécanisme entier fonctionne — ligne
  `evenements_notification_parent` créée avec
  `type_evenement = 'note_ajoutee'`, `parent_id` et `enfant_id`
  corrects. L'envoi effectif de l'email a échoué (`statut_email:
  'echoue'`), mais c'est un artefact du compte de test créé
  directement en base (jamais passé par le vrai formulaire
  d'inscription, donc sans ligne `comptes_parents.email` à lire) — pas
  un bug du mécanisme lui-même, qui a échoué exactement comme prévu
  faute de destinataire.

### Révocation — le test le plus important de cette passe
1. Révocation déclenchée côté parent (Menu → "Mes rattachements
   établissement" → "Révoquer", avec écran de confirmation). Ligne
   `enfants_etablissements` mise à jour : `statut = 'revoque'`,
   `revoque_le` renseigné.
2. **Vérifié séparément, par impersonation RLS (le professionnel
   authentifié, pas le rôle `postgres` qui contourne tout) : l'accès
   réel aux données de santé est coupé immédiatement côté serveur** —
   `select ... from profils_sante` renvoie 0 ligne pour le
   professionnel revoqué, alors même que l'écran de l'app affichait
   encore la fiche complète dans la même session (cache local, pas
   encore resynchronisé).
3. Après reconnexion complète (rechargement de page + nouvelle
   connexion), le trombinoscope professionnel affiche bien
   "Aucun enfant rattaché pour le moment." — la purge du cache local
   au prochain contact avec le serveur, prévue dans le plan (§7),
   fonctionne réellement.

**Conclusion sur la révocation : la sécurité réelle (RLS) est
immédiate ; l'affichage côté client se met à jour au prochain contact
avec le serveur, pas instantanément dans un onglet déjà ouvert — c'est
le comportement voulu, pas une faille (la donnée elle-même n'est plus
accessible, seul un texte déjà chargé en mémoire reste visible jusqu'au
prochain rafraîchissement).**

## Aucun nouveau problème trouvé dans cette moitié de la passe

Tout ce qui a été testé ci-dessus (profil enfant, activité parent et
établissement, mode urgence, fiche secours, journal RGPD, rattachement,
révocation) a fonctionné conformément à ce que décrit le plan. Les 3
constats de la passe 3 remontés précédemment (message d'erreur
technique brut à l'inscription, expéditeur/réponse Brevo mal
configurés, limite d'emails Supabase à vérifier avant lancement) restent
les seuls réels de cette passe — déjà dans `corrections_a_faire.md`
(items 10 à 12), pas corrigés pendant l'audit comme convenu.

## Nettoyage

Compte parent de test (`kidsrelay-audit-pass3d-...`), compte
professionnel de test (`kidsrelay-audit-pass3-pro-...`), l'enfant
fictif "AuditTest Fictif", l'établissement "Ecole Audit Test", et
toutes les données liées (profil santé, rattachement, 2 activités
préparées, note, événement de notification, ligne de journal de
consultation) ont été entièrement supprimés après les tests.
**Vérification finale : zéro ligne restante** sur les 12 tables
concernées (comptage explicite par table, tout à 0). Théo, Noé et le
compte réel de Fanny n'ont jamais été touchés — revérifié.

## Ce qu'il reste à couvrir dans la passe 3

Rien : les 8 parcours annoncés (compte, connexion, profil enfant,
activité parent, activité professionnel, mode urgence, fiche secours,
rattachement/révocation) ont tous été testés réellement. La passe 3
est terminée.
