import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class CommunicationRules {
  const CommunicationRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final communication =
        child.activityProfile?.communication;

    if (childId == null || communication == null) {
      return recommendations;
    }

    if (communication.useSimpleInstructions) {
      recommendations.add(
        Recommendation(
          id: 'communication_simple_instructions',
          category:
              RecommendationCategory.adaptation,
          childId: childId,
          text: 'Utiliser des consignes simples.',
        ),
      );
    }

    // Si l'une des deux situations est présente,
    // ou si les deux le sont, une seule recommandation
    // est générée.
    if (communication.mayAppearToUnderstand == true ||
        communication.verifyUnderstandingIndividually) {
      recommendations.add(
        Recommendation(
          id: 'communication_verify_understanding',
          category:
              RecommendationCategory.adaptation,
          childId: childId,
          text: 'Vérifier sa compréhension.',
        ),
      );
    }

    if (communication.usesCommunicationSupport == true) {
      final supportDetails =
          communication
              .communicationSupportDetails
              ?.trim();

      if (supportDetails != null &&
          supportDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'communication_support',
            category:
                RecommendationCategory.equipment,
            childId: childId,
            text: supportDetails,
          ),
        );
      }
    }

    return recommendations;
  }
}