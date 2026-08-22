import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/emergency_info/emergency_info_sheet_page.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';

/// Corrigé (19/08/2026), le point le plus grave de la passe 2 de
/// l'audit : les consignes d'urgence numérotées rédigées par le
/// parent pour une pathologie/allergie précise n'apparaissaient
/// jusqu'ici que dans le Mode Urgence interactif, jamais sur la fiche
/// secours imprimable/partageable — exactement ce que consulte
/// quelqu'un sans l'app sous la main.
void main() {
  testWidgets(
    'Les consignes d’urgence d’une pathologie et d’une allergie '
    'apparaissent, numérotées, sur la fiche secours',
    (tester) async {
      final child = CompleteChildProfileData(
        essentialInformation: ChildProfileData(
          childId: 'test-child',
          userId: 'test-family',
          identity: IdentityData(
            firstName: 'Théo',
            lastName: 'Test',
          ),
          pathologies: [
            PathologyData(
              pathologyId: 'p1',
              name: 'Épilepsie',
              emergencyInstructionSteps: const [
                'Mettre en position latérale de sécurité',
                'Chronométrer la crise',
              ],
            ),
          ],
          medicalEvents: [],
          medicalObservations: [],
          triggerFactors: TriggerFactorData(),
          dailyTreatments: [],
          discontinuedTreatments: [],
          emergencyTreatments: [],
          allergies: [
            AllergyData(
              allergyId: 'a1',
              categories: {AllergyCategory.food},
              details: {
                AllergyCategory.food: 'Arachides',
              },
              emergencyInstructionSteps: const [
                'Administrer l’auto-injecteur',
              ],
            ),
          ],
          medicalDevices: [],
          contacts: [],
          primaryCareDoctor: PrimaryCareDoctorData(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyInfoSheetPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Consignes d’urgence'),
        findsOneWidget,
      );
      expect(find.text('Épilepsie'), findsWidgets);
      expect(
        find.text(
          '1. Mettre en position latérale de sécurité',
        ),
        findsOneWidget,
      );
      expect(
        find.text('2. Chronométrer la crise'),
        findsOneWidget,
      );
      expect(find.text('Arachides'), findsWidgets);
      expect(
        find.text(
          '1. Administrer l’auto-injecteur',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Aucune consigne renseignée : pas de section "Consignes d’urgence"',
    (tester) async {
      final child = CompleteChildProfileData(
        essentialInformation: ChildProfileData(
          childId: 'test-child-none',
          userId: 'test-family',
          identity: IdentityData(
            firstName: 'Noé',
            lastName: 'Test',
          ),
          pathologies: [
            PathologyData(
              pathologyId: 'p2',
              name: 'Asthme',
            ),
          ],
          medicalEvents: [],
          medicalObservations: [],
          triggerFactors: TriggerFactorData(),
          dailyTreatments: [],
          discontinuedTreatments: [],
          emergencyTreatments: [],
          allergies: [],
          medicalDevices: [],
          contacts: [],
          primaryCareDoctor: PrimaryCareDoctorData(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyInfoSheetPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Consignes d’urgence'),
        findsNothing,
      );
    },
  );
}
