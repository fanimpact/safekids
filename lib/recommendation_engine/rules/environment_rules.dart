import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../../models/trigger_factor_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class EnvironmentRules {
  const EnvironmentRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;

    if (childId == null) {
      return recommendations;
    }

    final triggerFactors =
        child.essentialInformation.triggerFactors;

    // Hauteur
    if (activity.hasHeightActivity == true) {
      recommendations.addAll(
        heightRecommendations(childId, triggerFactors),
      );
    }

    // Animaux
    if (activity.hasAnimalContact == true) {
      recommendations.addAll(
        animalRecommendations(childId, triggerFactors),
      );
    }

    // Vigilance eau (facteur déclenchant, distinct des
    // réponses du profil activité aquatique).
    final hasWaterContext =
        activity.hasWaterNearby == true ||
            activity.childrenWillEnterWater == true;

    if (hasWaterContext) {
      recommendations.addAll(
        waterTriggerRecommendations(
          childId,
          triggerFactors,
        ),
      );
    }

    // Effort physique (facteur déclenchant, distinct de la
    // vigilance "effort physique intense" du profil marche).
    if (activity.hasSignificantPhysicalEffort == true) {
      final recommendation =
          physicalEffortRecommendation(
        childId,
        triggerFactors,
      );

      if (recommendation != null) {
        recommendations.add(recommendation);
      }
    }

    // Bruit
    if (activity.hasLoudEnvironment == true) {
      final recommendation =
          noiseRecommendation(childId, triggerFactors);

      if (recommendation != null) {
        recommendations.add(recommendation);
      }
    }

    // Foule
    if (activity.hasLargeCrowd == true) {
      final recommendation =
          crowdRecommendation(childId, triggerFactors);

      if (recommendation != null) {
        recommendations.add(recommendation);
      }
    }

    // Espaces confinés
    if (activity.hasConfinedSpace == true) {
      final recommendation =
          confinedSpaceRecommendation(
        childId,
        triggerFactors,
      );

      if (recommendation != null) {
        recommendations.add(recommendation);
      }
    }

    return recommendations;
  }

  /// Recommandations calculables uniquement à partir des facteurs
  /// déclenchants du profil santé, sans qu'une activité soit créée.
  /// Utilisées par la fiche "Ce qu'il faut savoir sur..." pour afficher,
  /// à côté de chaque facteur déclaré, la même recommandation que celle
  /// normalement générée lors de la préparation d'une activité — plutôt
  /// que de dupliquer ces textes à un second endroit.
  List<Recommendation> heightRecommendations(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.height != true) {
      return [];
    }

    switch (triggerFactors.heightVigilance) {
      case HeightVigilance.doesNotPerceiveDanger:
        return [
          Recommendation(
            id: 'height_does_not_perceive_danger',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'L’enfant ne perçoit pas le danger lié à la hauteur.',
            isCritical: true,
          ),
        ];

      case HeightVigilance.vertigoOrImportantFear:
        return [
          Recommendation(
            id: 'height_vertigo_or_important_fear',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'L’enfant présente un vertige ou une peur importante de la hauteur.',
          ),
        ];

      case HeightVigilance.other:
        final details =
            triggerFactors.otherHeightVigilance?.trim();

        if (details == null || details.isEmpty) {
          return [];
        }

        return [
          Recommendation(
            id: 'height_other_vigilance',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text: details,
          ),
        ];

      case null:
        return [];
    }
  }

  List<Recommendation> animalRecommendations(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.animals != true) {
      return [];
    }

    switch (triggerFactors.animalVigilance) {
      case AnimalVigilance.importantFear:
        return [
          Recommendation(
            id: 'animals_important_fear',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'L’enfant présente une peur importante des animaux.',
          ),
        ];

      case AnimalVigilance.approachesWithoutPerceivingDanger:
        return [
          Recommendation(
            id:
                'animals_approaches_without_perceiving_danger',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'L’enfant peut approcher les animaux sans percevoir le danger.',
            isCritical: true,
          ),
        ];

      case AnimalVigilance.other:
        final details =
            triggerFactors.otherAnimalVigilance?.trim();

        if (details == null || details.isEmpty) {
          return [];
        }

        return [
          Recommendation(
            id: 'animals_other_vigilance',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text: details,
          ),
        ];

      case null:
        return [];
    }
  }

  List<Recommendation> waterTriggerRecommendations(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.waterContact != true) {
      return [];
    }

    switch (triggerFactors.waterVigilance) {
      case WaterVigilance.mayJumpIntoWater:
        return [
          Recommendation(
            id: 'trigger_water_may_jump_into_water',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'Facteur déclenchant signalé par la famille : risque de se jeter dans l’eau.',
            isCritical: true,
          ),
        ];

      case WaterVigilance.cannotSwim:
        return [
          Recommendation(
            id: 'trigger_water_cannot_swim',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text:
                'Facteur déclenchant signalé par la famille : l’enfant ne sait pas nager.',
            isCritical: true,
          ),
        ];

      case WaterVigilance.other:
        final details =
            triggerFactors.otherWaterVigilance?.trim();

        if (details == null || details.isEmpty) {
          return [];
        }

        return [
          Recommendation(
            id: 'trigger_water_other_vigilance',
            category:
                RecommendationCategory.informationVigilance,
            childId: childId,
            text: details,
          ),
        ];

      case null:
        return [];
    }
  }

  Recommendation? physicalEffortRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.physicalEffort != true) {
      return null;
    }

    return Recommendation(
      id: 'trigger_physical_effort_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text:
          'Effort physique signalé comme facteur déclenchant : vigilance particulière.',
      isCritical: true,
    );
  }

  Recommendation? noiseRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.noise != true) {
      return null;
    }

    return Recommendation(
      id: 'noise_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text: 'Bruit : vigilance particulière.',
    );
  }

  Recommendation? crowdRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.crowd != true) {
      return null;
    }

    return Recommendation(
      id: 'crowd_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text: 'Foule : vigilance particulière.',
    );
  }

  Recommendation? confinedSpaceRecommendation(
    String? childId,
    TriggerFactorData triggerFactors,
  ) {
    if (triggerFactors.confinedSpaces != true) {
      return null;
    }

    return Recommendation(
      id: 'confined_space_vigilance',
      category: RecommendationCategory.informationVigilance,
      childId: childId,
      text: 'Espaces confinés : vigilance particulière.',
    );
  }
}
