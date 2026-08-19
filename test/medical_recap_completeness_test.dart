import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/daily_treatment_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/questionnaire_recap/medical_questionnaire_recap_page.dart';

/// Corrigé (19/08/2026), inventaire du 19/08/2026 : le récapitulatif
/// santé prétendait couvrir "chaque question posée" mais omettait les
/// consignes d'urgence par pathologie/allergie et les liaisons
/// traitement ↔ pathologie/allergie, alors même que ces deux éléments
/// sont bien saisis dans le questionnaire.
void main() {
  testWidgets(
    'Le récapitulatif santé affiche les consignes d’urgence et les '
    'liaisons traitement ↔ pathologie',
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
              ],
            ),
          ],
          medicalEvents: [],
          medicalObservations: [],
          triggerFactors: TriggerFactorData(),
          dailyTreatments: [
            DailyTreatmentData(
              medicationName: 'Dépakine',
              dosage: '500mg',
              relatedPathologyIds: const ['p1'],
            ),
          ],
          discontinuedTreatments: [],
          emergencyTreatments: [],
          allergies: [
            AllergyData(
              allergyId: 'a1',
              allergen: 'Arachides',
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
          home: MedicalQuestionnaireRecapPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          '1. Mettre en position latérale de sécurité',
        ),
        findsOneWidget,
      );

      // La fiche est une longue liste défilante : les sections plus
      // bas (allergies, traitements) ne sont réalisées dans l'arbre
      // de widgets qu'une fois défilées jusqu'à leur position.
      await tester.scrollUntilVisible(
        find.textContaining(
          '1. Administrer l’auto-injecteur',
        ),
        300,
      );
      expect(
        find.textContaining(
          '1. Administrer l’auto-injecteur',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.textContaining('Épilepsie'),
        300,
      );
      expect(
        find.textContaining('Épilepsie'),
        findsWidgets,
      );
    },
  );
}
