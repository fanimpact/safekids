import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/emergency_info/emergency_info_sheet_page.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/medical_device_data.dart';
import 'package:safekids/models/medical_professional_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';

/// Corrections de l'audit passe 2 : la fiche secours n'affichait ni
/// le détail (spécialité/lieu/téléphone) du médecin référent d'une
/// pathologie, ni la distinction entre dispositifs portés en
/// permanence et dispositifs à emporter (déjà correcte sur "Ce qu'il
/// faut savoir sur...", absente ici).
void main() {
  testWidgets(
    'Le médecin référent complet et la distinction des dispositifs '
    'permanents s’affichent',
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
          medicalEvents: const [],
          medicalObservations: const [],
          triggerFactors: TriggerFactorData(),
          allergies: const [],
          dailyTreatments: const [],
          discontinuedTreatments: const [],
          emergencyTreatments: const [],
          medicalDevices: [
            MedicalDeviceData(
              deviceName: 'Pompe à insuline',
              isWornOrImplantedPermanently: true,
            ),
            MedicalDeviceData(
              deviceName: 'Machine à apnée',
              isWornOrImplantedPermanently: false,
            ),
          ],
          contacts: const [],
          primaryCareDoctor: PrimaryCareDoctorData(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: EmergencyInfoSheetPage(child: child)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining(
          'suivi par Dr Cabasson — Neurologue — CHU Pau — '
          'Tél. : 0559000000',
        ),
        300,
      );
      expect(
        find.textContaining(
          'suivi par Dr Cabasson — Neurologue — CHU Pau — '
          'Tél. : 0559000000',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text(
          'Dispositifs portés ou implantés en permanence',
        ),
        300,
      );
      expect(
        find.text(
          'Dispositifs portés ou implantés en permanence',
        ),
        findsOneWidget,
        reason:
            'Cette distinction existait déjà sur "Ce qu\'il faut '
            'savoir sur...", elle doit exister ici aussi.',
      );
      expect(find.text('Pompe à insuline'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Machine à apnée'),
        300,
      );
      expect(find.text('Machine à apnée'), findsOneWidget);
    },
  );
}
