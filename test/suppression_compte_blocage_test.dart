import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/suppression/garde_suppression.dart';
import 'package:kidsrelay/suppression/jours_restants.dart';
import 'package:kidsrelay/suppression/suppression_compte_service.dart';
import 'package:kidsrelay/suppression/suppression_en_cours_page.dart';

// Délai de grâce à la suppression du compte : inaccessible tout de
// suite, effacé sept jours plus tard, annulable entre les deux.
//
// Ce qui est vérifié ici, c'est la moitié « application » du blocage.
// L'autre moitié est en base (RLS), et c'est elle qui tient vraiment :
// un écran ne protège rien de qui contournerait l'application. Mais
// sans écran, le parent tomberait sur une application vide sans
// comprendre pourquoi.

final _maintenant = DateTime(2026, 8, 23, 12);
final _effacement = DateTime(2026, 8, 30, 12);

class _FauxService implements SuppressionCompteService {
  DateTime? enCours;
  final Object? erreurLecture;
  final Object? erreurAnnulation;
  final Completer<void>? attenteAnnulation;

  int annulations = 0;
  int demandes = 0;
  final List<DateTime> emails = [];

  _FauxService({
    this.enCours,
    this.erreurLecture,
    this.erreurAnnulation,
    this.attenteAnnulation,
  });

  @override
  Future<DateTime?> suppressionEnCours() async {
    if (erreurLecture != null) {
      throw erreurLecture!;
    }

    return enCours;
  }

  @override
  Future<DateTime> demanderSuppression() async {
    demandes++;
    enCours = _effacement;
    return _effacement;
  }

  @override
  Future<void> annulerSuppression() async {
    if (attenteAnnulation != null) {
      await attenteAnnulation!.future;
    }

    if (erreurAnnulation != null) {
      throw erreurAnnulation!;
    }

    annulations++;
    enCours = null;
  }

  @override
  Future<void> envoyerEmailConfirmation(
    DateTime effacementLe,
  ) async {
    emails.add(effacementLe);
  }
}

const _accueil = Scaffold(
  body: Center(child: Text('Accueil de l’application')),
);

Future<void> _monterGarde(
  WidgetTester tester,
  SuppressionCompteService service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GardeSuppression(
        service: service,
        enfant: _accueil,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('Jours restants', () {
    test('Sept jours pleins', () {
      expect(joursRestants(_effacement, _maintenant), 7);
    });

    test('Une journée entamée compte pour un jour', () {
      // À 23 heures de l'échéance il reste « 1 jour », pas « 0 ».
      // Annoncer zéro à quelqu'un qui a encore le temps d'annuler
      // serait une erreur dans le sens qui fait mal.
      expect(
        joursRestants(_effacement, _effacement.subtract(
          const Duration(hours: 23),
        )),
        1,
      );
      expect(
        joursRestants(_effacement, _effacement.subtract(
          const Duration(minutes: 30),
        )),
        1,
      );
    });

    test('Une date passée ne rend jamais un nombre négatif', () {
      expect(
        joursRestants(
          _effacement,
          _effacement.add(const Duration(days: 3)),
        ),
        0,
      );
    });

    test('Le texte s’accorde', () {
      expect(texteJoursRestants(7), contains('7 jours'));
      expect(texteJoursRestants(1), contains('1 jour pour'));
      expect(texteJoursRestants(0), 'L’effacement va avoir lieu');
    });

    test('La date se lit en français', () {
      expect(
        formaterDateHeureFr(DateTime(2026, 8, 30, 9, 5)),
        '30/08/2026 à 09h05',
      );
    });
  });

  group('La barrière devant l’accueil', () {
    testWidgets('Sans demande, l’application s’ouvre normalement',
        (tester) async {
      await _monterGarde(tester, _FauxService());

      expect(find.text('Accueil de l’application'), findsOneWidget);
    });

    testWidgets('Avec une demande, l’accueil est inatteignable',
        (tester) async {
      await _monterGarde(
        tester,
        _FauxService(enCours: _effacement),
      );

      expect(find.text('Accueil de l’application'), findsNothing);
      expect(find.byType(SuppressionEnCoursPage), findsOneWidget);
    });

    testWidgets(
      'L’écran de blocage n’offre aucune autre issue',
      (tester) async {
        // Pas de retour, pas d'onglet, pas de menu : « inaccessible
        // tout de suite » serait faux si l'on pouvait sortir par un
        // côté.
        await _monterGarde(
          tester,
          _FauxService(enCours: _effacement),
        );

        expect(find.byType(BackButton), findsNothing);
        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(BottomNavigationBar), findsNothing);
      },
    );

    testWidgets(
      'Une lecture impossible laisse passer plutôt que d’enfermer',
      (tester) async {
        // Choix assumé : hors ligne, la vraie barrière est en base, et
        // il n'y a de toute façon aucune donnée à protéger ici.
        // Bloquer sur une incertitude enfermerait dehors un parent qui
        // n'a rien demandé.
        await _monterGarde(
          tester,
          _FauxService(erreurLecture: StateError('hors ligne')),
        );

        expect(find.text('Accueil de l’application'), findsOneWidget);
      },
    );
  });

  group('L’écran de suppression en cours', () {
    Future<_FauxService> monter(
      WidgetTester tester, {
      Object? erreurAnnulation,
      Completer<void>? attente,
    }) async {
      final service = _FauxService(
        enCours: _effacement,
        erreurAnnulation: erreurAnnulation,
        attenteAnnulation: attente,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SuppressionEnCoursPage(
            effacementLe: _effacement,
            service: service,
            horloge: () => _maintenant,
            onAnnule: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      return service;
    }

    testWidgets('Il annonce la date et le temps restant',
        (tester) async {
      await monter(tester);

      expect(
        find.textContaining('Il vous reste 7 jours pour annuler'),
        findsOneWidget,
      );
      expect(
        find.textContaining('30/08/2026'),
        findsOneWidget,
      );
    });

    testWidgets('Il dit que rien n’est encore effacé', (tester) async {
      await monter(tester);

      expect(
        find.textContaining('Rien n’est encore effacé'),
        findsOneWidget,
      );
      expect(
        find.textContaining('vous retrouverez tout en l’état'),
        findsOneWidget,
      );
    });

    testWidgets('Il dit que passé la date, c’est définitif',
        (tester) async {
      await monter(tester);

      expect(
        find.textContaining('nous ne pourrons rien restaurer'),
        findsOneWidget,
      );
    });

    testWidgets('L’annulation rouvre l’application', (tester) async {
      final service = _FauxService(enCours: _effacement);

      await _monterGarde(tester, service);

      await tester.tap(
        find.textContaining('Annuler la suppression'),
      );
      await tester.pumpAndSettle();

      expect(service.annulations, 1);
      expect(find.text('Accueil de l’application'), findsOneWidget);
    });

    testWidgets(
      'Une annulation qui échoue rassure sur le délai',
      (tester) async {
        final service = await monter(
          tester,
          erreurAnnulation: StateError('réseau'),
        );

        await tester.tap(
          find.textContaining('Annuler la suppression'),
        );
        await tester.pumpAndSettle();

        expect(service.annulations, 0);
        expect(
          find.textContaining(
            'vos données ne seront pas effacées avant la date',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Pendant l’annulation, le bouton ne repart pas',
      (tester) async {
        final attente = Completer<void>();
        final service = await monter(tester, attente: attente);

        await tester.tap(
          find.textContaining('Annuler la suppression'),
        );
        await tester.pump();

        final bouton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );

        expect(bouton.onPressed, isNull);

        attente.complete();
        await tester.pumpAndSettle();

        expect(service.annulations, 1);
      },
    );
  });

  group('Toutes les portes sont gardées', () {
    // Garde de câblage : il suffirait d'un `HomePage()` oublié quelque
    // part pour que le blocage ne serve à rien.

    test('Aucun écran n’ouvre l’accueil sans la barrière', () {
      final fautifs = <String>[];

      final fichiers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((chemin) => chemin.endsWith('.dart'));

      for (final chemin in fichiers) {
        if (chemin == 'lib/suppression/garde_suppression.dart') {
          continue;
        }

        final source = File(chemin).readAsStringSync();

        // `HomePage()` doit toujours être enveloppé.
        final ouvertures =
            RegExp(r'(?<![A-Za-z])(?<!enfant: )HomePage\(\)').allMatches(source);

        if (ouvertures.isNotEmpty) {
          fautifs.add(chemin);
        }
      }

      expect(
        fautifs,
        isEmpty,
        reason:
            'Ces fichiers ouvrent l’accueil sans passer par '
            'GardeSuppression : un compte en cours de suppression y '
            'entrerait comme si de rien n’était.',
      );
    });
  });
}
