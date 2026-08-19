import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/controllers/transmission_controller.dart';

/// Corrigé (19/08/2026) : un traitement d'urgence rattaché à une étape
/// précise (ex. "étape 6") doit rester rattaché à la BONNE étape après
/// suppression d'une étape antérieure — sinon le lien pointe
/// silencieusement vers un texte différent, sur une fonctionnalité de
/// sécurité (Mode Urgence).
void main() {
  test(
    'Supprimer une étape antérieure décale le lien du traitement vers '
    'le bon nouvel index',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(0, 'Epilepsie');

      final pathologyId =
          controller.formData.pathologies[0].pathologyId;

      // 3 étapes, la 3e sera l'étape d'administration (index 2).
      controller.addPathologyEmergencyStep(0);
      controller.addPathologyEmergencyStep(0);
      controller.addPathologyEmergencyStep(0);
      controller.updatePathologyEmergencyStep(
        0,
        0,
        'Mettre en PLS',
      );
      controller.updatePathologyEmergencyStep(
        0,
        1,
        'Declencher chrono',
      );
      controller.updatePathologyEmergencyStep(
        0,
        2,
        'Administrer BUCCOLAM',
      );

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentName(0, 'BUCCOLAM');
      controller.updateEmergencyTreatmentPathology(
        0,
        pathologyId,
        true,
      );
      controller.updateEmergencyTreatmentPathologyStep(
        0,
        pathologyId,
        2,
      );

      // On supprime l'étape 1 ("Mettre en PLS") : "Administrer
      // BUCCOLAM" passe de l'index 2 à l'index 1.
      controller.removePathologyEmergencyStep(0, 0);

      final treatment = controller.formData.emergencyTreatments[0];

      expect(
        treatment.administrationStepByPathologyId[pathologyId],
        equals(1),
      );

      expect(
        controller
            .formData
            .pathologies[0]
            .emergencyInstructionSteps[
                treatment.administrationStepByPathologyId[
                    pathologyId]!],
        equals('Administrer BUCCOLAM'),
        reason:
            'Après réindexation, le lien doit pointer vers le texte '
            'qui correspond vraiment à l’administration du '
            'traitement.',
      );
    },
  );

  test(
    'Supprimer l’étape d’administration elle-même efface le lien '
    'au lieu de pointer vers une étape sans rapport',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(0, 'Epilepsie');

      final pathologyId =
          controller.formData.pathologies[0].pathologyId;

      controller.addPathologyEmergencyStep(0);
      controller.addPathologyEmergencyStep(0);
      controller.updatePathologyEmergencyStep(
        0,
        0,
        'Mettre en PLS',
      );
      controller.updatePathologyEmergencyStep(
        0,
        1,
        'Administrer BUCCOLAM',
      );

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentPathology(
        0,
        pathologyId,
        true,
      );
      controller.updateEmergencyTreatmentPathologyStep(
        0,
        pathologyId,
        1,
      );

      controller.removePathologyEmergencyStep(0, 1);

      final treatment = controller.formData.emergencyTreatments[0];

      expect(
        treatment.administrationStepByPathologyId
            .containsKey(pathologyId),
        isFalse,
      );
    },
  );

  test(
    'Supprimer entièrement une pathologie efface aussi le lien '
    'd’étape, pas seulement le lien de pathologie',
    () {
      final controller = TransmissionController();

      controller.ensureFirstPathology();
      controller.updatePathologyName(0, 'Epilepsie');
      controller.addPathologyEmergencyStep(0);
      controller.updatePathologyEmergencyStep(
        0,
        0,
        'Administrer BUCCOLAM',
      );

      controller.addPathology();
      controller.updatePathologyName(1, 'Asthme');

      final epilepsyId =
          controller.formData.pathologies[0].pathologyId;

      controller.ensureFirstEmergencyTreatment();
      controller.updateEmergencyTreatmentPathology(
        0,
        epilepsyId,
        true,
      );
      controller.updateEmergencyTreatmentPathologyStep(
        0,
        epilepsyId,
        0,
      );

      controller.removePathology(0);

      final treatment = controller.formData.emergencyTreatments[0];

      expect(
        treatment.administrationStepByPathologyId,
        isEmpty,
      );
    },
  );
}
