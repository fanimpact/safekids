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
              id: 'animals_approaches_without_perceiving_danger',
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

    // Bruit
    if (activity.hasLoudEnvironment == true &&
        triggerFactors.noise) {
      recommendations.add(
        Recommendation(
          id: 'noise_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Le bruit nécessite une vigilance particulière.',
        ),
      );
    }

    // Foule
    if (activity.hasLargeCrowd == true &&
        triggerFactors.crowd) {
      recommendations.add(
        Recommendation(
          id: 'crowd_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'La foule nécessite une vigilance particulière.',
        ),
      );
    }

    // Espaces confinés
    if (activity.hasConfinedSpace == true &&
        triggerFactors.confinedSpaces) {
      recommendations.add(
        Recommendation(
          id: 'confined_space_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Les espaces confinés nécessitent une vigilance particulière.',
        ),
      );
    }

    return recommendations;
  }
}