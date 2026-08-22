import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../models/share_link_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import '../recommendation_engine/models/recommendation_category.dart';
import '../utils/treatment_audience.dart';

/// Construit la "photo" figée des recommandations d'un enfant pour une
/// activité donnée, au moment où le parent crée le lien de partage —
/// voir corrections_a_faire.md point 5. Le lien affichera ce contenu
/// tel quel, sans jamais le recalculer : le moteur de recommandations
/// n'existe qu'en Dart/Flutter, pas dans les Edge Functions Deno qui
/// servent le lien.
///
/// Corrigé (22/08/2026) : les allergies étaient ajoutées ici une
/// seconde fois, par une liste de textes reconstruite à la main à
/// partir du profil santé, alors que `HealthConditionsRules` les
/// produit déjà comme recommandations `informationVigilance`, reprises
/// par `textsFor`. Chaque allergie apparaissait donc en double dans
/// "Points importants" du lien partagé. Cette copie locale a été
/// supprimée : le moteur est la seule source.
class ActivityRecommendationSnapshot {
  static Map<String, dynamic> build({
    required CompleteActivitySessionData activitySession,
    required ActivityRecommendationResult recommendationResult,
    required CompleteChildProfileData child,
    required ShareDestinataire destinataire,
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

    final pointsImportants = [
      ...recommendationResult.globalRecommendations
          .where(
            (recommendation) =>
                recommendation.category ==
                RecommendationCategory.informationVigilance,
          )
          .map((recommendation) => recommendation.text),
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

    final medicationAudience = destinataire ==
            ShareDestinataire.structureAccueil
        ? TreatmentAudience.professionnel
        : TreatmentAudience.particulier;
    final medicationMention =
        treatmentMentionSuffix(medicationAudience);

    addSection(
      'Médicaments d’urgence',
      textsFor([RecommendationCategory.emergencyMedication])
          .map(
            (texte) => medicationMention == null
                ? texte
                : '$texte — $medicationMention',
          )
          .toList(),
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
