import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/suppression/section_suppression_compte.dart';
import 'package:kidsrelay/suppression/suppression_compte_service.dart';

// La demande de suppression, depuis Paramètres.
//
// Ce qui compte ici : qu'on ne puisse pas la déclencher par mégarde,
// que le parent sache ce qu'il perd avant de confirmer, et qu'un email
// qui ne part pas ne le laisse pas sans moyen d'annuler.

final _effacement = DateTime(2026, 8, 31, 12);

class _FauxService implements SuppressionCompteService {
  final Object? erreurDemande;
  final Object? erreurEmail;

  int demandes = 0;
  final List<DateTime> emails = [];

  _FauxService({this.erreurDemande, this.erreurEmail});

  @override
  Future<DateTime?> suppressionEnCours() async => null;

  @override
  Future<DateTime> demanderSuppression() async {
    if (erreurDemande != null) {
      throw erreurDemande!;
    }

    demandes++;
    return _effacement;
  }

  @override
  Future<void> annulerSuppression() async {}

  @override
  Future<void> envoyerEmailConfirmation(
    DateTime effacementLe,
  ) async {
    if (erreurEmail != null) {
      throw erreurEmail!;
    }

    emails.add(effacementLe);
  }
}

Future<List<DateTime>> _monter(
  WidgetTester tester,
  SuppressionCompteService service,
) async {
  final demandes = <DateTime>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SectionSuppressionCompte(
            service: service,
            onDemandeEnregistree: demandes.add,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  return demandes;
}

Future<void> _ouvrirConfirmation(WidgetTester tester) async {
  await tester.tap(
    find.widgetWithText(OutlinedButton, 'Supprimer mon compte'),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('On ne supprime pas par mégarde', () {
    testWidgets('Le bouton ouvre une confirmation, pas une suppression',
        (tester) async {
      final service = _FauxService();

      await _monter(tester, service);
      await _ouvrirConfirmation(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(service.demandes, 0);
    });

    testWidgets(
      'Tant que le mot n’est pas saisi, la confirmation est inerte',
      (tester) async {
        // Un second bouton se tape sans réfléchir ; recopier un mot
        // demande de lire.
        await _monter(tester, _FauxService());
        await _ouvrirConfirmation(tester);

        final bouton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Supprimer mon compte'),
        );

        expect(bouton.onPressed, isNull);
      },
    );

    testWidgets('Un mot approchant ne suffit pas', (tester) async {
      await _monter(tester, _FauxService());
      await _ouvrirConfirmation(tester);

      await tester.enterText(find.byType(TextField), 'supprime');
      await tester.pumpAndSettle();

      final bouton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Supprimer mon compte'),
      );

      expect(bouton.onPressed, isNull);
    });

    testWidgets('Le mot exact ouvre la confirmation, casse comprise',
        (tester) async {
      await _monter(tester, _FauxService());
      await _ouvrirConfirmation(tester);

      await tester.enterText(find.byType(TextField), 'supprimer');
      await tester.pumpAndSettle();

      final bouton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Supprimer mon compte'),
      );

      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('Renoncer ne déclenche rien', (tester) async {
      final service = _FauxService();

      await _monter(tester, service);
      await _ouvrirConfirmation(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();

      expect(service.demandes, 0);
    });
  });

  group('Le parent sait ce qu’il perd', () {
    testWidgets('La confirmation énumère ce qui sera effacé',
        (tester) async {
      await _monter(tester, _FauxService());
      await _ouvrirConfirmation(tester);

      expect(
        find.textContaining('les profils de tous vos enfants'),
        findsOneWidget,
      );
      expect(
        find.textContaining('leurs informations de santé'),
        findsOneWidget,
      );
      expect(
        find.textContaining('vos liens de partage'),
        findsOneWidget,
      );
    });

    testWidgets('Et rappelle le délai de sept jours', (tester) async {
      await _monter(tester, _FauxService());
      await _ouvrirConfirmation(tester);

      expect(
        find.textContaining('7 jours pour changer d’avis'),
        findsOneWidget,
      );
    });

    testWidgets('La section propose d’exporter avant de partir',
        (tester) async {
      await _monter(tester, _FauxService());

      expect(
        find.textContaining('Pensez à exporter vos données avant'),
        findsOneWidget,
      );
    });
  });

  group('Une fois confirmée', () {
    Future<List<DateTime>> confirmer(
      WidgetTester tester,
      _FauxService service,
    ) async {
      final demandes = await _monter(tester, service);

      await _ouvrirConfirmation(tester);
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, 'Supprimer mon compte'),
      );
      await tester.pumpAndSettle();

      return demandes;
    }

    testWidgets('La demande part, et l’email avec', (tester) async {
      final service = _FauxService();
      final demandes = await confirmer(tester, service);

      expect(service.demandes, 1);
      expect(service.emails, [_effacement]);
      expect(demandes, [_effacement]);
      expect(
        find.textContaining('Un email vous confirme la date'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Un email qui ne part pas n’annule pas la demande, mais est dit',
      (tester) async {
        // La demande est déjà enregistrée. Si le parent attendait un
        // email qui ne vient pas, il ne saurait ni la date ni comment
        // annuler.
        final service = _FauxService(
          erreurEmail: StateError('Brevo indisponible'),
        );

        final demandes = await confirmer(tester, service);

        expect(service.demandes, 1);
        expect(demandes, [_effacement]);
        expect(
          find.textContaining('31/08/2026'),
          findsOneWidget,
        );
        expect(
          find.textContaining('n’a pas pu être envoyé'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Une demande qui échoue ne supprime rien et le dit',
      (tester) async {
        final service = _FauxService(
          erreurDemande: StateError('hors ligne'),
        );

        final demandes = await confirmer(tester, service);

        expect(service.demandes, 0);
        expect(service.emails, isEmpty);
        expect(demandes, isEmpty);
        expect(
          find.textContaining('Rien n’a été supprimé'),
          findsOneWidget,
        );
      },
    );
  });
}
