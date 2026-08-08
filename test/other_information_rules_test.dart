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
import 'package:safekids/recommendation_engine/models/recommendation_category.dart';
import 'package:safekids/recommendation_engine/rules/other_information_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool hasOtherInformation = false,
  String? details,
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
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(
        hasOtherInformation: hasOtherInformation,
        details: details,
      ),
    ),
  );
}

void main() {
  const rules = OtherInformationRules();

  test(
    'Informations complémentaires - texte renseigné génère une recommandation',
    () {
      final child = _createTestChild(
        childId: 'test-other-information',
        hasOtherInformation: true,
        details: 'Information importante à transmettre.',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.id,
        'other_information',
      );

      expect(
        recommendations.first.category,
        RecommendationCategory.additionalInformation,
      );

      expect(
        recommendations.first.text,
        'Information importante à transmettre.',
      );
    },
  );

  test(
    'Informations complémentaires - espaces autour du texte sont supprimés',
    () {
      final child = _createTestChild(
        childId: 'test-other-information-trim',
        hasOtherInformation: true,
        details: '   Détail utile   ',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.first.text,
        'Détail utile',
      );
    },
  );

  test(
    'Informations complémentaires - indicateur faux ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-other-information-false',
        hasOtherInformation: false,
        details: 'Ce texte ne doit pas sortir.',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );

  test(
    'Informations complémentaires - texte vide ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-other-information-empty',
        hasOtherInformation: true,
        details: '   ',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}