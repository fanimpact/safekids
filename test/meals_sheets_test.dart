import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_pages/activity_clothing_change_page.dart';
import 'package:kidsrelay/activity_pages/activity_meals_page.dart';
import 'package:kidsrelay/care_info/care_info_sheet_page.dart';
import 'package:kidsrelay/emergency_info/emergency_info_sheet_page.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/activity_session/activity_session_codec.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/meals_data.dart';
import 'package:kidsrelay/models/other_information_data.dart';
import 'package:kidsrelay/models/overnight_stay_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/safety_data.dart';
import 'package:kidsrelay/models/toilets_data.dart';
import 'package:kidsrelay/models/transitions_data.dart';
import 'package:kidsrelay/models/transport_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/models/walking_effort_data.dart';
import 'package:kidsrelay/questionnaire_recap/activity_questionnaire_recap_page.dart';

/// Où la section Repas ressort, et surtout où elle ne ressort pas :
///
/// - "Ce qu'il faut savoir sur..." : toute la section ;
/// - fiche secours : UNIQUEMENT le risque de fausse route (les
///   allergies y restent affichées comme avant, sans condition) ;
/// - récapitulatif du questionnaire : les neuf questions.
void main() {
  CompleteChildProfileData buildChild({
    required MealsData meals,
    List<AllergyData> allergies = const [],
  }) {
    return CompleteChildProfileData(
      essentialInformation: ChildProfileData(
        childId: 'enfant-fiches',
        userId: 'test-user',
        identity: IdentityData(
          firstName: 'Camille',
          lastName: 'Durand',
        ),
        pathologies: const [],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: allergies,
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      ),
      activityProfile: ActivityProfileData(
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
        meals: meals,
      ),
    );
  }

  MealsData fullMeals() {
    return MealsData(
      hasChokingRisk: true,
      preparations: {MealPreparation.smallPieces},
      requiresSpecificSeating: true,
      seatingDetails: 'Chaise à accoudoirs',
      hasWarningSigns: true,
      warningSignsDetails: 'Toux répétée : arrêter le repas',
      requiresAssistance: true,
      assistanceLevel: MealAssistanceLevel.fullyFedByAdult,
      requiresSpecialEquipment: true,
      specialEquipmentDetails: 'Verre à bec',
      requiresIncreasedHydration: true,
      hasDietaryRestrictions: true,
      dietaryRestrictions: {MealDietaryRestriction.glutenFree},
      hasFoodRefusals: true,
      foodRefusalDetails: 'Légumes verts',
      refusalStance: MealRefusalStance.doNotInsist,
      hasOtherInformation: true,
      otherInformationDetails: 'Mange lentement',
    );
  }

  AllergyData foodAllergy() {
    return AllergyData(
      allergyId: 'a-food',
      categories: {AllergyCategory.food},
      details: {AllergyCategory.food: 'Arachide'},
      observedReaction: 'Œdème',
    );
  }

  group('Fiche "Ce qu’il faut savoir sur..."', () {
    testWidgets(
      'Affiche toute la section Repas',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CareInfoSheetPage(
              child: buildChild(meals: fullMeals()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final expected in [
          'risque de fausse route',
          'Chaise à accoudoirs',
          'Toux répétée',
          'nourri entièrement par un adulte',
          'Verre à bec',
          'hydratation renforcée',
          'sans gluten',
          'Légumes verts',
          'Mange lentement',
        ]) {
          expect(
            find.textContaining(expected),
            findsWidgets,
            reason: '"$expected" doit figurer sur la fiche.',
          );
        }
      },
    );

    testWidgets(
      'L’allergie alimentaire est rattachée au repas, pas listée à '
      'part, et n’apparaît qu’une fois',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CareInfoSheetPage(
              child: buildChild(
                meals: MealsData(),
                allergies: [foodAllergy()],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Repas — allergie alimentaire'),
          findsOneWidget,
        );

        expect(
          find.textContaining('Arachide'),
          findsOneWidget,
          reason:
              'Rattachée au repas, elle ne doit pas rester en plus '
              'dans la liste générale des allergies.',
        );
      },
    );

    testWidgets(
      'Une allergie non alimentaire reste dans la liste générale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CareInfoSheetPage(
              child: buildChild(
                meals: MealsData(),
                allergies: [
                  AllergyData(
                    allergyId: 'a-insect',
                    categories: {AllergyCategory.insectSting},
                    details: {
                      AllergyCategory.insectSting: 'Guêpe',
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Allergie : Guêpe'), findsWidgets);
        expect(
          find.textContaining('Repas — allergie alimentaire'),
          findsNothing,
        );
      },
    );
  });

  group('Fiche secours', () {
    testWidgets(
      'Affiche le risque de fausse route et sa préparation',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyInfoSheetPage(
              child: buildChild(meals: fullMeals()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Repas'), findsOneWidget);
        expect(
          find.textContaining('Risque de fausse route'),
          findsOneWidget,
        );
        expect(
          find.textContaining('couper en petits morceaux'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'N’affiche rien d’autre de la section Repas',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyInfoSheetPage(
              child: buildChild(meals: fullMeals()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final absent in [
          'Chaise à accoudoirs',
          'Verre à bec',
          'Légumes verts',
          'Mange lentement',
          'hydratation renforcée',
        ]) {
          expect(
            find.textContaining(absent),
            findsNothing,
            reason:
                'Cette fiche est faite pour des secours : "$absent" '
                'n’y a pas sa place.',
          );
        }
      },
    );

    testWidgets(
      'Sans risque de fausse route, aucune section Repas',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyInfoSheetPage(
              child: buildChild(
                meals: MealsData(
                  hasChokingRisk: false,
                  requiresIncreasedHydration: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Repas'), findsNothing);
      },
    );

    testWidgets(
      'Les allergies y restent affichées sans condition, inchangées',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyInfoSheetPage(
              child: buildChild(
                meals: MealsData(),
                allergies: [foodAllergy()],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Allergies et réactions connues'),
          findsOneWidget,
        );
        expect(find.textContaining('Arachide'), findsWidgets);
      },
    );
  });

  group('Récapitulatif du questionnaire Activités', () {
    testWidgets(
      'La section Repas y figure avec ses neuf questions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ActivityQuestionnaireRecapPage(
              child: buildChild(meals: fullMeals()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Le récapitulatif est une ListView : les sections hors écran
        // ne sont pas construites, il faut défiler jusqu'à Repas.
        final list = find.byType(Scrollable).first;

        await tester.scrollUntilVisible(
          find.text('Repas'),
          300,
          scrollable: list,
        );
        await tester.pumpAndSettle();

        expect(find.text('Repas'), findsOneWidget);

        for (final question in [
          'risque de fausse route',
          'installé d’une façon particulière',
          'signes qui doivent alerter',
          'besoin d’aide pendant la prise du repas',
          'matériel particulier pour manger',
          'hydratation renforcée',
          'aliments que votre enfant ne doit pas manger',
          'aliments que votre enfant refuse',
          'autre chose d’important à savoir sur les repas',
        ]) {
          await tester.scrollUntilVisible(
            find.textContaining(question),
            300,
            scrollable: list,
          );
          await tester.pumpAndSettle();

          expect(
            find.textContaining(question),
            findsWidgets,
            reason: 'La question "$question" doit être restituée.',
          );
        }
      },
    );
  });

  group('Déclenchement côté activité', () {
    testWidgets(
      'La question est posée en fin de questionnaire d’activité',
      (tester) async {
        final sessionData = ActivitySessionData();

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityMealsPage(sessionData: sessionData),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Cette activité comprend-elle un repas, un goûter ou une collation ?',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'On ne peut pas continuer sans répondre',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ActivityMealsPage(
              sessionData: ActivitySessionData(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Continuer'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Répondez à la question avant de continuer.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'La section "Changement de tenue" enchaîne sur la question repas',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ActivityClothingChangePage(
              sessionData: ActivitySessionData(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Non'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Continuer'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivityMealsPage), findsOneWidget);
      },
    );

    test(
      'La réponse est enregistrée avec l’activité',
      () {
        final activity = ActivitySessionData(hasMeal: true);

        final description =
            ActivitySessionCodec.descriptionToJson(activity);

        expect(description['hasMeal'], isTrue);

        final restored = ActivitySessionCodec.activityFromRow({
          'nom_activite': 'Sortie',
          'description': description,
        });

        expect(restored.hasMeal, isTrue);
      },
    );

    test(
      'Une activité enregistrée avant cette question reste lisible',
      () {
        final restored = ActivitySessionCodec.activityFromRow({
          'nom_activite': 'Ancienne sortie',
          'description': <String, dynamic>{},
        });

        expect(
          restored.hasMeal,
          isNull,
          reason:
              'Pas de repas supposé : sans réponse, la section Repas '
              'ne remonte pas.',
        );
      },
    );
  });
}
