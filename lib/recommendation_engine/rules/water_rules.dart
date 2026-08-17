import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class WaterRules {
  const WaterRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final aquaticActivity =
        child.activityProfile?.aquaticActivity;

    if (childId == null || aquaticActivity == null) {
      return recommendations;
    }

    final hasWaterNearby =
        activity.hasWaterNearby == true;

    final hasSwimming =
        activity.childrenWillEnterWater == true;

    if (!hasWaterNearby && !hasSwimming) {
      return recommendations;
    }

    // Le fait que l'enfant ne sache pas nager / risque de se jeter
    // dans l'eau est un facteur déclenchant du profil santé : il est
    // déjà généré par EnvironmentRules (waterTriggerRecommendations),
    // sans dépendre des questions d'équipement/surveillance ci-dessous
    // — pour ne pas le dupliquer, et surtout pour ne jamais le faire
    // dépendre d'une case cochée ailleurs.

    // À proximité d'un point d'eau.

    if (hasWaterNearby &&
        aquaticActivity
                .requiresFlotationVestNearWater ==
            true) {
      recommendations.add(
        Recommendation(
          id: 'water_flotation_vest_near_water',
          category:
              RecommendationCategory.equipment,
          childId: childId,
          text: 'Gilet de flottaison.',
        ),
      );
    }

    final requiresDedicatedAdult =
        (hasWaterNearby &&
                aquaticActivity
                        .requiresDedicatedAdultNearWater ==
                    true) ||
            (hasSwimming &&
                aquaticActivity
                    .requiresDedicatedAdult);

    if (requiresDedicatedAdult) {
      recommendations.add(
        Recommendation(
          id: 'water_dedicated_adult',
          category:
              RecommendationCategory.adaptation,
          childId: childId,
          text: 'Prévoir un adulte dédié.',
        ),
      );
    }

    // Règles spécifiques à une baignade réelle.

    if (hasSwimming) {
      if (aquaticActivity.requiresSpecialEquipment ==
          true) {
        final equipmentDetails =
            aquaticActivity
                .specialEquipmentDetails
                ?.trim();

        if (equipmentDetails != null &&
            equipmentDetails.isNotEmpty) {
          recommendations.add(
            Recommendation(
              id:
                  'water_special_swimming_equipment',
              category:
                  RecommendationCategory.equipment,
              childId: childId,
              text: equipmentDetails,
            ),
          );
        }
      }

      // Une surveillance adaptée ne doit pas
      // produire une consigne vague.
      // On affiche uniquement la précision
      // renseignée par le parent.

      if (aquaticActivity.requiresAdaptedSupervision ==
          true) {
        final supervisionDetails =
            aquaticActivity
                .otherSupervisionDetails
                ?.trim();

        if (supervisionDetails != null &&
            supervisionDetails.isNotEmpty) {
          recommendations.add(
            Recommendation(
              id:
                  'water_adapted_supervision',
              category:
                  RecommendationCategory.adaptation,
              childId: childId,
              text: supervisionDetails,
            ),
          );
        }
      }

      if (aquaticActivity.notifyLifeguard &&
          activity
                  .swimmingSupervisedByLifeguard ==
              true) {
        recommendations.add(
          Recommendation(
            id: 'water_notify_lifeguard',
            category:
                RecommendationCategory.adaptation,
            childId: childId,
            text:
                'Prévenir le maître-nageur.',
          ),
        );
      }

      // Autre adaptation importante :
      // reprendre exactement la précision
      // renseignée dans le profil parent.

      if (aquaticActivity.requiresOtherAdaptation ==
          true) {
        final adaptationDetails =
            aquaticActivity
                .otherAdaptationDetails
                ?.trim();

        if (adaptationDetails != null &&
            adaptationDetails.isNotEmpty) {
          recommendations.add(
            Recommendation(
              id: 'water_other_adaptation',
              category:
                  RecommendationCategory.adaptation,
              childId: childId,
              text: adaptationDetails,
            ),
          );
        }
      }
    }

    return recommendations;
  }
}