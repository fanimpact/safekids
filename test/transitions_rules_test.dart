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
import 'package:safekids/recommendation_engine/rules/transitions_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool transitionsMayCauseStress = false,
  bool changesMustBeAnnounced = false,
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
      toilets: ToiletsData(),
      communication: CommunicationData(),
      transitions: TransitionsData(
        requiresAdaptations: true,
        transitionsMayCauseStress:
            transitionsMayCauseStress,
        changesMustBeAnnounced:
            changesMustBeAnnounced,
      ),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    ),
  );
}

void main() {
  const rules = TransitionsRules();

  test(
    'Transitions - stress génère une vigilance',
    () {
      final child = _createTestChild(
        childId: 'test-transition-stress',
        transitionsMayCauseStress: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('transitions_may_cause_stress'),
      );
    },
  );

  test(
    'Transitions - changements à annoncer génèrent une adaptation',
    () {
      final child = _createTestChild(
        childId: 'test-transition-announce',
        changesMustBeAnnounced: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('transitions_announce_changes'),
      );
    },
  );

  test(
    'Transitions - les deux besoins peuvent apparaître ensemble',
    () {
      final child = _createTestChild(
        childId: 'test-transition-both',
        transitionsMayCauseStress: true,
        changesMustBeAnnounced: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('transitions_may_cause_stress'),
      );

      expect(
        ids,
        contains('transitions_announce_changes'),
      );
    },
  );

  test(
    'Transitions - aucune donnée ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-transition-none',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}