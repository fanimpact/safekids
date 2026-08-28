import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/secours/code_qr.dart';
import 'package:kidsrelay/secours/service_acces_secours.dart';
import 'package:qr/qr.dart';

// Le QR de l'accès secours, côté application (28/08/2026).
//
// Ce que ces tests protègent : le code se calcule sur l'appareil, il
// mène à la fiche secours et à rien d'autre, et l'adresse en clair
// reste sous lui.

String _codeSansCommentaires(String chemin) {
  return File(chemin)
      .readAsStringSync()
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('//'))
      .join('\n');
}

void main() {
  group('Le code lui-même', () {
    test('Le niveau de correction est M', () {
      // Pour notre adresse de 82 caractères, M donne la même grille
      // que L tout en tolérant deux fois plus de reflets. Le changer
      // densifie le code sans rien apporter à qui le scanne.
      expect(niveauCorrectionQr, QrErrorCorrectLevel.M);
    });

    test('La zone calme fait quatre modules', () {
      // La norme en demande quatre. En dessous, certains lecteurs
      // refusent de voir le code.
      expect(margeQr, 4);
    });

    test('L’adresse d’un accès secours tient en 37 × 37', () {
      // Mesuré, pas estimé : c'est ce qui justifie le niveau M.
      final adresse = adresseAccesSecours('a' * 48);

      expect(adresse.length, 82);

      final image = QrImage(
        QrCode.fromData(
          data: adresse,
          errorCorrectLevel: niveauCorrectionQr,
        ),
      );

      expect(image.moduleCount, 37);
    });

    test('Le code encode l’adresse, pas le jeton nu', () {
      // Un jeton seul ne mènerait nulle part : le lecteur du soignant
      // ouvre une adresse, il ne connaît pas notre schéma.
      final adresse = adresseAccesSecours('jeton-1');

      expect(adresse, startsWith('https://fiche.kidsrelay.fr/#jeton='));
    });
  });

  group('Le widget', () {
    testWidgets('Il se dessine sans réseau', (tester) async {
      // Aucune requête possible dans un test de widget : s'il
      // s'affiche ici, il s'affichera dans un couloir sans couverture.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeQr(donnees: adresseAccesSecours('jeton-1')),
          ),
        ),
      );

      expect(find.byType(CodeQr), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Le fond reste blanc, quel que soit le thème',
        (tester) async {
      // Un lecteur cherche des modules sombres sur fond clair.
      // L'inverse ne se scanne pas.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CodeQr(donnees: adresseAccesSecours('jeton-1')),
          ),
        ),
      );

      final conteneur = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CodeQr),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = conteneur.decoration! as BoxDecoration;

      expect(decoration.color, Colors.white);
    });

    testWidgets('Une donnée impossible n’affiche pas un carré faux',
        (tester) async {
      // Un QR ne tient pas au-delà d'environ 2 950 octets en niveau M.
      // Mieux vaut ne rien montrer que montrer un code illisible :
      // l'adresse en clair reste dessous.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CodeQr(donnees: 'x' * 5000)),
        ),
      );

      expect(tester.takeException(), isNull);

      // Rien de dessiné : le widget occupe une place nulle. On ne
      // cherche pas `CustomPaint`, que le Scaffold fournit lui-même.
      expect(tester.getSize(find.byType(CodeQr)), Size.zero);
    });

    testWidgets('Il s’annonce aux lecteurs d’écran', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeQr(donnees: adresseAccesSecours('jeton-1')),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Code à scanner pour ouvrir la fiche secours',
        ),
        findsOneWidget,
      );
    });
  });

  group('Sa place dans l’écran', () {
    final ecran =
        _codeSansCommentaires('lib/secours/declenchement_acces_secours.dart');

    test('Le code est au-dessus de l’adresse en clair', () {
      expect(
        ecran.indexOf('CodeQr('),
        lessThan(ecran.indexOf('SelectableText(')),
      );
    });

    test('L’adresse en clair n’a pas disparu', () {
      // Décision maintenue : tout le monde ne sait pas scanner, et
      // c'est le repli quand le QR ne prend pas.
      expect(ecran, contains('SelectableText('));
      expect(ecran, contains('Copier'));
      expect(ecran, contains('Transmettre'));
    });

    test('Le même écran sert au déclenchement et au réaffichage', () {
      // Quelqu'un dont le téléphone se verrouille doit retrouver son
      // code sans rien rouvrir d'autre.
      expect(ecran, contains('Revoir l’accès secours'));
      expect(ecran, contains('EcranAccesSecoursOuvert('));
    });
  });

  group('Ce que la page publique fait du même code', () {
    final page = _codeSansCommentaires(
      'supabase/functions/_logique/page_partage.mts',
    );

    test('Elle utilise le même niveau de correction', () {
      expect(page, contains("qrcode(0, 'M')"));
    });

    test('Elle ne charge rien depuis l’extérieur', () {
      // La bibliothèque est inlinée par le générateur. Aucun CDN,
      // aucune police distante, aucun traceur.
      expect(page, isNot(contains('<script src=')));
      expect(page, contains(r'${bibliothequeQr}'));
    });

    test('Le générateur inline bien la bibliothèque', () {
      // Sans cette ligne, la page serait servie sans QR et personne ne
      // s'en apercevrait avant le déploiement.
      final generateur = _codeSansCommentaires('web_partage/generer.mjs');

      expect(generateur, contains('bibliothequeQr'));
      expect(generateur, contains("'qrcode.js'"));
    });

    test('La bibliothèque est présente dans le dépôt', () {
      final fichier = File('web_partage/vendor/qrcode.js');

      expect(fichier.existsSync(), isTrue);
      expect(
        fichier.readAsStringSync(),
        contains('Licensed under the MIT license'),
      );
    });
  });
}
