import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_profile_pages/meals_page.dart';
import 'package:kidsrelay/activity_profile_pages/other_information_page.dart';
import 'package:kidsrelay/controllers/activity_profile_controller.dart';
import 'package:kidsrelay/models/activity_profile_draft.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/meals_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/repositories/child_repository.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Section Repas du profil Activités (22/08/2026). Aucune question
/// filtre : les neuf questions sont posées à tous les parents, aucune
/// réponse n'est présélectionnée, et on ne peut pas continuer sans
/// avoir répondu à chacune — mêmes conventions que les sections
/// eau/transport/nuitée/sécurité.
void main() {
  const questions = [
    'risque de fausse route',
    'installé d’une façon particulière',
    'signes qui doivent alerter',
    'besoin d’aide pendant la prise du repas',
    'matériel particulier pour manger',
    'hydratation renforcée',
    'aliments que votre enfant ne doit pas manger',
    'aliments que votre enfant refuse',
    'autre chose d’important à savoir sur les repas',
  ];

  Finder yesNoField(String labelContains) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is SkYesNoField &&
          widget.label.contains(labelContains),
    );
  }

  Future<void> answer(
    WidgetTester tester,
    String labelContains,
    bool value,
  ) async {
    final finder = yesNoField(labelContains);

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    tester.widget<SkYesNoField>(finder).onChanged(value);
    await tester.pumpAndSettle();
  }

  Future<void> answerEverything(
    WidgetTester tester,
    bool value,
  ) async {
    for (final question in questions) {
      await answer(tester, question, value);
    }
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ActivityProfileController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MealsPage(
          activityProfileController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Continuer');

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  setUp(() {
    ChildRepository.instance.clearForTesting();
  });

  group('Encart en tête de section', () {
    testWidgets(
      'Nomme l’enfant et annonce que les allergies sont reprises '
      'automatiquement',
      (tester) async {
        ChildRepository.instance.seedForTesting(
          ChildProfileData(
            childId: 'enfant-repas',
            userId: 'test-user',
            identity: IdentityData(firstName: 'Camille'),
            pathologies: const [],
            medicalEvents: const [],
            medicalObservations: const [],
            triggerFactors: TriggerFactorData(),
            dailyTreatments: const [],
            discontinuedTreatments: const [],
            emergencyTreatments: const [],
            allergies: const [],
            medicalDevices: const [],
            contacts: const [],
            primaryCareDoctor: PrimaryCareDoctorData(),
          ),
        );

        await pumpPage(
          tester,
          ActivityProfileController(
            initialDraft: ActivityProfileDraft(
              childId: 'enfant-repas',
            ),
          ),
        );

        expect(
          find.textContaining(
            'repris automatiquement depuis le profil santé de Camille',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Reste lisible quand le prénom n’est pas encore connu',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        expect(
          find.textContaining(
            'depuis le profil santé de votre enfant',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Aucune question filtre, aucune présélection', () {
    testWidgets(
      'Les neuf questions sont posées d’emblée',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        for (final question in questions) {
          expect(
            yesNoField(question),
            findsOneWidget,
            reason: 'La question "$question" doit être posée.',
          );
        }
      },
    );

    testWidgets(
      'Aucune réponse n’est présélectionnée',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        for (final question in questions) {
          expect(
            tester.widget<SkYesNoField>(yesNoField(question)).value,
            isNull,
            reason:
                'Une présélection ferait valider "$question" sans y '
                'penser.',
          );
        }
      },
    );

    testWidgets(
      'On ne peut pas continuer sans avoir répondu à tout',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        await answer(tester, 'risque de fausse route', false);

        await tapContinue(tester);

        expect(
          find.text(
            'Répondez par oui ou par non à chaque question avant de continuer.',
          ),
          findsOneWidget,
        );

        expect(find.byType(OtherInformationPage), findsNothing);
      },
    );

    testWidgets(
      'Une fois tout répondu, on passe à la section suivante',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        await answerEverything(tester, false);
        await tapContinue(tester);

        expect(
          find.byType(OtherInformationPage),
          findsOneWidget,
          reason:
              'Repas s’insère avant "Autres informations", qui reste '
              'la dernière section du parcours.',
        );
      },
    );
  });

  group('Sous-questions', () {
    testWidgets(
      'Les précisions n’apparaissent qu’après un "Oui"',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        expect(find.text('Couper en petits morceaux'), findsNothing);

        await answer(tester, 'risque de fausse route', true);

        expect(
          find.text('Couper en petits morceaux'),
          findsOneWidget,
        );
        expect(find.text('Boissons épaissies'), findsOneWidget);
      },
    );

    testWidgets(
      'La case "Autre" ouvre son champ de précision',
      (tester) async {
        final controller = ActivityProfileController();
        await pumpPage(tester, controller);

        await answer(tester, 'risque de fausse route', true);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SkTextField &&
                widget.label.contains('Précisez cette préparation'),
          ),
          findsNothing,
        );

        final otherCheckbox = find.byWidgetPredicate(
          (widget) =>
              widget is CheckboxListTile &&
              widget.title is Text &&
              (widget.title as Text).data == 'Autre',
        );

        await tester.ensureVisible(otherCheckbox);
        await tester.pumpAndSettle();

        tester.widget<CheckboxListTile>(otherCheckbox).onChanged!(true);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SkTextField &&
                widget.label.contains('Précisez cette préparation'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Le choix du niveau d’aide est unique',
      (tester) async {
        await pumpPage(tester, ActivityProfileController());

        await answer(
          tester,
          'besoin d’aide pendant la prise du repas',
          true,
        );

        expect(
          find.textContaining('Il mange seul mais quelqu’un doit'),
          findsOneWidget,
        );
        expect(
          find.textContaining('nourri entièrement par un adulte'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Repasser à "Non" efface la précision déjà saisie',
      (tester) async {
        final controller = ActivityProfileController();
        await pumpPage(tester, controller);

        await answer(
          tester,
          'installé d’une façon particulière',
          true,
        );

        final field = find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Précisez cette installation'),
        );

        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        await tester.enterText(field, 'Chaise à accoudoirs');
        await tester.pumpAndSettle();

        expect(
          controller.draft.meals.seatingDetails,
          equals('Chaise à accoudoirs'),
        );

        await answer(
          tester,
          'installé d’une façon particulière',
          false,
        );

        expect(
          controller.draft.meals.seatingDetails,
          isNull,
          reason:
              'Une réponse retirée de l’écran ne doit pas survivre en '
              'arrière-plan.',
        );
      },
    );
  });

  group('Enregistrement dans le brouillon', () {
    testWidgets(
      'Les réponses sont bien portées par la section Repas',
      (tester) async {
        final controller = ActivityProfileController();
        await pumpPage(tester, controller);

        await answerEverything(tester, false);
        await answer(tester, 'hydratation renforcée', true);

        final meals = controller.draft.meals;

        expect(meals.requiresIncreasedHydration, isTrue);
        expect(meals.hasChokingRisk, isFalse);
        expect(meals.hasFoodRefusals, isFalse);
      },
    );

    testWidgets(
      'Un profil déjà enregistré rouvre la section pré-remplie',
      (tester) async {
        final controller = ActivityProfileController(
          initialDraft: ActivityProfileDraft(
            meals: MealsData(
              hasChokingRisk: true,
              preparations: {MealPreparation.blended},
            ),
          ),
        );

        await pumpPage(tester, controller);

        expect(
          tester
              .widget<SkYesNoField>(
                yesNoField('risque de fausse route'),
              )
              .value,
          isTrue,
        );

        final blendedCheckbox = find.byWidgetPredicate(
          (widget) =>
              widget is CheckboxListTile &&
              widget.title is Text &&
              (widget.title as Text).data == 'Alimentation mixée',
        );

        expect(
          tester.widget<CheckboxListTile>(blendedCheckbox).value,
          isTrue,
        );
      },
    );
  });
}
