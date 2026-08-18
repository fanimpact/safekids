import '../../models/complete_child_profile_data.dart';
import '../../models/trigger_factor_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

/// Comme `EnvironmentRules`, expose ses recommandations via des
/// méthodes publiques, appelées à la fois par `evaluate()` (pour la
/// fiche de recommandations d'activité) et directement par la fiche
/// secours et "Ce qu'il faut savoir sur..." — source unique de
/// formulation, corrigée le 19/08/2026 (voir le commentaire
/// équivalent dans environment_rules.dart).
class UniversalTriggerRules {
  const UniversalTriggerRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    if (childId == null) {
      return recommendations;
    }

    recommendations.addAll(
      photosensitivityRecommendations(
        childId,
        triggerFactors,
      ),
    );

    final heat = heatRecommendation(
      childId,
      triggerFactors,
    );

    if (heat != null) {
      recommendations.add(heat);
    }

    final stress = stressRecommendation(
      childId,
      triggerFactors,
    );

    if (stress != null) {
      recommendations.add(stress);
    }

    final fatigue = fatigueRecommendation(
      childId,
      triggerFactors,
    );

    if (fatigue != null) {
      recommendations.add(fatigue);
    }

    final other = otherTriggerFactorRecommendation(
      childId,
      triggerFactors,
    );

    if (other != null) {
      recommendations.add(other);
    }

    return recommendations;
  }

  /// Toujours deux recommandations distinctes quand les lunettes sont
  /// nécessaires (validé par Fanny le 19/08/2026) : une vigilance
  /// générale, une seconde pour l'équipement — jamais fusionnées en
  /// une seule ligne.
  List<Recommendation> photosensitivityRecommendations(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.flashingLights != true) {
      return [];
    }

    final recommendations = [
      Recommendation(
        id: 'photosensitivity',
        category:
            RecommendationCategory.informationVigilance,
        childId: childId,
        text:
            'Photosensibilité : vigilance avec les lumières, reflets et alternances ombre/lumière.',
        isCritical: true,
      ),
    ];

    if (triggerFactors.requiresGlassesOutdoors == true) {
      recommendations.add(
        Recommendation(
          id: 'photosensitivity_glasses',
          category: RecommendationCategory.equipment,
          childId: childId,
          text:
              'Lunettes adaptées à la photosensibilité.',
          isCritical: true,
        ),
      );
    }

    return recommendations;
  }

  Recommendation? heatRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.heat != true) {
      return null;
    }

    return Recommendation(
      id: 'heat_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text: 'Chaleur : vigilance particulière.',
    );
  }

  Recommendation? stressRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.stressOrStrongEmotions != true) {
      return null;
    }

    return Recommendation(
      id: 'stress_strong_emotions_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text:
          'Stress ou émotions fortes : vigilance particulière.',
    );
  }

  Recommendation? fatigueRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.fatigueOrLackOfSleep != true) {
      return null;
    }

    return Recommendation(
      id: 'fatigue_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text:
          'Fatigue ou manque de sommeil : vigilance particulière.',
    );
  }

  Recommendation? otherTriggerFactorRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    final otherTriggerFactor = triggerFactors.other?.trim();

    if (otherTriggerFactor == null ||
        otherTriggerFactor.isEmpty) {
      return null;
    }

    return Recommendation(
      id: 'other_trigger_factor',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text: 'Autre : $otherTriggerFactor',
    );
  }
}
