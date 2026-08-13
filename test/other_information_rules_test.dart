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
  String? secondDetails,
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
      medicalObservations: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
      discontinuedTreatments: [],
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
        secondDetails: secondDetails,
      ),
    ),
  );
}

void main() {
  const rules = OtherInformationRules();

  test(
    'Informations complémentaires - premier texte renseigné génère une recommandation',
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
        'other_information_1',
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
    'Informations complémentaires - deux textes génèrent deux recommandations séparées',
    () {
      final child = _createTestChild(
        childId: 'test-two-other-information',
        hasOtherInformation: true,
        details: 'Première information.',
        secondDetails: 'Deuxième information.',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        2,
      );

      expect(
        recommendations[0].id,
        'other_information_1',
      );

      expect(
        recommendations[0].text,
        'Première information.',
      );

      expect(
        recommendations[1].id,
        'other_information_2',
      );

      expect(
        recommendations[1].text,
        'Deuxième information.',
      );
    },
  );

  test(
    'Informations complémentaires - deuxième texte seul génère une recommandation',
    () {
      final child = _createTestChild(
        childId: 'test-second-other-information',
        hasOtherInformation: true,
        details: null,
        secondDetails: 'Deuxième information uniquement.',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.id,
        'other_information_2',
      );

      expect(
        recommendations.first.text,
        'Deuxième information uniquement.',
      );
    },
  );

  test(
    'Informations complémentaires - espaces autour des textes sont supprimés',
    () {
      final child = _createTestChild(
        childId: 'test-other-information-trim',
        hasOtherInformation: true,
        details: '   Détail utile   ',
        secondDetails: '   Deuxième détail   ',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations[0].text,
        'Détail utile',
      );

      expect(
        recommendations[1].text,
        'Deuxième détail',
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
        secondDetails:
            'Ce deuxième texte ne doit pas sortir non plus.',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );

  test(
    'Informations complémentaires - textes vides ne génèrent rien',
    () {
      final child = _createTestChild(
        childId: 'test-other-information-empty',
        hasOtherInformation: true,
        details: '   ',
        secondDetails: '   ',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}