# Passe 4 — Écrans et boutons inactifs ou trompeurs

Date : 19/08/2026. Méthode : recherche exhaustive déléguée sur
l'ensemble de `lib/` (164 fichiers Dart), puis vérification
personnelle indépendante de chaque constat retenu — par relecture
directe du code pour les questions d'accessibilité (une route est-elle
vraiment jamais atteinte ?), et par test réel dans le navigateur piloté
pour les deux constats les plus graves.

## 1. Bouton final du carrousel de découverte — testé réellement, ne fait rien

`lib/demo_page.dart:164-178`. Sur la dernière diapositive (6/6) du
parcours "Découvrir ce que KidsRelay peut faire", le bouton
**"Créer gratuitement la fiche de mon enfant"** a pour code :
```dart
onPressed: _currentPage == _pages.length - 1 ? () {} : _nextPage,
```
Sur la dernière page, c'est une fonction vide. **Cliqué réellement
pendant l'audit** (navigateur piloté, pas une lecture de code) :
l'écran reste identique, capture d'écran avant/après strictement
comparée. C'est le bouton d'appel à l'action principal du parcours de
découverte — vu par tout nouveau parent curieux, avant même de créer
un compte. Sévérité la plus haute de cette passe.

## 2. "Outils de développement" visibles sans garde en production — confirmé deux fois

`lib/particulier_home_page.dart:119-178`. Déjà repéré pendant la passe
3 en testant la création de compte, spécifiquement revérifié pour
cette passe : la section (commentée "Développement uniquement" dans le
code, mais sans aucune protection `kDebugMode` ou équivalente)
s'affiche bien dans le build web release, dans l'écran "Espace
particulier" — le parcours normal, pas un accès caché. Les deux
boutons ouvrent les vrais formulaires de production ("Télétransmission"
et "Activités") sans contexte d'enfant réel.

## 3. "Paramètres" — n'ouvre aucun écran

`lib/home/home_page.dart:84-95, 291-306`. Affiche un SnackBar :
*"Les paramètres sera créé à l'étape suivante."* Aucun écran de
paramètres n'existe dans le code. Se présente comme une entrée de
menu normale.

## 4. Deux ensembles de code mort, avec des pièges similaires à l'intérieur

- **`lib/create_child_profile_page.dart`** : écran jamais atteint
  depuis nulle part dans l'app (vérifié indépendamment), remplacé par
  le vrai parcours (`CreateChildProfileIntroPage` → `IdentityPage`).
  Contient lui-même un menu déroulant et un bouton "Continuer" tous
  deux non fonctionnels — sans impact aujourd'hui, mais un piège si
  quelqu'un le rebranchait par erreur.
- **5 fichiers `story_*.dart`** : chaîne d'écrans entièrement morte
  (vérifiée indépendamment — aucune navigation vers son point
  d'entrée), apparemment une version antérieure du carrousel de
  découverte jamais supprimée. Contient un bouton portant exactement
  le même texte trompeur que le constat n°1 ("Créer gratuitement la
  fiche de mon enfant"), qui ne fait que fermer les écrans sans rien
  créer — plus un bug annexe (chemins d'images incorrects, n'auraient
  de toute façon jamais chargé).

Recommandation : supprimer ces deux ensembles plutôt que les corriger,
puisqu'ils ne sont accessibles depuis nulle part.

## 5. Classe `HomePage` dupliquée, jamais utilisée

`lib/main.dart:114-138` définit sa propre classe `HomePage` (texte
"Bienvenue dans KidsRelay"), distincte de la vraie
(`lib/home/home_page.dart`). Vérifié indépendamment : les 4 endroits
qui naviguent vers `HomePage()` importent tous la bonne classe.
Purement cosmétique — à nettoyer par hygiène, aucun impact utilisateur.

## 6. Point à clarifier avec toi : "Supprimer le profil côté professionnel" (item 2 déjà dans la liste)

Recherche exhaustive dans `lib/professional/` (les 14 fichiers) :
aucun bouton "supprimer", "quitter" ou équivalent n'existe nulle part
côté professionnel. Le seul bouton "Supprimer le profil" du code se
trouve côté **parent** (`lib/children/child_profile_page.dart:634-656`)
et il est **fonctionnel** depuis le commit `4ccbe62` — antérieur même
à la passe 1. Je ne tranche pas seule entre deux hypothèses : soit le
constat de la passe 1 visait ce bouton parent, mal étiqueté
"professionnel" sur le moment ; soit un bouton de gestion d'équipe
(retirer un collègue) a existé et disparu depuis, mais rien dans le
code actuel ne confirme cette seconde piste. Note ajoutée à l'item 2
de `corrections_a_faire.md`, à trancher avec toi plutôt que deviner.

## Ce qui a été vérifié et n'a rien donné

Recherche exhaustive de `Placeholder()`, `UnimplementedError`,
`onPressed: null`/`onChanged: null`, et des formulations françaises
type "bientôt disponible"/"non implémenté" utilisées comme substitut
de fonctionnalité — aucune autre occurrence trouvée. Tous les boutons
d'impression/partage (fiche secours, "Ce qu'il faut savoir",
récapitulatifs, PDF de recommandations), les écrans d'authentification,
Mode Urgence, création de lien de partage/rattachement, et l'ajout de
note côté professionnel ont été vérifiés individuellement et sont
réellement fonctionnels — pas de faux positifs à signaler.

## Nettoyage

Aucun compte de test créé pour cette passe — tous les constats
retenus étaient soit vérifiables par lecture de code indépendante
(accessibilité d'un écran), soit testables sans authentification (le
carrousel de découverte, accessible avant tout compte).

## Bilan des 4 passes

Avec cette passe 4, l'audit complet demandé est terminé. Récapitulatif
dans `docs/audits/corrections_a_faire.md` : 19 points recensés au
total (5 de la passe 1, 4 de la passe 2, 4 de la passe 3, 6 de la
passe 4), aucun corrigé pendant l'audit lui-même — prêts à être
priorisés.
