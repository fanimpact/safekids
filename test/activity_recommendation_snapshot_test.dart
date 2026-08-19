import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/activity_profile_data.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
import 'package:safekids/models/activity_session/complete_activity_session_data.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/aquatic_activity_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/clothing_data.dart';
import 'package:safekids/models/communication_data.dart';
import 'package:safekids/models/emergency_treatment_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/other_information_data.dart';
import 'package:safekids/models/overnight_stay_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/safety_data.dart';
import 'package:safekids/models/toilets_data.dart';
import 'package:safekids/models/transitions_data.dart';
import 'package:safekids/models/transport_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/models/walking_effort_data.dart';
import 'package:safekids/recommendation_engine/recommendation_engine.dart';
import 'package:safekids/repositories/child_repository.dart';
import 'package:safekids/sharing/activity_recommendation_snapshot.dart';

/// Corrigé (19/08/2026, corrections de l'inventaire point 5) : le
/// partage "recommandations d'activité" était bloqué depuis toujours
/// (raison : aucune activité n'était sauvegardée nulle part). La
/// persistance existe désormais (`ActivitySessionRepository`) — ce
/// test vérifie la "photo" figée construite au moment du partage,
/// séparément du reste du moteur de recommandations déjà testé
/// ailleurs.
void main() {
  ChildProfileData buildChild(String childId) {
    return ChildProfileData(
      childId: childId,
      userId: 'test-user',
      identity: IdentityData(firstName: 'Camille'),
      pathologies: const <PathologyData>[],
      medicalEvents: const [],
      medicalObservations: const [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: const [],
      discontinuedTreatments: const [],
      emergencyTreatments: [
        EmergencyTreatmentData(
          medicationName: 'Adrénaline',
          dosage: '1 dose',
        ),
      ],
      allergies: [
        AllergyData(
          allergen: 'Arachide',
          observedReaction: 'Œdème',
        ),
      ],
      medicalDevices: const [],
      contacts: const [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    );
  }

  ActivityProfileData buildActivityProfile() {
    return ActivityProfileData(
      aquaticActivity: AquaticActivityData(),
      transport: TransportData(),
      walkingEffort: WalkingEffortData(),
      overnightStay: OvernightStayData(),
      clothing: ClothingData(),
      toilets: ToiletsData(),
      communication: CommunicationData(),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    );
  }

  setUp(() {
    ChildRepository.instance.clearForTesting();
  });

  test(
    'La photo figée reprend les recommandations propres à l’enfant '
    'partagé, et les informations de l’activité',
    () {
      const sharedChildId = 'snapshot-child-1';
      const otherChildId = 'snapshot-child-2';

      ChildRepository.instance.seedForTesting(
        buildChild(sharedChildId),
      );
      ChildRepository.instance.seedActivityProfileForTesting(
        childId: sharedChildId,
        activityProfile: buildActivityProfile(),
      );
      ChildRepository.instance.seedForTesting(
        buildChild(otherChildId),
      );
      ChildRepository.instance.seedActivityProfileForTesting(
        childId: otherChildId,
        activityProfile: buildActivityProfile(),
      );

      final activitySession = CompleteActivitySessionData(
        id: 'activite-1',
        activity: ActivitySessionData(
          activityName: 'Sortie piscine',
          date: DateTime.utc(2026, 9, 1, 10, 30),
          location: 'Centre aquatique',
        ),
        childIds: const [sharedChildId, otherChildId],
      );

      final result = RecommendationEngine()
          .generateRecommendations(activitySession);

      final sharedChild = ChildRepository.instance.findByChildId(
        sharedChildId,
      )!;

      final snapshot = ActivityRecommendationSnapshot.build(
        activitySession: activitySession,
        recommendationResult: result,
        child: sharedChild,
      );

      expect(snapshot['activite_nom'], equals('Sortie piscine'));
      expect(snapshot['activite_lieu'], equals('Centre aquatique'));

      final sections =
          (snapshot['sections'] as List).cast<Map<String, dynamic>>();

      final pointsImportants = sections.firstWhere(
        (section) => section['titre'] == 'Points importants',
      );

      expect(
        (pointsImportants['lignes'] as List).any(
          (ligne) => (ligne as String).contains('Arachide'),
        ),
        isTrue,
        reason:
            'L’allergie de l’enfant partagé doit figurer dans les '
            'points importants de la photo figée.',
      );

      final medicaments = sections.firstWhere(
        (section) => section['titre'] == 'Médicaments d’urgence',
      );

      expect(
        (medicaments['lignes'] as List).any(
          (ligne) => (ligne as String).contains('Adrénaline'),
        ),
        isTrue,
      );

      final toutLeTexte = sections
          .expand((section) => section['lignes'] as List)
          .cast<String>()
          .join(' ');

      expect(
        toutLeTexte.contains(otherChildId),
        isFalse,
        reason:
            'Seules les recommandations de l’enfant dont la fiche est '
            'partagée doivent apparaître, jamais celles d’un autre '
            'enfant de la même activité.',
      );
    },
  );
}
