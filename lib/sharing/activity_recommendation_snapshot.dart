import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import '../recommendation_engine/models/recommendation_category.dart';

/// Construit la "photo" figée des recommandations d'un enfant pour une
/// activité donnée, au moment où le parent crée le lien de partage —
/// voir corrections_a_faire.md point 5. Le lien affichera ce contenu
/// tel quel, sans jamais le recalculer : le moteur de recommandations
/// n'existe qu'en Dart/Flutter, pas dans les Edge Functions Deno qui
/// servent le lien.
class ActivityRecommendationSnapshot {
  static Map<String, dynamic> build({
    required CompleteActivitySessionData activitySession,
    required ActivityRecommendationResult recommendationResult,
    required CompleteChildProfileData child,
  }) {
    final childId = child.childId;

    final recommendations = recommendationResult.childResults
        .where((result) => result.childId == childId)
        .expand((result) => result.recommendations)
        .toList();

    List<String> textsFor(
      List<RecommendationCategory> categories,
    ) {
      return recommendations
          .where(
            (recommendation) =>
                categories.contains(recommendation.category),
          )
          .map((recommendation) => recommendation.text)
          .toList();
    }

    final allergyTexts = child.essentialInformation.allergies
        .map((allergy) {
          final allergen = allergy.allergen?.trim();

          if (allergen == null || allergen.isEmpty) {
            return null;
          }

          final reaction = allergy.observedReaction?.trim();

          return (reaction != null && reaction.isNotEmpty)
              ? 'Allergie : $allergen — Réaction connue : $reaction'
              : 'Allergie : $allergen';
        })
        .whereType<String>()
        .toList();

    final pointsImportants = [
      ...recommendationResult.globalRecommendations
          .where(
            (recommendation) =>
                recommendation.category ==
                RecommendationCategory.informationVigilance,
          )
          .map((recommendation) => recommendation.text),
      ...allergyTexts,
      ...textsFor([
        RecommendationCategory.informationVigilance,
        RecommendationCategory.additionalInformation,
      ]),
    ];

    final sections = <Map<String, dynamic>>[];

    void addSection(String titre, List<String> lignes) {
      if (lignes.isEmpty) {
        return;
      }

      sections.add({'titre': titre, 'lignes': lignes});
    }

    addSection('Points importants', pointsImportants);

    addSection(
      'Médicaments d’urgence',
      textsFor([RecommendationCategory.emergencyMedication]),
    );

    addSection(
      'Adaptations à prévoir',
      textsFor([RecommendationCategory.adaptation]),
    );

    addSection(
      'Matériel à prévoir',
      textsFor([
        RecommendationCategory.equipment,
        RecommendationCategory.rememberToTake,
      ]),
    );

    return {
      'activite_nom': activitySession.activityName,
      'activite_date':
          activitySession.date?.toUtc().toIso8601String(),
      'activite_lieu': activitySession.location,
      'sections': sections,
    };
  }
}
