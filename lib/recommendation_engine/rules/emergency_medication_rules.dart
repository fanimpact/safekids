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

    final essentialInformation = child.essentialInformation;

    for (var index = 0;
        index < essentialInformation.emergencyTreatments.length;
        index++) {
      final treatment =
          essentialInformation.emergencyTreatments[index];

      final medicationName = treatment.medicationName?.trim();

      if (medicationName == null || medicationName.isEmpty) {
        continue;
      }

      final details = <String>[];

      final dosage = treatment.dosage?.trim();
      final administrationCondition =
          treatment.administrationCondition?.trim();
      final administrationMethod =
          treatment.administrationMethod?.trim();

      if (dosage != null && dosage.isNotEmpty) {
        details.add('Dosage : $dosage');
      }

      if (administrationCondition != null &&
          administrationCondition.isNotEmpty) {
        details.add(
          'Condition d’administration : $administrationCondition',
        );
      }

      if (administrationMethod != null &&
          administrationMethod.isNotEmpty) {
        details.add(
          'Mode d’administration : $administrationMethod',
        );
      }

      final text = details.isEmpty
          ? medicationName
          : '$medicationName — ${details.join(' — ')}';

      recommendations.add(
        Recommendation(
          id: 'emergency_treatment_$index',
          category:
              RecommendationCategory.emergencyMedication,
          childId: childId,
          text: text,
        ),
      );
    }

    for (var index = 0;
        index < essentialInformation.allergies.length;
        index++) {
      final allergy = essentialInformation.allergies[index];

      if (allergy.hasEmergencyTreatment != true) {
        continue;
      }

      final medicationName =
          allergy.emergencyTreatmentName?.trim();

      if (medicationName == null || medicationName.isEmpty) {
        continue;
      }

      final details = <String>[];

      final dosage =
          allergy.emergencyTreatmentDosage?.trim();
      final allergen = allergy.allergen?.trim();

      if (dosage != null && dosage.isNotEmpty) {
        details.add('Dosage : $dosage');
      }

      if (allergen != null && allergen.isNotEmpty) {
        details.add('Allergie : $allergen');
      }

      final text = details.isEmpty
          ? medicationName
          : '$medicationName — ${details.join(' — ')}';

      recommendations.add(
        Recommendation(
          id: 'allergy_emergency_treatment_$index',
          category:
              RecommendationCategory.emergencyMedication,
          childId: childId,
          text: text,
        ),
      );
    }

    return recommendations;
  }
}