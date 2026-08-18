import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/activity_profile_pages/transport_page.dart';
import 'package:safekids/activity_profile_pages/walking_effort_page.dart';
import 'package:safekids/controllers/activity_profile_controller.dart';

/// Corrigé (19/08/2026) : répondre "oui" au mal des transports sans
/// cocher aucun moyen de transport concerné laissait passer un profil
/// incomplet — la règle de recommandation ne lit que la liste des
/// moyens de transport, jamais la réponse "oui" globale, donc ce
/// "oui" ne générait jamais aucune recommandation.
void main() {
  testWidgets(
    'Mal des transports "oui" sans aucun moyen de transport coché '
    'bloque "Continuer"',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransportPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oui').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Voiture'),
        findsOneWidget,
        reason:
            'La liste des moyens de transport doit apparaître une '
            'fois "oui" sélectionné.',
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'au moins un moyen de transport',
        ),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir continuer sans avoir précisé au '
            'moins un moyen de transport concerné.',
      );
      expect(find.byType(TransportPage), findsOneWidget);
      expect(
        find.byType(WalkingEffortPage),
        findsNothing,
      );
    },
  );
}
