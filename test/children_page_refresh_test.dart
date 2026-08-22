import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsrelay/children/children_page.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/repositories/child_repository.dart';

/// Vérifie que la liste "Mes enfants" se met à jour toute seule quand
/// les données changent (ex. suppression), sans qu'il soit nécessaire
/// de relancer l'app ou de renaviguer pour "forcer" un rafraîchissement
/// — bug signalé : après une suppression réussie, la page revenait
/// bien à la liste, mais continuait d'afficher l'enfant supprimé.
void main() {
  ChildProfileData buildChild(String id, String firstName) {
    return ChildProfileData(
      childId: id,
      userId: 'test-user',
      identity: IdentityData(firstName: firstName),
      pathologies: const <PathologyData>[],
      medicalEvents: const [],
      medicalObservations: const [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: const [],
      discontinuedTreatments: const [],
      emergencyTreatments: const [],
      allergies: const <AllergyData>[],
      medicalDevices: const [],
      contacts: const [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ChildRepository.instance.clearForTesting();
  });

  testWidgets(
    'La liste se met à jour sans nouvelle navigation quand un enfant est retiré',
    (tester) async {
      ChildRepository.instance.seedForTesting(
        buildChild('child-1', 'Camille'),
      );
      ChildRepository.instance.seedForTesting(
        buildChild('child-2', 'Théo'),
      );

      await tester.pumpWidget(
        const MaterialApp(home: ChildrenPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('Théo'), findsOneWidget);

      // Simule ce que fait deleteChild() une fois la suppression
      // réussie côté Supabase : mise à jour de la liste en mémoire,
      // puis notification des écrans à l'écoute (ce que fait
      // _saveToLocalCache() en interne).
      ChildRepository.instance.clearForTesting();
      ChildRepository.instance.seedForTesting(
        buildChild('child-1', 'Camille'),
      );
      await ChildRepository.instance
          .saveToLocalCacheForTesting();
      await tester.pump();

      expect(
        find.text('Théo'),
        findsNothing,
        reason:
            'La page ne doit pas continuer à afficher un enfant '
            'supprimé entre-temps, sans avoir besoin de relancer '
            'l\'app ou de renaviguer pour "forcer" un rafraîchissement.',
      );
      expect(find.text('Camille'), findsOneWidget);
    },
  );
}
