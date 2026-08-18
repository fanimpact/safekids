import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class WalkingEffortRules {
  const WalkingEffortRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final walkingEffort =
        child.activityProfile?.walkingEffort;

    if (childId == null || walkingEffort == null) {
      return recommendations;
    }

    if (activity.hasProlongedWalking == true &&
        walkingEffort
                .prolongedWalkingRequiresVigilance ==
            true) {
      recommendations.add(
        Recommendation(
          id: 'prolonged_walking_vigilance',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'Marche prolongée : vigilance particulière.',
        ),
      );
    }

    // Corrigé (19/08/2026) : le facteur déclenchant "effort physique"
    // du profil santé (EnvironmentRules.physicalEffortRecommendation,
    // critique) et cette question du profil activités décrivaient la
    // même vigilance sous la même condition d'activité, générant
    // deux recommandations quasi identiques quand les deux étaient
    // renseignées. Même principe déjà appliqué à l'eau (voir
    // water_rules.dart) : le facteur déclenchant du profil santé,
    // marqué critique, prime — cette question ne génère sa propre
    // recommandation que si le profil santé n'a pas déjà signalé le
    // même risque.
    if (activity.hasSignificantPhysicalEffort ==
            true &&
        walkingEffort
                .intensePhysicalEffortRequiresVigilance ==
            true &&
        child.essentialInformation.triggerFactors
                .physicalEffort !=
            true) {
      recommendations.add(
        Recommendation(
          id:
              'intense_physical_effort_vigilance',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'Effort physique intense : vigilance particulière.',
        ),
      );
    }

    return recommendations;
  }
}