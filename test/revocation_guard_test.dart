import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/professional/revocation_guard.dart';

/// Corrections de l'audit passe 3, item 13 : une fiche professionnelle
/// déjà ouverte doit se refermer d'elle-même si l'accès à l'enfant a
/// été révoqué ou a expiré entre-temps, au lieu d'attendre un
/// rechargement manuel.
///
/// Le contrôle réel interroge Supabase (non disponible dans ces tests
/// de widgets, comme partout ailleurs dans ce projet) : ce test
/// vérifie donc surtout la règle de sécurité la plus importante —
/// qu'une vérification qui échoue (pas de réseau, pas de session)
/// n'entraîne jamais une fermeture intempestive, seule une absence
/// confirmée de la fiche doit le faire.
void main() {
  testWidgets(
    'Affiche normalement son contenu, et une vérification qui '
    'échoue (pas de connexion Supabase) ne ferme jamais la fiche '
    'par erreur',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RevocationGuard(
            childId: 'test-child',
            child: Scaffold(
              body: Text('Fiche de test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fiche de test'), findsOneWidget);

      // Fait avancer l'horloge au-delà d'un cycle de vérification
      // périodique : sans connexion Supabase, l'appel échoue et doit
      // être ignoré silencieusement, jamais interprété comme "accès
      // perdu".
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      expect(
        find.text('Fiche de test'),
        findsOneWidget,
        reason:
            'Un problème réseau ou l’absence de session ne doit '
            'jamais fermer la fiche — seule une absence confirmée '
            '(RLS) le doit.',
      );
      expect(find.text('Accès révoqué'), findsNothing);
    },
  );
}
