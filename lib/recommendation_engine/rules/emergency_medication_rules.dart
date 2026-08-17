import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class EmergencyMedicationRules {
  const EmergencyMedicationRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;

    if (childId == null) {
      return recommendations;
    }

    final essentialInformation =
        child.essentialInformation;

    for (var index = 0;
        index <
            essentialInformation
                .emergencyTreatments
                .length;
        index++) {
      final treatment =
          essentialInformation
              .emergencyTreatments[index];

      final medicationName =
          treatment.medicationName?.trim();

      if (medicationName == null ||
          medicationName.isEmpty) {
        continue;
      }

      final relatedLabels = <String>[];

      for (final pathologyId
          in treatment.relatedPathologyIds) {
        final matchingPathologies =
            essentialInformation.pathologies.where(
          (pathology) =>
              pathology.pathologyId ==
              pathologyId,
        );

        if (matchingPathologies.isEmpty) {
          continue;
        }

        final pathologyName =
            matchingPathologies
                .first
                .name
                ?.trim();

        if (pathologyName != null &&
            pathologyName.isNotEmpty) {
          relatedLabels.add(
            pathologyName,
          );
        }
      }

      for (final allergyId
          in treatment.relatedAllergyIds) {
        final matchingAllergies =
            essentialInformation.allergies.where(
          (allergy) =>
              allergy.allergyId ==
              allergyId,
        );

        if (matchingAllergies.isEmpty) {
          continue;
        }

        final allergen =
            matchingAllergies
                .first
                .allergen
                ?.trim();

        if (allergen != null &&
            allergen.isNotEmpty) {
          relatedLabels.add(
            allergen,
          );
        }
      }

      final details = <String>[];

      final dosage =
          treatment.dosage?.trim();

      final administrationMethod =
          treatment
              .administrationMethod
              ?.trim();

      if (dosage != null &&
          dosage.isNotEmpty) {
        details.add(
          'Dosage : $dosage',
        );
      }

      if (administrationMethod != null &&
          administrationMethod.isNotEmpty) {
        details.add(
          'Mode d’administration : '
          '$administrationMethod',
        );
      }

      final context =
          relatedLabels.isEmpty
              ? null
              : ' (${relatedLabels.join(' / ')})';

      final base =
          'Pensez à emporter le traitement d’urgence : '
          '$medicationName${context ?? ''}';

      final text =
          details.isEmpty
              ? base
              : '$base — ${details.join(' — ')}';

      recommendations.add(
        Recommendation(
          id:
              'emergency_treatment_$index',
          category:
              RecommendationCategory
                  .emergencyMedication,
          childId: childId,
          text: text,
        ),
      );
    }

    return recommendations;
  }
}