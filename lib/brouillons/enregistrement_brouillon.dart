import 'package:flutter/foundation.dart';

import '../models/activity_profile_draft.dart';
import '../models/child_profile_draft.dart';
import '../repositories/child_repository.dart';
import 'brouillon_profil.dart';
import 'brouillon_repository.dart';

/// Ce que les écrans de questionnaire appellent, en une ligne.
///
/// Le détail — d'où vient le prénom, quel identifiant sert de clé — est
/// ici et pas répété dans les dix-sept écrans. Un paramètre mal passé
/// sur un seul d'entre eux donnerait un brouillon qu'on ne saurait plus
/// retrouver, et personne ne s'en apercevrait avant qu'un parent perde
/// son travail.

/// À appeler à la fin de chaque écran du questionnaire santé, une fois
/// la validation passée.
///
/// **N'échoue jamais.** Un brouillon perdu est regrettable ; un parent
/// bloqué au milieu de son questionnaire parce que le stockage de
/// l'appareil a hoqueté ne l'est pas — c'est exactement le problème
/// qu'on cherche à résoudre.
Future<void> enregistrerBrouillonSante(
  ChildProfileDraft draft,
) async {
  try {
    await BrouillonRepository.instance.enregistrerSante(draft);
  } catch (erreur) {
    debugPrint('Brouillon santé non enregistré : $erreur');
  }
}

/// À appeler à la fin de chaque écran du profil Activités. N'échoue
/// jamais non plus, pour la même raison.
///
/// Le prénom vient de l'enfant déjà enregistré : à ce stade du parcours
/// il existe forcément, puisque le profil Activités ne se remplit
/// qu'après le questionnaire santé.
Future<void> enregistrerBrouillonActivites(
  ActivityProfileDraft draft,
) async {
  final childId = draft.childId;

  if (childId == null || childId.isEmpty) {
    return;
  }

  try {
    final enfant = ChildRepository.instance.findByChildId(childId);

    await BrouillonRepository.instance.enregistrerActivites(
      draft,
      childId: childId,
      prenom: enfant?.essentialInformation.identity.firstName,
    );
  } catch (erreur) {
    debugPrint('Brouillon Activités non enregistré : $erreur');
  }
}

/// À appeler quand le questionnaire est allé au bout : le brouillon n'a
/// plus de raison d'être. N'échoue jamais non plus — l'enfant est déjà
/// enregistré à ce stade, un brouillon récalcitrant ne doit pas gâcher
/// l'arrivée.
Future<void> supprimerBrouillon(
  TypeBrouillon type,
  String childId,
) async {
  try {
    await BrouillonRepository.instance.supprimer(type, childId);
  } catch (erreur) {
    debugPrint('Brouillon non supprimé : $erreur');
  }
}
