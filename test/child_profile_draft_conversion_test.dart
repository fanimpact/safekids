import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/child_profile_draft.dart';

void main() {
  test(
    'fromChildProfileData conserve childId, pathologyId, allergyId et les étapes d’urgence',
    () {
      final controller = TransmissionController();

      controller.formData.identity.firstName = 'Théo';

      controller.ensureFirstPathology();
      controller.updatePathologyName(0, 'Épilepsie');
      controller.addPathologyEmergencyStep(0);
      controller.updatePathologyEmergencyStep(
        0,
        0,
        'Mettre en position latérale de sécurité',
      );
      controller.addPathologyEmergencyStep(0);
      controller.updatePathologyEmergencyStep(
        0,
        1,
        'Déclencher un chronomètre',
      );

      controller.ensureFirstAllergy();
      controller.updateAllergen(0, 'Arachide');
      controller.addAllergyEmergencyStep(0);
      controller.updateAllergyEmergencyStep(
        0,
        0,
        'Administrer le stylo injecteur',
      );

      controller.ensureFirstDailyTreatment();
      controller.updateDailyTreatmentName(0, 'Dépakine');

      final epilepsyId =
          controller.formData.pathologies[0].pathologyId;
      final peanutAllergyId =
          controller.formData.allergies[0].allergyId;

      controller.updateDailyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );

      final profile = controller.validateAndGetProfile();

      final rebuiltDraft =
          ChildProfileDraft.fromChildProfileData(profile);

      expect(rebuiltDraft.childId, profile.childId);

      expect(
        rebuiltDraft.pathologies[0].pathologyId,
        epilepsyId,
      );

      expect(
        rebuiltDraft.pathologies[0]
            .emergencyInstructionSteps,
        [
          'Mettre en position latérale de sécurité',
          'Déclencher un chronomètre',
        ],
      );

      expect(
        rebuiltDraft.allergies[0].allergyId,
        peanutAllergyId,
      );

      expect(
        rebuiltDraft.allergies[0]
            .emergencyInstructionSteps,
        ['Administrer le stylo injecteur'],
      );

      expect(
        rebuiltDraft.dailyTreatments[0]
            .relatedPathologyIds,
        contains(epilepsyId),
      );

      expect(
        rebuiltDraft.identity.firstName,
        'Théo',
      );
    },
  );
}
