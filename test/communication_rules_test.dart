import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/other_information_data.dart';
import 'package:kidsrelay/models/overnight_stay_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/safety_data.dart';
import 'package:kidsrelay/models/toilets_data.dart';
import 'package:kidsrelay/models/transitions_data.dart';
import 'package:kidsrelay/models/transport_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/models/walking_effort_data.dart';
import 'package:kidsrelay/recommendation_engine/rules/communication_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool useSimpleInstructions = false,
  bool mayAppearToUnderstand = false,
  bool verifyUnderstandingIndividually = false,
  bool usesCommunicationSupport = false,
  String? communicationSupportDetails,
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
      communication: CommunicationData(
        requiresAdaptations: true,
        useSimpleInstructions: useSimpleInstructions,
        mayAppearToUnderstand: mayAppearToUnderstand,
        verifyUnderstandingIndividually:
            verifyUnderstandingIndividually,
        usesCommunicationSupport: usesCommunicationSupport,
        communicationSupportDetails:
            communicationSupportDetails,
      ),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    ),
  );
}

void main() {
  const rules = CommunicationRules();

  test(
    'Communication - consignes simples',
    () {
      final child = _createTestChild(
        childId: 'test-simple-instructions',
        useSimpleInstructions: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('communication_simple_instructions'),
      );
    },
  );

  test(
    'Communication - sembler avoir compris génère vérifier sa compréhension',
    () {
      final child = _createTestChild(
        childId: 'test-may-understand',
        mayAppearToUnderstand: true,
      );

      final recommendations = rules.evaluate(child);

      final recommendation = recommendations.firstWhere(
        (recommendation) =>
            recommendation.id ==
            'communication_verify_understanding',
      );

      expect(
        recommendation.text,
        'Vérifier sa compréhension.',
      );
    },
  );

  test(
    'Communication - vérifier individuellement génère vérifier sa compréhension',
    () {
      final child = _createTestChild(
        childId: 'test-verify-understanding',
        verifyUnderstandingIndividually: true,
      );

      final recommendations = rules.evaluate(child);

      final recommendation = recommendations.firstWhere(
        (recommendation) =>
            recommendation.id ==
            'communication_verify_understanding',
      );

      expect(
        recommendation.text,
        'Vérifier sa compréhension.',
      );
    },
  );

  test(
    'Communication - les deux besoins génèrent une seule vérification',
    () {
      final child = _createTestChild(
        childId: 'test-both-understanding',
        mayAppearToUnderstand: true,
        verifyUnderstandingIndividually: true,
      );

      final recommendations = rules.evaluate(child);

      final understandingRecommendations =
          recommendations.where(
        (recommendation) =>
            recommendation.id ==
            'communication_verify_understanding',
      );

      expect(
        understandingRecommendations.length,
        1,
      );

      expect(
        understandingRecommendations.first.text,
        'Vérifier sa compréhension.',
      );
    },
  );

  test(
    'Communication - support spécifique repris tel quel',
    () {
      final child = _createTestChild(
        childId: 'test-support',
        usesCommunicationSupport: true,
        communicationSupportDetails:
            'Tablette avec pictogrammes',
      );

      final recommendations = rules.evaluate(child);

      final support = recommendations.firstWhere(
        (recommendation) =>
            recommendation.id ==
            'communication_support',
      );

      expect(
        support.text,
        'Tablette avec pictogrammes',
      );
    },
  );

  test(
    'Communication - support vide ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-empty-support',
        usesCommunicationSupport: true,
        communicationSupportDetails: '   ',
      );

      final recommendations = rules.evaluate(child);

      final supportRecommendations =
          recommendations.where(
        (recommendation) =>
            recommendation.id ==
            'communication_support',
      );

      expect(
        supportRecommendations,
        isEmpty,
      );
    },
  );

  test(
    'Communication - aucune donnée ne génère aucune recommandation',
    () {
      final child = _createTestChild(
        childId: 'test-no-communication',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}