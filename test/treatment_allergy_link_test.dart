import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/allergy_data.dart';

void main() {
  test(
    'Un traitement quotidien peut être lié à plusieurs allergies',
    () {
      final controller = TransmissionController();

      controller.ensureFirstAllergy();
      controller.updateAllergyCategory(
        0,
        AllergyCategory.insectSting,
        true,
      );
      controller.updateAllergyDetail(
        0,
        AllergyCategory.insectSting,
        'Piqûres de guêpe',
      );

      controller.addAllergy();
      controller.updateAllergyCategory(
        1,
        AllergyCategory.food,
        true,
      );
      controller.updateAllergyDetail(
        1,
        AllergyCategory.food,
        'Arachide',
      );

      controller.ensureFirstDailyTreatment();
      controller.updateDailyTreatmentName(
        0,
        'Traitement quotidien test',
      );

      final allergies =
          controller.formData.allergies;

      final waspId =
          allergies[0].allergyId;

      final peanutId =
          allergies[1].allergyId;

      controller.updateDailyTreatmentAllergy(
        0,
        waspId,
        true,
      );

      controller.updateDailyTreatmentAllergy(
        0,
        peanutId,
        true,
      );

      final treatment =
          controller.formData.dailyTreatments[0];

      expect(
        treatment.relatedAllergyIds,
        contains(waspId),
      );

      expect(
        treatment.relatedAllergyIds,
        contains(peanutId),
      );

      expect(
        treatment.relatedAllergyIds.length,
        2,
      );
    },
  );

  test(
    'Un traitement d’urgence peut être lié à une seule allergie',
    () {
      final controller = TransmissionController();

      controller.ensureFirstAllergy();
      controller.updateAllergyCategory(
        0,
        AllergyCategory.insectSting,
        true,
      );
      controller.updateAllergyDetail(
        0,
        AllergyCategory.insectSting,
        'Piqûres de guêpe',
      );

      controller.addAllergy();
      controller.updateAllergyCategory(
        1,
        AllergyCategory.food,
        true,
      );
      controller.updateAllergyDetail(
        1,
        AllergyCategory.food,
        'Arachide',
      );

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentName(
        0,
        'Desloratadine',
      );

      final allergies =
          controller.formData.allergies;

      final waspId =
          allergies[0].allergyId;

      final peanutId =
          allergies[1].allergyId;

      controller.updateEmergencyTreatmentAllergy(
        0,
        waspId,
        true,
      );

      final treatment =
          controller.formData.emergencyTreatments[0];

      expect(
        treatment.relatedAllergyIds,
        contains(waspId),
      );

      expect(
        treatment.relatedAllergyIds,
        isNot(
          contains(peanutId),
        ),
      );
    },
  );

  test(
    'Plusieurs traitements peuvent être liés à la même allergie',
    () {
      final controller = TransmissionController();

      controller.ensureFirstAllergy();
      controller.updateAllergyCategory(
        0,
        AllergyCategory.insectSting,
        true,
      );
      controller.updateAllergyDetail(
        0,
        AllergyCategory.insectSting,
        'Piqûres de guêpe',
      );

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentName(
        0,
        'Desloratadine',
      );

      controller.addEmergencyTreatment();
      controller.updateEmergencyTreatmentName(
        1,
        'Solupred',
      );

      final allergyId =
          controller
              .formData
              .allergies[0]
              .allergyId;

      controller.updateEmergencyTreatmentAllergy(
        0,
        allergyId,
        true,
      );

      controller.updateEmergencyTreatmentAllergy(
        1,
        allergyId,
        true,
      );

      expect(
        controller
            .formData
            .emergencyTreatments[0]
            .relatedAllergyIds,
        contains(allergyId),
      );

      expect(
        controller
            .formData
            .emergencyTreatments[1]
            .relatedAllergyIds,
        contains(allergyId),
      );
    },
  );

  test(
    'Supprimer une allergie supprime aussi ses liens dans les traitements',
    () {
      final controller = TransmissionController();

      controller.ensureFirstAllergy();
      controller.updateAllergyCategory(
        0,
        AllergyCategory.insectSting,
        true,
      );
      controller.updateAllergyDetail(
        0,
        AllergyCategory.insectSting,
        'Piqûres de guêpe',
      );

      controller.addAllergy();
      controller.updateAllergyCategory(
        1,
        AllergyCategory.food,
        true,
      );
      controller.updateAllergyDetail(
        1,
        AllergyCategory.food,
        'Arachide',
      );

      controller.ensureFirstDailyTreatment();
      controller.ensureFirstEmergencyTreatment();

      final waspId =
          controller
              .formData
              .allergies[0]
              .allergyId;

      final peanutId =
          controller
              .formData
              .allergies[1]
              .allergyId;

      controller.updateDailyTreatmentAllergy(
        0,
        waspId,
        true,
      );

      controller.updateDailyTreatmentAllergy(
        0,
        peanutId,
        true,
      );

      controller.updateEmergencyTreatmentAllergy(
        0,
        waspId,
        true,
      );

      controller.updateEmergencyTreatmentAllergy(
        0,
        peanutId,
        true,
      );

      controller.removeAllergy(0);

      final dailyTreatment =
          controller.formData.dailyTreatments[0];

      final emergencyTreatment =
          controller.formData.emergencyTreatments[0];

      expect(
        dailyTreatment.relatedAllergyIds,
        isNot(
          contains(waspId),
        ),
      );

      expect(
        emergencyTreatment.relatedAllergyIds,
        isNot(
          contains(waspId),
        ),
      );

      expect(
        dailyTreatment.relatedAllergyIds,
        contains(peanutId),
      );

      expect(
        emergencyTreatment.relatedAllergyIds,
        contains(peanutId),
      );
    },
  );
}