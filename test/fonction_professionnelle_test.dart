import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/professional/fonction_professionnelle.dart';

// Le sélecteur de fonction professionnelle (25/08/2026).
//
// Ce que la personne choisit ici est recopié tel quel sous chaque note
// qu'elle écrira sur un enfant, et lu par son parent. D'où les tests
// sur ce qui sort du sélecteur, plus que sur son apparence.

/// Monte le sélecteur seul et rend la dernière valeur qu'il a émise.
Future<String? Function()> _monter(
  WidgetTester tester, {
  String? valeurInitiale,
}) async {
  String? derniere;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelecteurFonction(
          valeurInitiale: valeurInitiale,
          onChanged: (fonction) => derniere = fonction,
        ),
      ),
    ),
  );

  return () => derniere;
}

Future<void> _choisir(WidgetTester tester, String libelle) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle).last);
  await tester.pumpAndSettle();
}

void main() {
  group('La liste arrêtée le 25/08/2026', () {
    test('Elle contient les huit fonctions validées, dans l’ordre', () {
      // Ce n'est pas une constante technique : elle décide de ce que
      // des parents liront pendant des années.
      expect(fonctionsProposees, [
        'Enseignant·e',
        'ATSEM',
        'AESH / AVS',
        'Direction',
        'Animation',
        'Restauration',
        'Santé scolaire (infirmerie)',
        'Auxiliaire de puériculture',
      ]);
    });

    test('Aucune entrée n’est un rôle administratif', () {
      // `directeur`, `adjoint`, `membre` disent qui gère l'équipe dans
      // l'application, jamais qui s'occupe de l'enfant.
      for (final fonction in fonctionsProposees) {
        expect(fonction, isNot('directeur'));
        expect(fonction, isNot('adjoint'));
        expect(fonction, isNot('membre'));
      }
    });

    test('Aucune entrée ne dépasse la borne de la base', () {
      for (final fonction in fonctionsProposees) {
        expect(fonction.length, lessThanOrEqualTo(longueurMaxFonction));
      }
    });
  });

  group('Ce que le sélecteur rend', () {
    testWidgets('Rien tant que rien n’est choisi', (tester) async {
      final valeur = await _monter(tester);

      expect(valeur(), isNull);
    });

    testWidgets('Le libellé exact de la liste, sans retouche',
        (tester) async {
      final valeur = await _monter(tester);

      await _choisir(tester, 'Restauration');

      expect(valeur(), 'Restauration');
    });

    testWidgets('« Autre » seul ne vaut rien de choisi', (tester) async {
      // Le piège : la personne ouvre « Autre », n'écrit rien, et
      // l'écran croit avoir une fonction. Le parent lirait une ligne
      // vide sous une observation sur son enfant.
      final valeur = await _monter(tester);

      await _choisir(tester, 'Autre…');

      expect(valeur(), isNull);
    });

    testWidgets('« Autre » rend ce qui a été écrit', (tester) async {
      final valeur = await _monter(tester);

      await _choisir(tester, 'Autre…');

      await tester.enterText(
        find.byType(TextField),
        'Chauffeur du car de ramassage',
      );
      await tester.pump();

      expect(valeur(), 'Chauffeur du car de ramassage');
    });

    testWidgets('Un texte d’espaces ne compte pas', (tester) async {
      final valeur = await _monter(tester);

      await _choisir(tester, 'Autre…');
      await tester.enterText(find.byType(TextField), '    ');
      await tester.pump();

      expect(valeur(), isNull);
    });

    testWidgets('Le champ libre n’apparaît que sous « Autre »',
        (tester) async {
      await _monter(tester);

      expect(find.byType(TextField), findsNothing);

      await _choisir(tester, 'Direction');
      expect(find.byType(TextField), findsNothing);

      await _choisir(tester, 'Autre…');
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Reprendre une fonction déjà déclarée', () {
    testWidgets('Une fonction de la liste est présélectionnée',
        (tester) async {
      await _monter(tester, valeurInitiale: 'ATSEM');

      expect(find.text('ATSEM'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Une fonction hors liste rouvre le champ libre rempli',
        (tester) async {
      // Elle vient forcément d'« Autre ». Repartir de zéro ferait
      // croire à la personne qu'elle n'avait rien saisi.
      await _monter(tester, valeurInitiale: 'Chauffeur du car');

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Chauffeur du car'), findsWidgets);
    });

    testWidgets('Une fonction vide se comporte comme rien de déclaré',
        (tester) async {
      await _monter(tester, valeurInitiale: '   ');

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Les deux écrans de saisie exigent la fonction', () {
    // Lecture des sources : ces écrans demandent un service Supabase
    // pour se monter. Ce qu'on protège est la présence du refus, pas
    // son rendu.

    String source(String chemin) => File(chemin).readAsStringSync();

    test('La création d’établissement refuse sans fonction', () {
      final code = source(
        'lib/professional/establishment_onboarding_page.dart',
      );

      expect(code, contains('SelecteurFonction('));
      expect(code, contains('if (_fonction == null)'));
      expect(code, contains('fonction: _fonction,'));
    });

    test('« Ma fonction » refuse un choix inexploitable', () {
      final code =
          source('lib/professional/team_management_page.dart');

      expect(code, contains('SelecteurFonction('));
      expect(code, contains('setMyFonction('));
      expect(code, contains('if (fonction == null)'));
    });

    test('Le geste n’est proposé que sur sa propre ligne', () {
      // Personne ne déclare la fonction d'un autre : il devinerait.
      // Le garde-fou tient en base ; l'écran ne propose simplement pas
      // le geste ailleurs.
      final code =
          source('lib/professional/team_management_page.dart');

      expect(code, contains('membre.userId == _myUserId'));
      expect(code, contains("tooltip: 'Ma fonction'"));
    });
  });

  group('La signature d’une note', () {
    test('Rien de choisi n’est pas utilisable', () {
      expect(
        const SignatureNote(null, dejaEnregistree: false).utilisable,
        isFalse,
      );
    });

    test('Une fonction choisie est utilisable', () {
      const signature = SignatureNote(
        'ATSEM',
        dejaEnregistree: false,
      );

      expect(signature.utilisable, isTrue);
      expect(signature.fonction, 'ATSEM');
    });

    test('Déjà enregistrée, elle n’a rien à réécrire', () {
      const signature = SignatureNote(
        'Direction',
        dejaEnregistree: true,
      );

      expect(signature.utilisable, isTrue);
      expect(signature.dejaEnregistree, isTrue);
    });

    testWidgets(
      'Sans connexion, le champ propose la saisie au lieu de bloquer',
      (tester) async {
        // La lecture de la fonction échoue (pas de Supabase en test).
        // Le professionnel doit pouvoir ressaisir : la base recevra la
        // même valeur, et jamais un blocage définitif.
        SignatureNote? rendue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChampSignatureNote(
                etablissementId: 'etab-1',
                onChanged: (signature) => rendue = signature,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(SelecteurFonction), findsOneWidget);
        expect(rendue?.utilisable, isFalse);
      },
    );
  });

  group('Pas de note écrite sans fonction', () {
    // Décision du 25/08/2026. C'est le seul moyen que la promesse faite
    // au parent soit vraie pour toutes les notes futures.

    String source(String chemin) => File(chemin).readAsStringSync();

    const ecrans = [
      'lib/professional/add_activity_note_page.dart',
      'lib/professional/activity_note_page.dart',
    ];

    test('Les deux écrans qui écrivent une note portent le filet', () {
      for (final ecran in ecrans) {
        final code = source(ecran);

        expect(
          code,
          contains('ChampSignatureNote('),
          reason: '$ecran ne demande pas la fonction',
        );
        expect(
          code,
          contains('if (signature == null || !signature.utilisable)'),
          reason: '$ecran ne refuse pas sans fonction',
        );
      }
    });

    test('Le refus tombe avant l’enregistrement, jamais après', () {
      for (final ecran in ecrans) {
        final code = source(ecran);

        expect(
          code.indexOf('!signature.utilisable'),
          lessThan(code.indexOf('.saveNote(')),
          reason: '$ecran enregistre avant de vérifier',
        );
      }
    });

    test('La fonction n’est réécrite que si elle a changé', () {
      for (final ecran in ecrans) {
        expect(
          source(ecran),
          contains('if (!signature.dejaEnregistree)'),
          reason: '$ecran réécrit une fonction inchangée',
        );
      }
    });

    test('Les deux écrans savent de quel établissement il s’agit', () {
      // Sans lui, impossible de lire ni d'écrire la fonction : elle est
      // portée par le rattachement, pas par le compte.
      for (final ecran in ecrans) {
        expect(source(ecran), contains('widget.etablissementId'));
      }
    });
  });
}
