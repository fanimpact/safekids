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
class HealthConditionsRules {
  const HealthConditionsRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
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
      final allergen = allergy.allergen?.trim();

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
        ),
      );
    }

    return recommendations;
  }
}
