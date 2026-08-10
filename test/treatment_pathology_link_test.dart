import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/controllers/transmission_controller.dart';

void main() {
  test(
    'Un traitement quotidien peut être lié à plusieurs pathologies',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(
        0,
        'Épilepsie',
      );

      controller.addPathology();
      controller.updatePathologyName(
        1,
        'Asthme',
      );

      controller.ensureFirstDailyTreatment();
      controller.updateDailyTreatmentName(
        0,
        'Traitement quotidien test',
      );

      final pathologies =
          controller.formData.pathologies;

      final epilepsyId =
          pathologies[0].pathologyId;

      final asthmaId =
          pathologies[1].pathologyId;

      controller.updateDailyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );

      controller.updateDailyTreatmentPathology(
        0,
        asthmaId,
        true,
      );

      final treatment =
          controller.formData.dailyTreatments[0];

      expect(
        treatment.relatedPathologyIds,
        contains(epilepsyId),
      );

      expect(
        treatment.relatedPathologyIds,
        contains(asthmaId),
      );

      expect(
        treatment.relatedPathologyIds.length,
        2,
      );
    },
  );

  test(
    'Un traitement d’urgence peut être lié à une seule pathologie',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(
        0,
        'Épilepsie',
      );

      controller.addPathology();
      controller.updatePathologyName(
        1,
        'Asthme',
      );

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentName(
        0,
        'Buccolam',
      );

      final pathologies =
          controller.formData.pathologies;

      final epilepsyId =
          pathologies[0].pathologyId;

      final asthmaId =
          pathologies[1].pathologyId;

      controller.updateEmergencyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );

      final treatment =
          controller.formData.emergencyTreatments[0];

      expect(
        treatment.relatedPathologyIds,
        contains(epilepsyId),
      );

      expect(
        treatment.relatedPathologyIds,
        isNot(
          contains(asthmaId),
        ),
      );

      expect(
        treatment.relatedPathologyIds.length,
        1,
      );
    },
  );

  test(
    'Une pathologie peut être décochée d’un traitement',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(
        0,
        'Épilepsie',
      );

      controller.ensureFirstEmergencyTreatment();

      final pathologyId =
          controller
              .formData
              .pathologies[0]
              .pathologyId;

      controller.updateEmergencyTreatmentPathology(
        0,
        pathologyId,
        true,
      );

      controller.updateEmergencyTreatmentPathology(
        0,
        pathologyId,
        false,
      );

      final treatment =
          controller.formData.emergencyTreatments[0];

      expect(
        treatment.relatedPathologyIds,
        isEmpty,
      );
    },
  );

  test(
    'Supprimer une pathologie supprime aussi ses liens dans les traitements',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(
        0,
        'Épilepsie',
      );

      controller.addPathology();
      controller.updatePathologyName(
        1,
        'Asthme',
      );

      controller.ensureFirstDailyTreatment();
      controller.ensureFirstEmergencyTreatment();

      final epilepsyId =
          controller
              .formData
              .pathologies[0]
              .pathologyId;

      final asthmaId =
          controller
              .formData
              .pathologies[1]
              .pathologyId;

      controller.updateDailyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );

      controller.updateDailyTreatmentPathology(
        0,
        asthmaId,
        true,
      );

      controller.updateEmergencyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );

      controller.updateEmergencyTreatmentPathology(
        0,
        asthmaId,
        true,
      );

      controller.removePathology(0);

      final dailyTreatment =
          controller.formData.dailyTreatments[0];

      final emergencyTreatment =
          controller.formData.emergencyTreatments[0];

      expect(
        dailyTreatment.relatedPathologyIds,
        isNot(
          contains(epilepsyId),
        ),
      );

      expect(
        emergencyTreatment.relatedPathologyIds,
        isNot(
          contains(epilepsyId),
        ),
      );

      expect(
        dailyTreatment.relatedPathologyIds,
        contains(asthmaId),
      );

      expect(
        emergencyTreatment.relatedPathologyIds,
        contains(asthmaId),
      );
    },
  );
}