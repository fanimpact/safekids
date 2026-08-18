import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/medical_device_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/recommendation_engine/models/recommendation_category.dart';
import 'package:safekids/recommendation_engine/rules/medical_device_reminder_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  List<MedicalDeviceData> medicalDevices = const [],
}) {
  return CompleteChildProfileData(
    essentialInformation: ChildProfileData(
      childId: childId,
      userId: 'test-family',
      identity: IdentityData(
        firstName: 'Test',
        lastName: 'Enfant',
      ),
      pathologies: [],
      medicalEvents: [],
      medicalObservations: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
      discontinuedTreatments: [],
      emergencyTreatments: [],
      allergies: [],
      medicalDevices: medicalDevices,
      contacts: [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    ),
  );
}

/// Corrigé (19/08/2026) : la seule règle qui lisait les dispositifs
/// médicaux jusqu'ici était celle de la nuitée, uniquement pour un
/// dispositif explicitement lié à un usage nocturne — un dispositif
/// utilisé seulement le jour ne générait jamais aucun rappel.
void main() {
  const rules = MedicalDeviceReminderRules();

  test(
    'Un dispositif à emporter (non permanent) génère un rappel',
    () {
      final child = _createTestChild(
        childId: 'test-device-bring',
        medicalDevices: [
          MedicalDeviceData(
            deviceId: 'd1',
            deviceName: 'Chambre d’inhalation',
            mainUse: 'Crise d’asthme',
            isWornOrImplantedPermanently: false,
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(recommendations.length, 1);
      expect(
        recommendations.first.text,
        'Chambre d’inhalation — Crise d’asthme',
      );
      expect(
        recommendations.first.category,
        RecommendationCategory.rememberToTake,
      );
    },
  );

  test(
    'Un dispositif non renseigné (ni vrai ni faux) génère quand même '
    'un rappel, par prudence',
    () {
      final child = _createTestChild(
        childId: 'test-device-unspecified',
        medicalDevices: [
          MedicalDeviceData(
            deviceId: 'd2',
            deviceName: 'Lecteur de glycémie',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(recommendations.length, 1);
    },
  );

  test(
    'Un dispositif porté ou implanté en permanence ne génère aucun '
    'rappel — il est déjà sur l’enfant',
    () {
      final child = _createTestChild(
        childId: 'test-device-permanent',
        medicalDevices: [
          MedicalDeviceData(
            deviceId: 'd3',
            deviceName: 'Pompe à insuline',
            isWornOrImplantedPermanently: true,
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(recommendations, isEmpty);
    },
  );

  test(
    'Un dispositif sans nom renseigné ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-device-no-name',
        medicalDevices: [
          MedicalDeviceData(deviceId: 'd4'),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(recommendations, isEmpty);
    },
  );
}
