import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/activity_profile_data.dart';
import 'package:safekids/models/aquatic_activity_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/clothing_data.dart';
import 'package:safekids/models/communication_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/other_information_data.dart';
import 'package:safekids/models/overnight_stay_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/safety_data.dart';
import 'package:safekids/models/toilets_data.dart';
import 'package:safekids/models/transitions_data.dart';
import 'package:safekids/models/transport_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/models/walking_effort_data.dart';
import 'package:safekids/recommendation_engine/rules/toilets_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  required bool requiresAssistance,
}) {
  return CompleteChildProfileData(
    essentialInformation: ChildProfileData(
      childId: childId,
      userId: 'test-family',
      identity: IdentityData(
        firstName: 'Test',
        lastName: 'Enfant',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
      emergencyTreatments: [],
      allergies: [],
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor: PrimaryCareDoctorData(
        name: null,
        workplace: null,
        phoneNumber: null,
      ),
    ),
    activityProfile: ActivityProfileData(
      aquaticActivity: AquaticActivityData(),
      transport: TransportData(),
      walkingEffort: WalkingEffortData(),
      overnightStay: OvernightStayData(),
      clothing: ClothingData(),
      toilets: ToiletsData(
        requiresAssistance: requiresAssistance,
      ),
      communication: CommunicationData(),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    ),
  );
}

void main() {
  const rules = ToiletsRules();

  test(
    'Toilettes - assistance nécessaire génère une adaptation',
    () {
      final child = _createTestChild(
        childId: 'test-toilets-assistance',
        requiresAssistance: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('toilets_assistance'),
      );
    },
  );

  test(
    'Toilettes - aucune assistance nécessaire ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-toilets-independent',
        requiresAssistance: false,
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}