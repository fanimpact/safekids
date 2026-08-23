import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/export/section_export.dart';
import 'package:kidsrelay/export/service_export.dart';
import 'package:kidsrelay/export/source_export.dart';

// La section « Exporter mes données » de l'écran Paramètres.
//
// Le point central : une personne de confiance en consultation seule
// arrive sur le même écran d'accueil qu'un parent, donc sur le même
// écran Paramètres. L'absence du bouton doit être décidée, pas héritée
// de la navigation.

class _FauxService implements ServiceExport {
  final bool disponible;
  final Object? erreur;

  /// Bloquée tant que le test ne la libère pas, pour observer l'état
  /// intermédiaire.
  final Completer<void>? attente;

  int appelsExport = 0;

  _FauxService({
    this.disponible = true,
    this.erreur,
    this.attente,
  });

  @override
  Future<bool> estDisponible() async => disponible;

  @override
  Future<void> exporterEtPartager() async {
    appelsExport++;

    if (attente != null) {
      await attente!.future;
    }

    if (erreur != null) {
      throw erreur!;
    }
  }
}

Future<void> _monter(
  WidgetTester tester,
  ServiceExport service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SectionExportDonnees(service: service),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('Qui voit le bouton', () {
    testWidgets('Un parent qui possède un enfant le voit', (tester) async {
      await _monter(tester, _FauxService(disponible: true));

      expect(find.text('Exporter mes données'), findsOneWidget);
    });

    testWidgets(
      'Une personne de confiance ne le voit pas',
      (tester) async {
        await _monter(tester, _FauxService(disponible: false));

        expect(find.text('Exporter mes données'), findsNothing);
      },
    );

    testWidgets(
      'Elle lit pourquoi, plutôt que de trouver un écran amputé',
      (tester) async {
        // Une absence muette laisserait croire à un défaut de
        // l'application.
        await _monter(tester, _FauxService(disponible: false));

        expect(
          find.textContaining(
            'réservé au parent qui a créé les fiches',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Aucun export ne peut être lancé quand la fonction est refusée',
      (tester) async {
        final service = _FauxService(disponible: false);

        await _monter(tester, service);

        expect(find.byType(OutlinedButton), findsNothing);
        expect(service.appelsExport, 0);
      },
    );
  });

  group('Déroulement de l’export', () {
    testWidgets('Le bouton lance l’export', (tester) async {
      final service = _FauxService();

      await _monter(tester, service);
      await tester.tap(find.text('Exporter mes données'));
      await tester.pumpAndSettle();

      expect(service.appelsExport, 1);
    });

    testWidgets(
      'Pendant la préparation, le bouton le dit et ne repart pas',
      (tester) async {
        // Un export peut prendre plusieurs secondes sur un profil
        // rempli : sans retour, l'utilisateur appuie deux fois.
        final attente = Completer<void>();
        final service = _FauxService(attente: attente);

        await _monter(tester, service);
        await tester.tap(find.text('Exporter mes données'));
        await tester.pump();

        expect(find.text('Préparation en cours…'), findsOneWidget);

        await tester.tap(
          find.text('Préparation en cours…'),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(service.appelsExport, 1);

        attente.complete();
        await tester.pumpAndSettle();

        expect(find.text('Exporter mes données'), findsOneWidget);
      },
    );
  });

  group('Refus plutôt qu’export partiel', () {
    testWidgets(
      'Un export impossible affiche sa raison',
      (tester) async {
        final service = _FauxService(
          erreur: const ExportImpossible(
            'Impossible de constituer l’export. Vérifiez votre '
            'connexion et réessayez : un export incomplet ne vous '
            'serait d’aucune aide.',
          ),
        );

        await _monter(tester, service);
        await tester.tap(find.text('Exporter mes données'));
        await tester.pump();
        await tester.pump();

        expect(
          find.textContaining('un export incomplet'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Une panne inattendue reste compréhensible',
      (tester) async {
        final service = _FauxService(
          erreur: StateError('quelque chose a cassé'),
        );

        await _monter(tester, service);
        await tester.tap(find.text('Exporter mes données'));
        await tester.pump();
        await tester.pump();

        expect(
          find.textContaining('Vérifiez votre connexion'),
          findsOneWidget,
        );
        expect(
          find.textContaining('quelque chose a cassé'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Après un échec, on peut réessayer',
      (tester) async {
        final service = _FauxService(
          erreur: const ExportImpossible('Échec.'),
        );

        await _monter(tester, service);
        await tester.tap(find.text('Exporter mes données'));
        await tester.pumpAndSettle();

        expect(find.text('Exporter mes données'), findsOneWidget);

        await tester.tap(find.text('Exporter mes données'));
        await tester.pumpAndSettle();

        expect(service.appelsExport, 2);
      },
    );
  });
}
