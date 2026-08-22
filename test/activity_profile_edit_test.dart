import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_profile_pages/aquatic_activity_page.dart';
import 'package:kidsrelay/children/child_profile_page.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
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

/// Vérifie que le bouton "Profil Activités" de la page de profil ouvre
/// bien le questionnaire d'activités pré-rempli avec les valeurs déjà
/// enregistrées, au lieu de ne rien faire (bug signalé).
void main() {
  testWidgets(
    'Le bouton "Profil Activités" ouvre le questionnaire pré-rempli',
    (tester) async {
      final child = CompleteChildProfileData(
        essentialInformation: ChildProfileData(
          childId: 'test-child',
          userId: 'test-user',
          identity: IdentityData(firstName: 'Camille'),
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
        ),
        activityProfile: ActivityProfileData(
          aquaticActivity: AquaticActivityData(),
          transport: TransportData(),
          walkingEffort: WalkingEffortData(),
          overnightStay: OvernightStayData(),
          // Valeur non par défaut, facile à distinguer d'un profil
          // vide : c'est celle-ci qu'on vérifie être pré-remplie.
          clothing: ClothingData(requiresAssistance: true),
          toilets: ToiletsData(),
          communication: CommunicationData(),
          transitions: TransitionsData(),
          safety: SafetyData(),
          otherInformation: OtherInformationData(),
        ),
        activityProfileCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChildProfilePage(child: child)),
      );
      await tester.pumpAndSettle();

      // Le bouton est loin dans une ListView à défilement : il n'est
      // construit qu'une fois scrollé jusqu'à sa position.
      final buttonFinder = find.ancestor(
        of: find.text('Profil Activités'),
        matching: find.byType(ListTile),
      );

      await tester.scrollUntilVisible(
        buttonFinder,
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(
        find.byType(AquaticActivityPage),
        findsOneWidget,
        reason:
            'Le bouton doit ouvrir le questionnaire, pas juste afficher '
            'un message.',
      );

      final page = tester.widget<AquaticActivityPage>(
        find.byType(AquaticActivityPage),
      );

      final draft = page.activityProfileController.draft;

      expect(
        draft.childId,
        'test-child',
        reason: 'Le brouillon doit être relié au bon enfant.',
      );

      expect(
        draft.clothing.requiresAssistance,
        isTrue,
        reason:
            'Le profil Activités déjà enregistré doit être repris '
            '(ici : habillage), pas remis à zéro.',
      );
    },
  );
}
