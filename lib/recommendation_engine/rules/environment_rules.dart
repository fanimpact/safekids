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
    if (activity.hasHeightActivity == true &&
        triggerFactors.height) {
      switch (triggerFactors.heightVigilance) {
        case HeightVigilance.doesNotPerceiveDanger:
          recommendations.add(
            Recommendation(
              id: 'height_does_not_perceive_danger',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'L’enfant ne perçoit pas le danger lié à la hauteur.',
            ),
          );
          break;

        case HeightVigilance.vertigoOrImportantFear:
          recommendations.add(
            Recommendation(
              id: 'height_vertigo_or_important_fear',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'L’enfant présente un vertige ou une peur importante de la hauteur.',
            ),
          );
          break;

        case HeightVigilance.other:
          final details =
              triggerFactors.otherHeightVigilance?.trim();

          if (details != null && details.isNotEmpty) {
            recommendations.add(
              Recommendation(
                id: 'height_other_vigilance',
                category:
                    RecommendationCategory.informationVigilance,
                childId: childId,
                text: details,
              ),
            );
          }
          break;

        case null:
          break;
      }
    }

    // Animaux
    if (activity.hasAnimalContact == true &&
        triggerFactors.animals) {
      switch (triggerFactors.animalVigilance) {
        case AnimalVigilance.importantFear:
          recommendations.add(
            Recommendation(
              id: 'animals_important_fear',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'L’enfant présente une peur importante des animaux.',
            ),
          );
          break;

        case AnimalVigilance.approachesWithoutPerceivingDanger:
          recommendations.add(
            Recommendation(
              id:
                  'animals_approaches_without_perceiving_danger',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'L’enfant peut approcher les animaux sans percevoir le danger.',
            ),
          );
          break;

        case AnimalVigilance.other:
          final details =
              triggerFactors.otherAnimalVigilance?.trim();

          if (details != null && details.isNotEmpty) {
            recommendations.add(
              Recommendation(
                id: 'animals_other_vigilance',
                category:
                    RecommendationCategory.informationVigilance,
                childId: childId,
                text: details,
              ),
            );
          }
          break;

        case null:
          break;
      }
    }

    // Vigilance eau (facteur déclenchant, distinct des
    // réponses du profil activité aquatique).
    final hasWaterContext =
        activity.hasWaterNearby == true ||
            activity.childrenWillEnterWater == true;

    if (hasWaterContext && triggerFactors.waterContact) {
      switch (triggerFactors.waterVigilance) {
        case WaterVigilance.mayJumpIntoWater:
          recommendations.add(
            Recommendation(
              id: 'trigger_water_may_jump_into_water',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'Facteur déclenchant signalé par la famille : risque de se jeter dans l’eau.',
            ),
          );
          break;

        case WaterVigilance.cannotSwim:
          recommendations.add(
            Recommendation(
              id: 'trigger_water_cannot_swim',
              category:
                  RecommendationCategory.informationVigilance,
              childId: childId,
              text:
                  'Facteur déclenchant signalé par la famille : l’enfant ne sait pas nager.',
            ),
          );
          break;

        case WaterVigilance.other:
          final details =
              triggerFactors.otherWaterVigilance?.trim();

          if (details != null && details.isNotEmpty) {
            recommendations.add(
              Recommendation(
                id: 'trigger_water_other_vigilance',
                category:
                    RecommendationCategory.informationVigilance,
                childId: childId,
                text: details,
              ),
            );
          }
          break;

        case null:
          break;
      }
    }

    // Effort physique (facteur déclenchant, distinct de la
    // vigilance "effort physique intense" du profil marche).
    if (activity.hasSignificantPhysicalEffort == true &&
        triggerFactors.physicalEffort == true) {
      recommendations.add(
        Recommendation(
          id: 'trigger_physical_effort_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Effort physique signalé comme facteur déclenchant : vigilance particulière.',
        ),
      );
    }

    // Bruit
    if (activity.hasLoudEnvironment == true &&
        triggerFactors.noise == true) {
      recommendations.add(
        Recommendation(
          id: 'noise_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text: 'Bruit : vigilance particulière.',
        ),
      );
    }

    // Foule
    if (activity.hasLargeCrowd == true &&
        triggerFactors.crowd == true) {
      recommendations.add(
        Recommendation(
          id: 'crowd_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text: 'Foule : vigilance particulière.',
        ),
      );
    }

    // Espaces confinés
    if (activity.hasConfinedSpace == true &&
        triggerFactors.confinedSpaces == true) {
      recommendations.add(
        Recommendation(
          id: 'confined_space_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Espaces confinés : vigilance particulière.',
        ),
      );
    }

    return recommendations;
  }
}