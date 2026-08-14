import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../../models/trigger_factor_data.dart';
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

    if (!aquaticActivity.requiresAdaptations) {
      return recommendations;
    }

    // Informations communes dès qu'il y a
    // un contexte lié à l'eau.

    final waterVigilance =
        child.essentialInformation.triggerFactors.waterVigilance;

    if (waterVigilance == WaterVigilance.cannotSwim) {
      recommendations.add(
        Recommendation(
          id: 'water_cannot_swim',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text: 'L’enfant ne sait pas nager.',
        ),
      );
    }

    if (aquaticActivity.mayJumpIntoWater) {
      recommendations.add(
        Recommendation(
          id: 'water_may_jump_into_water',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text: 'L’enfant peut se jeter dans l’eau.',
        ),
      );
    }

    // À proximité d'un point d'eau.

    if (hasWaterNearby &&
        aquaticActivity
            .requiresFlotationVestNearWater) {
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
                    .requiresDedicatedAdultNearWater) ||
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
      if (aquaticActivity
          .requiresSpecialEquipment) {
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

      if (aquaticActivity
          .requiresAdaptedSupervision) {
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

      if (aquaticActivity
          .requiresOtherAdaptation) {
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