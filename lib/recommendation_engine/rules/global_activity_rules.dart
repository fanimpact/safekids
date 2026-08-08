import '../../models/activity_session/activity_answer.dart';
import '../../models/activity_session/activity_session_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class GlobalActivityRules {
  const GlobalActivityRules();

  List<Recommendation> evaluate(
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final phoneNetworkMayBeUnavailable =
        activity.phoneNetworkMayBeUnavailable;

    if (phoneNetworkMayBeUnavailable ==
            ActivityThreeStateAnswer.yes ||
        phoneNetworkMayBeUnavailable ==
            ActivityThreeStateAnswer.unknown) {
      recommendations.add(
        const Recommendation(
          id: 'phone_network_may_be_unavailable',
          category:
              RecommendationCategory.informationVigilance,
          text:
              'Le réseau téléphonique peut être indisponible. Prévoir une solution permettant d’alerter les secours.',
        ),
      );
    }

    return recommendations;
  }
}