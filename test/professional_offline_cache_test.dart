import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/professional/professional_child_repository.dart';
import 'package:kidsrelay/repositories/child_profile_codec.dart';

/// Corrections de l'audit passe 1 : la limite de 7 jours sans
/// synchronisation réussie du cache hors-ligne professionnel
/// (`ProfessionalChildRepository`) était correcte au code, mais sans
/// aucun test — contrairement à l'équivalent parent
/// (`test/offline_cache_test.dart`). Sans cette limite, une personne
/// dont l'accès a été révoqué garderait indéfiniment des données de
/// santé d'enfants sur son téléphone.
void main() {
  const cacheKey = 'kidsrelay_pro_cached_children';
  const cacheSyncedAtKey = 'kidsrelay_pro_cache_synced_at';

  ChildProfileData buildChild() {
    return ChildProfileData(
      childId: 'pro-offline-test-child',
      identity: IdentityData(firstName: 'Théo'),
      pathologies: [PathologyData(name: 'Épilepsie')],
      medicalEvents: const [],
      medicalObservations: const [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: const [],
      discontinuedTreatments: const [],
      emergencyTreatments: const [],
      allergies: [AllergyData(
            categories: {AllergyCategory.food},
            details: {AllergyCategory.food: 'Arachides'},
          )],
      medicalDevices: const [],
      contacts: const [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    );
  }

  Map<String, dynamic> buildCacheJson(ChildProfileData child) {
    return {
      'enfant': ChildProfileCodec.enfantRow(child, ''),
      'sante': ChildProfileCodec.santeRow(
        child.childId ?? '',
        child,
      ),
      'activites': null,
      'activityProfileCompleted': false,
    };
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfessionalChildRepository.instance.clearLocalData();
  });

  test(
    'Une copie locale de moins de 7 jours se recharge normalement',
    () async {
      final child = buildChild();
      final syncedAt =
          DateTime.now().subtract(const Duration(days: 3));

      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode([buildCacheJson(child)]),
        cacheSyncedAtKey: syncedAt.toIso8601String(),
      });

      final loaded = await ProfessionalChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(loaded, isTrue);
      expect(
        ProfessionalChildRepository.instance.isOffline,
        isTrue,
      );
      expect(
        ProfessionalChildRepository.instance.children,
        hasLength(1),
      );
      expect(
        ProfessionalChildRepository.instance
            .findByChildId('pro-offline-test-child')
            ?.essentialInformation
            .identity
            .firstName,
        equals('Théo'),
      );
    },
  );

  test(
    'Une copie locale de plus de 7 jours sans synchronisation est '
    'refusée, pas affichée comme si elle était à jour',
    () async {
      final child = buildChild();
      final staleSyncedAt =
          DateTime.now().subtract(const Duration(days: 8));

      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode([buildCacheJson(child)]),
        cacheSyncedAtKey: staleSyncedAt.toIso8601String(),
      });

      final loaded = await ProfessionalChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(
        loaded,
        isFalse,
        reason:
            'Passé 7 jours sans synchronisation réussie, l’app ne '
            'doit plus faire confiance au cache — une personne '
            'révoquée entre-temps ne doit pas continuer à voir des '
            'données de santé indéfiniment.',
      );
      expect(
        ProfessionalChildRepository.instance.children,
        isEmpty,
      );
      expect(
        ProfessionalChildRepository.instance.isOffline,
        isFalse,
      );
    },
  );

  test(
    'Une synchronisation datant d’exactement 7 jours (ou tout juste '
    'plus, le temps que le test s’exécute) est déjà refusée — la '
    'limite ne tolère pas "7 jours ou moins"',
    () async {
      final child = buildChild();
      final exactlySevenDaysAgo = DateTime.now().subtract(
        const Duration(days: 7),
      );

      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode([buildCacheJson(child)]),
        cacheSyncedAtKey:
            exactlySevenDaysAgo.toIso8601String(),
      });

      final loaded = await ProfessionalChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(loaded, isFalse);
    },
  );

  test(
    'Sans aucune synchronisation antérieure, la copie locale est '
    'refusée',
    () async {
      final loaded = await ProfessionalChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      expect(loaded, isFalse);
      expect(
        ProfessionalChildRepository.instance.children,
        isEmpty,
      );
    },
  );
}
