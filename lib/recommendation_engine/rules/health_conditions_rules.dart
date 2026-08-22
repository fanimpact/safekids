import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

/// Rappelle l'existence de chaque pathologie et allergie du profil
/// santé, indépendamment de tout traitement d'urgence qui lui serait
/// lié. Corrigé (19/08/2026) : avant cette règle, une allergie ou une
/// pathologie sans traitement associé n'apparaissait dans aucune
/// recommandation — le moteur ne la lisait que via
/// `relatedPathologyIds`/`relatedAllergyIds` d'un traitement
/// d'urgence — alors qu'elle est toujours affichée sur la fiche
/// secours et "Ce qu'il faut savoir sur...". Le risque doit être
/// signalé même sans traitement enregistré.
///
/// Corrigé (22/08/2026) : cette règle est désormais la SEULE source
/// des allergies sur la fiche de recommandations d'activité et sur le
/// lien de partage. Les deux affichaient auparavant chaque allergie en
/// double — une fois par cette règle, une fois par une liste de textes
/// réécrite à la main dans la page (`_allergyTexts`) et dans le
/// snapshot de partage. Ces copies locales ont été supprimées ; ne pas
/// les réintroduire, sous peine de recréer le doublon.
///
/// Quand l'activité comprend un repas, les allergies concernées par le
/// repas sont laissées à `MealsRules`, qui les rattache au moment du
/// repas plutôt que de les isoler en haut de fiche (22/08/2026) — d'où
/// le paramètre [activity]. Sans repas prévu, elles restent affichées
/// ici, exactement comme avant : le repas déplace l'information, il ne
/// la fait jamais disparaître.
class HealthConditionsRules {
  const HealthConditionsRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;

    if (childId == null) {
      return recommendations;
    }

    final essentialInformation = child.essentialInformation;

    for (final pathology in essentialInformation.pathologies) {
      final name = pathology.name?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      recommendations.add(
        Recommendation(
          id: 'pathology_condition_${pathology.pathologyId}',
          category: RecommendationCategory.informationVigilance,
          childId: childId,
          text: 'Pathologie : $name.',
        ),
      );
    }

    for (final allergy in essentialInformation.allergies) {
      // Laissée à MealsRules, qui la rattache au moment du repas.
      if (activity.hasMeal == true && allergy.concernsMeals) {
        continue;
      }

      final allergen = allergy.label?.trim();

      if (allergen == null || allergen.isEmpty) {
        continue;
      }

      final reaction = allergy.observedReaction?.trim();

      recommendations.add(
        Recommendation(
          id: 'allergy_condition_${allergy.allergyId}',
          category: RecommendationCategory.informationVigilance,
          childId: childId,
          text: reaction != null && reaction.isNotEmpty
              ? 'Allergie : $allergen — réaction : $reaction.'
              : 'Allergie : $allergen.',
          // Toujours critique, donc jamais masquable, qu'un traitement
          // d'urgence soit lié ou non à cette allergie (arbitrage
          // Fanny du 22/08/2026) : une allergie ne doit jamais pouvoir
          // disparaître d'une fiche. C'est ce qui préserve le
          // comportement d'avant la suppression de `_allergyTexts`,
          // dont les puces n'étaient pas masquables.
          isCritical: true,
        ),
      );
    }

    return recommendations;
  }
}
