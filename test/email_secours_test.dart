import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/export/export_contenu.dart';
import 'package:kidsrelay/export/export_json.dart';
import 'package:kidsrelay/export/source_export.dart';
import 'package:kidsrelay/settings/compte_service.dart';
import 'package:kidsrelay/settings/email_secours.dart';
import 'package:kidsrelay/settings/section_email_secours.dart';

import 'support/fake_source_export.dart';

// Adresse de secours : une seconde adresse, facultative, qui sert
// uniquement à recontacter le parent s'il perd l'accès à son compte.
//
// C'est aussi une donnée personnelle de plus : elle doit ressortir dans
// l'export RGPD, sans quoi cet export cesserait d'être complet.

class _FauxCompteService implements CompteService {
  String? adresse;
  final Object? erreurLecture;
  final Object? erreurEcriture;

  final List<String?> enregistrements = [];

  _FauxCompteService({
    this.adresse,
    this.erreurLecture,
    this.erreurEcriture,
  });

  @override
  Future<String?> lireEmailSecours() async {
    if (erreurLecture != null) {
      throw erreurLecture!;
    }

    return adresse;
  }

  @override
  Future<void> enregistrerEmailSecours(String? email) async {
    if (erreurEcriture != null) {
      throw erreurEcriture!;
    }

    enregistrements.add(email);
    adresse = email;
  }
}

Future<void> _monter(
  WidgetTester tester,
  CompteService service, {
  String? emailPrincipal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SectionEmailSecours(
            service: service,
            emailPrincipal: emailPrincipal,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('Ce qui est accepté', () {
    test('Une adresse ordinaire passe', () {
      expect(erreurEmailSecours('mamie@exemple.fr'), isNull);
      expect(
        erreurEmailSecours('prenom.nom+kidsrelay@sous.domaine.co.uk'),
        isNull,
      );
    });

    test('Le champ vide est une réponse valable', () {
      // Il est facultatif : ne rien mettre n'est pas une erreur.
      expect(erreurEmailSecours(''), isNull);
      expect(erreurEmailSecours('   '), isNull);
    });

    test('Les espaces autour sont ignorés', () {
      expect(erreurEmailSecours('  mamie@exemple.fr  '), isNull);
      expect(
        valeurAEnregistrer('  mamie@exemple.fr  '),
        'mamie@exemple.fr',
      );
    });
  });

  group('Ce qui est refusé', () {
    test('Une adresse sans arobase', () {
      expect(erreurEmailSecours('mamie.exemple.fr'), isNotNull);
    });

    test('Une adresse à deux arobases', () {
      expect(erreurEmailSecours('a@b@c.fr'), isNotNull);
    });

    test('Une adresse avec un espace au milieu', () {
      expect(
        erreurEmailSecours('mamie @exemple.fr'),
        contains('espace'),
      );
    });

    test('Un domaine incomplet', () {
      expect(erreurEmailSecours('mamie@exemple'), isNotNull);
      expect(erreurEmailSecours('mamie@.fr'), isNotNull);
      expect(erreurEmailSecours('mamie@exemple.'), isNotNull);
    });

    test('Une partie manquante', () {
      expect(erreurEmailSecours('@exemple.fr'), isNotNull);
      expect(erreurEmailSecours('mamie@'), isNotNull);
    });
  });

  group('Vider le champ efface l’adresse', () {
    test('Une saisie vide devient null', () {
      expect(valeurAEnregistrer(''), isNull);
      expect(valeurAEnregistrer('   '), isNull);
    });

    testWidgets('Et l’enregistrement le dit', (tester) async {
      final service = _FauxCompteService(
        adresse: 'mamie@exemple.fr',
      );

      await _monter(tester, service);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(
        find.text('Enregistrer l’adresse de secours'),
      );
      await tester.pumpAndSettle();

      expect(service.enregistrements, [null]);
      expect(find.text('Adresse de secours effacée.'), findsOneWidget);
    });
  });

  group('La même adresse que le compte', () {
    test('Est détectée, quelle que soit la casse', () {
      expect(
        memeAdresseQuePrincipale(
          'Parent@Exemple.FR',
          'parent@exemple.fr',
        ),
        isTrue,
      );
    });

    test('N’est pas une erreur', () {
      // Le parent a le droit. On le prévient, on ne l'empêche pas.
      expect(erreurEmailSecours('parent@exemple.fr'), isNull);
    });

    testWidgets('Est signalée à l’enregistrement', (tester) async {
      final service = _FauxCompteService();

      await _monter(
        tester,
        service,
        emailPrincipal: 'parent@exemple.fr',
      );

      await tester.enterText(
        find.byType(TextField),
        'parent@exemple.fr',
      );
      await tester.tap(
        find.text('Enregistrer l’adresse de secours'),
      );
      await tester.pumpAndSettle();

      expect(service.enregistrements, ['parent@exemple.fr']);
      expect(
        find.textContaining('elle ne pourra pas vous secourir'),
        findsOneWidget,
      );
    });
  });

  group('L’écran', () {
    testWidgets('Affiche l’adresse déjà enregistrée', (tester) async {
      await _monter(
        tester,
        _FauxCompteService(adresse: 'mamie@exemple.fr'),
      );

      expect(find.text('mamie@exemple.fr'), findsOneWidget);
    });

    testWidgets('Dit que le champ est facultatif', (tester) async {
      await _monter(tester, _FauxCompteService());

      expect(find.textContaining('Facultatif'), findsOneWidget);
    });

    testWidgets(
      'Dit qu’aucun email n’y sera envoyé',
      (tester) async {
        // Le parent doit savoir à quoi elle sert avant de la donner.
        await _monter(tester, _FauxCompteService());

        expect(
          find.textContaining('ne reçoit aucun email'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Une saisie invalide n’est pas enregistrée',
        (tester) async {
      final service = _FauxCompteService();

      await _monter(tester, service);
      await tester.enterText(find.byType(TextField), 'pas-une-adresse');
      await tester.tap(
        find.text('Enregistrer l’adresse de secours'),
      );
      await tester.pumpAndSettle();

      expect(service.enregistrements, isEmpty);
      expect(
        find.textContaining('ne ressemble pas à une adresse email'),
        findsOneWidget,
      );
    });

    testWidgets('Une panne d’enregistrement est dite', (tester) async {
      final service = _FauxCompteService(
        erreurEcriture: StateError('réseau'),
      );

      await _monter(tester, service);
      await tester.enterText(
        find.byType(TextField),
        'mamie@exemple.fr',
      );
      await tester.tap(
        find.text('Enregistrer l’adresse de secours'),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Vérifiez votre connexion'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Une lecture qui échoue laisse le champ utilisable',
      (tester) async {
        await _monter(
          tester,
          _FauxCompteService(erreurLecture: StateError('réseau')),
        );

        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });

  group('L’export RGPD reste complet', () {
    final maintenant = DateTime.utc(2026, 8, 23, 12);

    test('L’adresse de secours ressort dans le fichier de données',
        () async {
      // Sans cela, l'export cesserait d'être complet le jour où cette
      // colonne a été ajoutée.
      final donnees = await collecterExport(
        FakeSourceExport(
          ligneCompteParent: {
            'id': 'parent-1',
            'email': 'parent@exemple.fr',
            'email_secours': 'mamie@exemple.fr',
          },
        ),
        maintenant,
      );

      final texte = encoderExportJson(donnees);

      expect(texte, contains('mamie@exemple.fr'));
      expect(texte, contains('email_secours'));
    });

    test('Et dans le document lisible', () async {
      final donnees = await collecterExport(
        FakeSourceExport(
          ligneCompteParent: {
            'id': 'parent-1',
            'email_secours': 'mamie@exemple.fr',
          },
        ),
        maintenant,
      );

      final tout = pagesExport(donnees)
          .expand((page) => page)
          .map((bloc) => bloc.texte)
          .join('\n');

      expect(tout, contains('Votre compte'));
      expect(tout, contains('mamie@exemple.fr'));
    });

    test('Un compte sans ligne enregistrée ne fait pas échouer l’export',
        () async {
      final donnees = await collecterExport(
        FakeSourceExport(),
        maintenant,
      );

      expect(donnees.compte.detailsCompte, isNull);
      expect(
        encoderExportJson(donnees),
        contains('"details": null'),
      );
    });
  });
}
