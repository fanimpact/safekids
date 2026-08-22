import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/care_info/care_info_sheet_page.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/medical_event_data.dart';
import 'package:kidsrelay/models/medical_professional_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';

/// Corrections de l'audit passe 2 : "Ce qu'il faut savoir sur..."
/// n'affichait ni le médecin traitant, ni les antécédents médicaux,
/// ni la spécialité/le lieu d'exercice/le téléphone du médecin
/// référent d'une pathologie (seul son nom apparaissait).
void main() {
  testWidgets(
    'Médecin traitant, antécédents et médecin référent complet '
    's’affichent tous',
    (tester) async {
      final child = CompleteChildProfileData(
        essentialInformation: ChildProfileData(
          childId: 'test-child',
          userId: 'test-user',
          identity: IdentityData(firstName: 'Théo'),
          pathologies: [
            PathologyData(
              name: 'Epilepsie',
              hasReferringProfessional: true,
              referringProfessional: MedicalProfessionalData(
                name: 'Dr Cabasson',
                specialty: 'Neurologue',
                workplace: 'CHU Pau',
                phoneNumber: '0559000000',
              ),
            ),
          ],
          medicalEvents: [
            MedicalEventData(
              description: 'Crise convulsive à l’école',
              hospitalized: true,
              hospitalName: 'CHU Pau',
            ),
          ],
          medicalObservations: const [],
          triggerFactors: TriggerFactorData(),
          allergies: const [],
          dailyTreatments: const [],
          discontinuedTreatments: const [],
          emergencyTreatments: const [],
          medicalDevices: const [],
          contacts: const [],
          primaryCareDoctor: PrimaryCareDoctorData(
            name: 'Dr Martin',
            workplace: 'Cabinet du centre',
            phoneNumber: '0559111111',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: CareInfoSheetPage(child: child)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Médecin traitant'),
        300,
      );

      expect(find.text('Médecin traitant'), findsOneWidget);
      expect(find.text('Dr Martin'), findsOneWidget);
      expect(find.text('Cabinet du centre'), findsOneWidget);
      expect(find.text('Tél. : 0559111111'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Antécédent : Crise convulsive'),
        300,
      );
      expect(
        find.textContaining('Antécédent : Crise convulsive'),
        findsOneWidget,
        reason:
            'Les antécédents médicaux (événements médicaux passés) '
            'doivent apparaître, pas seulement les pathologies.',
      );

      expect(
        find.textContaining(
          'suivi par Dr Cabasson — Neurologue — CHU Pau — '
          'Tél. : 0559000000',
        ),
        findsOneWidget,
        reason:
            'Spécialité, lieu d’exercice et téléphone du médecin '
            'référent doivent apparaître, pas seulement son nom.',
      );
    },
  );

  testWidgets(
    'Sans médecin traitant renseigné, aucune fausse ligne vide',
    (tester) async {
      final child = CompleteChildProfileData(
        essentialInformation: ChildProfileData(
          childId: 'test-child',
          userId: 'test-user',
          identity: IdentityData(firstName: 'Noé'),
          pathologies: const [],
          medicalEvents: const [],
          medicalObservations: const [],
          triggerFactors: TriggerFactorData(),
          allergies: const [],
          dailyTreatments: const [],
          discontinuedTreatments: const [],
          emergencyTreatments: const [],
          medicalDevices: const [],
          contacts: const [],
          primaryCareDoctor: PrimaryCareDoctorData(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: CareInfoSheetPage(child: child)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Médecin traitant'), findsNothing);
    },
  );
}
