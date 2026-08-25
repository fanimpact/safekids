import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/transmission_pages/diagnosed_pathologies_page.dart';
import 'package:kidsrelay/transmission_pages/identity_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';

/// Corrigé (19/08/2026, corrections de l'inventaire du 19/08/2026) :
/// contrairement à toutes les autres pages du questionnaire santé,
/// IdentityPage ne bloquait jamais "Continuer", même prénom, nom et
/// date de naissance vides.
void main() {
  testWidgets(
    'Continuer est bloqué tant que le prénom, le nom ou la date de '
    'naissance ne sont pas renseignés',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdentityPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('prénom et le nom'),
        findsOneWidget,
        reason:
            'Rien n’est renseigné : le message doit porter sur '
            'le prénom et le nom, premiers champs manquants.',
      );
      expect(find.byType(IdentityPage), findsOneWidget);

      // Laisse le message disparaître avant d'en déclencher un autre :
      // sinon il reste affiché par-dessus le bouton "Continuer".
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Prénom'),
        ),
        'Camille',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Nom de famille'),
        ),
        'Test',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      // Le message exact, et non un fragment : depuis le 25/08/2026 la
      // consigne en tête de l'écran nomme elle aussi la date de
      // naissance, et un `textContaining` en trouverait deux.
      expect(
        find.text('Sélectionnez la date de naissance avant de continuer.'),
        findsOneWidget,
        reason:
            'Prénom et nom renseignés, mais pas encore la date de '
            'naissance : doit encore bloquer, sur ce message précis.',
      );
      expect(find.byType(IdentityPage), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Pas de champ texte pour la date de naissance : on ouvre le
      // vrai sélecteur de date et on valide la date proposée par
      // défaut (l'écran ne pose aucune contrainte sur quelle date
      // choisir, seulement qu'une date soit choisie).
      await tester.tap(find.text('Sélectionner une date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.byType(DiagnosedPathologiesPage),
        findsOneWidget,
        reason:
            'Une fois les trois champs renseignés, "Continuer" doit '
            'enfin fonctionner.',
      );
    },
  );
}
