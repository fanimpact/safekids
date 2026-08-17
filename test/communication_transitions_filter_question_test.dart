import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/activity_profile_pages/communication_page.dart';
import 'package:safekids/activity_profile_pages/transitions_page.dart';
import 'package:safekids/controllers/activity_profile_controller.dart';
import 'package:safekids/widgets/sk_yes_no_field.dart';

/// Contrairement aux autres sections du profil activités (voir
/// activity_profile_no_filter_question_test.dart), les sections
/// "Communication" et "Transitions" ont volontairement retrouvé une
/// question filtre au début, sur demande explicite de l'utilisatrice :
/// l'objectif est d'éviter que tous les parents remplissent une section
/// détaillée par réflexe, alors que seuls ceux réellement concernés ont
/// besoin d'y répondre en détail. La question filtre elle-même reste
/// soumise à la même exigence que partout ailleurs : aucune
/// présélection, réponse obligatoire avant de continuer.
void main() {
  bool? yesNoValue(WidgetTester tester, String labelContains) {
    final field = tester.widget<SkYesNoField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SkYesNoField &&
            widget.label.contains(labelContains),
      ),
    );

    return field.value;
  }

  group('Communication', () {
    testWidgets(
      'la question filtre est visible, sans présélection, et les '
      'questions détaillées sont cachées tant qu\'elle n\'est pas '
      'répondue',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CommunicationPage(
              activityProfileController:
                  ActivityProfileController(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Votre enfant peut-il donner l’impression d’avoir compris une consigne alors que ce n’est pas le cas ?',
          ),
          findsOneWidget,
        );
        expect(
          yesNoValue(tester, 'donner l’impression d’avoir compris'),
          isNull,
        );
        expect(
          find.text(
            'Les consignes doivent être formulées avec des mots simples.',
          ),
          findsNothing,
          reason:
              'Les questions détaillées ne doivent pas être visibles '
              'tant que la question filtre n\'a pas de réponse "Oui".',
        );

        await tester.ensureVisible(find.text('Continuer'));
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('avant de continuer'),
          findsOneWidget,
          reason:
              'On ne doit pas pouvoir continuer sans avoir répondu à '
              'la question filtre.',
        );
      },
    );

    testWidgets(
      'répondre "Oui" à la question filtre affiche les questions '
      'détaillées, elles aussi sans présélection',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CommunicationPage(
              activityProfileController:
                  ActivityProfileController(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final filterField = tester.widget<SkYesNoField>(
          find.byWidgetPredicate(
            (widget) =>
                widget is SkYesNoField &&
                widget.label.contains(
                  'donner l’impression d’avoir compris',
                ),
          ),
        );
        filterField.onChanged(true);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Les consignes doivent être formulées avec des mots simples.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Votre enfant utilise-t-il un support de communication particulier ?',
          ),
          findsOneWidget,
        );
        expect(
          yesNoValue(tester, 'un support de communication'),
          isNull,
        );

        await tester.ensureVisible(find.text('Continuer'));
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('avant de continuer'),
          findsOneWidget,
          reason:
              'La question sur le support de communication reste '
              'obligatoire une fois la section ouverte.',
        );
      },
    );
  });

  group('Transitions', () {
    testWidgets(
      'la question filtre est visible, sans présélection, et les '
      'questions détaillées sont cachées tant qu\'elle n\'est pas '
      'répondue',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TransitionsPage(
              activityProfileController:
                  ActivityProfileController(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Votre enfant nécessite-t-il des adaptations particulières lors des transitions ou des changements d’activité, par rapport à un enfant de son âge ?',
          ),
          findsOneWidget,
        );
        expect(
          yesNoValue(
            tester,
            'des adaptations particulières lors des transitions',
          ),
          isNull,
        );
        expect(
          find.text(
            'Les changements d’activité peuvent provoquer un stress important.',
          ),
          findsNothing,
        );

        await tester.ensureVisible(find.text('Continuer'));
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('avant de continuer'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'répondre "Oui" à la question filtre affiche les questions '
      'détaillées',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TransitionsPage(
              activityProfileController:
                  ActivityProfileController(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final filterField = tester.widget<SkYesNoField>(
          find.byWidgetPredicate(
            (widget) =>
                widget is SkYesNoField &&
                widget.label.contains(
                  'des adaptations particulières lors des transitions',
                ),
          ),
        );
        filterField.onChanged(true);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Les changements d’activité peuvent provoquer un stress important.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Les changements de programme doivent être annoncés à l’avance.',
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(find.text('Continuer'));
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();

        expect(
          find.byType(TransitionsPage),
          findsNothing,
          reason:
              'Les deux questions détaillées sont des cases à cocher '
              '(facultatives) : une fois la question filtre répondue, '
              'on doit pouvoir continuer.',
        );
      },
    );
  });
}
