import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/daily_treatment_data.dart';
import 'package:kidsrelay/models/emergency_treatment_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/other_information_data.dart';
import 'package:kidsrelay/models/overnight_stay_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/safety_data.dart';
import 'package:kidsrelay/models/toilets_data.dart';
import 'package:kidsrelay/models/transitions_data.dart';
import 'package:kidsrelay/models/transport_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/models/walking_effort_data.dart';
import 'package:kidsrelay/repositories/child_repository.dart';

/// Vérifie le mode hors-ligne : une fois une copie locale écrite, on
/// doit pouvoir reconstruire exactement les mêmes données (y compris
/// les détails imbriqués : pathologie, allergie, traitements, profil
/// activités) sans passer par Supabase — c'est ce que le démarrage
/// hors-ligne utilise pour que le Mode Urgence et la fiche secours
/// restent utilisables sans réseau.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ChildRepository.instance.clearForTesting();
  });

  test(
    'Une copie locale sauvegardée restaure fidèlement le profil complet',
    () async {
      final child = ChildProfileData(
        childId: 'offline-test-child',
        identity: IdentityData(
          firstName: 'Camille',
          lastName: 'Dupont',
          hasDiagnosedPathologies: true,
        ),
        hasPathologies: true,
        hasAllergies: true,
        pathologies: [
          PathologyData(name: 'Épilepsie'),
        ],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(
          hasTriggerFactors: true,
          waterContact: true,
          waterVigilance: WaterVigilance.cannotSwim,
        ),
        dailyTreatments: [
          DailyTreatmentData(
            medicationName: 'Depakine',
            dosage: '200mg',
          ),
        ],
        discontinuedTreatments: const [],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Buccolam',
            dosage: '5mg',
          ),
        ],
        allergies: [
          AllergyData(allergen: 'Arachides'),
        ],
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(
          name: 'Dr Martin',
        ),
      );

      ChildRepository.instance.seedForTesting(child);

      ChildRepository.instance.seedActivityProfileForTesting(
        childId: 'offline-test-child',
        activityProfile: ActivityProfileData(
          aquaticActivity: AquaticActivityData(),
          transport: TransportData(),
          walkingEffort: WalkingEffortData(),
          overnightStay: OvernightStayData(
            usesNightDevice: true,
          ),
          clothing: ClothingData(
            requiresAssistance: true,
          ),
          toilets: ToiletsData(),
          communication: CommunicationData(),
          transitions: TransitionsData(),
          safety: SafetyData(),
          otherInformation: OtherInformationData(),
        ),
      );

      // Simule une synchronisation Supabase réussie : écrit la copie
      // locale.
      await ChildRepository.instance
          .saveToLocalCacheForTesting();

      expect(ChildRepository.instance.isOffline, isFalse);
      expect(
        ChildRepository.instance.lastSyncAt,
        isNotNull,
      );

      // Simule un redémarrage de l'app sans réseau : plus rien en
      // mémoire, tout doit revenir de la copie locale.
      ChildRepository.instance.clearForTesting();
      expect(ChildRepository.instance.children, isEmpty);

      final loaded = await ChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(loaded, isTrue);
      expect(ChildRepository.instance.isOffline, isTrue);
      expect(
        ChildRepository.instance.lastSyncAt,
        isNotNull,
      );

      final restored = ChildRepository.instance
          .findByChildId('offline-test-child');

      expect(restored, isNotNull);
      expect(
        restored!.essentialInformation.identity.firstName,
        'Camille',
      );
      expect(
        restored.essentialInformation.pathologies
            .single
            .name,
        'Épilepsie',
      );
      expect(
        restored.essentialInformation.allergies
            .single
            .allergen,
        'Arachides',
      );
      expect(
        restored.essentialInformation.emergencyTreatments
            .single
            .medicationName,
        'Buccolam',
      );
      expect(
        restored.essentialInformation.dailyTreatments
            .single
            .medicationName,
        'Depakine',
      );
      expect(
        restored.essentialInformation.triggerFactors
            .waterVigilance,
        WaterVigilance.cannotSwim,
      );
      expect(
        restored.activityProfile?.clothing
            .requiresAssistance,
        isTrue,
      );
      expect(
        restored.activityProfile?.overnightStay
            .usesNightDevice,
        isTrue,
      );
      expect(restored.activityProfileCompleted, isTrue);
    },
  );

  test(
    'Sans copie locale enregistrée, loadFromLocalCacheIfAvailable renvoie false',
    () async {
      final loaded = await ChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(loaded, isFalse);
      expect(ChildRepository.instance.children, isEmpty);
    },
  );
}
