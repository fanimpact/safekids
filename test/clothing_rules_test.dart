import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/activity_profile_data.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
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
import 'package:safekids/recommendation_engine/rules/clothing_rules.dart';

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
      clothing: ClothingData(
        requiresAssistance: requiresAssistance,
      ),
      toilets: ToiletsData(),
      communication: CommunicationData(),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    ),
  );
}

void main() {
  const rules = ClothingRules();

  test(
    'Habillage - changement de tenue avec besoin d’assistance',
    () {
      final child = _createTestChild(
        childId: 'test-clothing-assistance',
        requiresAssistance: true,
      );

      final activity = ActivitySessionData(
        hasClothingChange: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('clothing_change_assistance'),
      );
    },
  );

  test(
    'Habillage - pas de recommandation sans changement de tenue',
    () {
      final child = _createTestChild(
        childId: 'test-clothing-no-change',
        requiresAssistance: true,
      );

      final activity = ActivitySessionData(
        hasClothingChange: false,
      );

      final recommendations =
          rules.evaluate(child, activity);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );

  test(
    'Habillage - pas de recommandation si aucune assistance nécessaire',
    () {
      final child = _createTestChild(
        childId: 'test-clothing-independent',
        requiresAssistance: false,
      );

      final activity = ActivitySessionData(
        hasClothingChange: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}