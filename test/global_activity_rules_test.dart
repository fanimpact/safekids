import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/activity_session/activity_answer.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/recommendation_engine/models/recommendation_category.dart';
import 'package:kidsrelay/recommendation_engine/rules/global_activity_rules.dart';

void main() {
  const rules = GlobalActivityRules();

  test(
    'Réseau - indisponibilité possible génère une vigilance globale',
    () {
      final activity = ActivitySessionData(
        phoneNetworkMayBeUnavailable:
            ActivityThreeStateAnswer.yes,
      );

      final recommendations = rules.evaluate(activity);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.id,
        'phone_network_may_be_unavailable',
      );

      expect(
        recommendations.first.category,
        RecommendationCategory.informationVigilance,
      );

      expect(
        recommendations.first.childId,
        isNull,
      );
    },
  );

  test(
    'Réseau - situation inconnue génère aussi une vigilance globale',
    () {
      final activity = ActivitySessionData(
        phoneNetworkMayBeUnavailable:
            ActivityThreeStateAnswer.unknown,
      );

      final recommendations = rules.evaluate(activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('phone_network_may_be_unavailable'),
      );
    },
  );

  test(
    'Réseau - disponible ne génère aucune recommandation',
    () {
      final activity = ActivitySessionData(
        phoneNetworkMayBeUnavailable:
            ActivityThreeStateAnswer.no,
      );

      final recommendations = rules.evaluate(activity);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );

  test(
    'Réseau - absence de réponse ne génère rien',
    () {
      final activity = ActivitySessionData(
        phoneNetworkMayBeUnavailable: null,
      );

      final recommendations = rules.evaluate(activity);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}