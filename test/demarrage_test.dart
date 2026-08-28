import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/demarrage/destination_demarrage.dart';

// Où l'application s'ouvre au démarrage (28/08/2026).
//
// Le défaut corrigé : l'écran de connexion s'affichait à chaque
// démarrage, même quand la session était valide — rien dans
// l'interface ne consultait `hasSession`. Or le moment où un parent
// ouvre cette application en urgence est exactement celui où il ne
// retrouve pas son mot de passe.

void main() {
  group('Sans session exploitable, rien ne change', () {
    test('Aucune session : le parcours d’entrée', () {
      expect(
        destinationDemarrage(
          session: false,
          anonyme: false,
          enfants: 0,
          etablissements: 0,
        ),
        DestinationDemarrage.concept,
      );
    });

    test('Une session anonyme ne vaut pas une session', () {
      // `signInAnonymously` existe dans l'application, et une session
      // anonyme ne donne accès à aucun profil : l'ouvrir sur un
      // accueil montrerait une page vide.
      expect(
        destinationDemarrage(
          session: true,
          anonyme: true,
          enfants: 3,
          etablissements: 1,
        ),
        DestinationDemarrage.concept,
      );
    });
  });

  group('Avec une vraie session, on va droit au bon espace', () {
    test('Un parent avec des enfants', () {
      expect(
        destinationDemarrage(
          session: true,
          anonyme: false,
          enfants: 2,
          etablissements: 0,
        ),
        DestinationDemarrage.accueilParent,
      );
    });

    test('Un professionnel membre d’un établissement', () {
      expect(
        destinationDemarrage(
          session: true,
          anonyme: false,
          enfants: 0,
          etablissements: 1,
        ),
        DestinationDemarrage.accueilProfessionnel,
      );
    });

    test('Les deux à la fois ouvrent sur l’espace parent', () {
      // C'est celui qui porte les données de ses propres enfants, donc
      // celui qu'on ouvre en urgence. L'autre reste à un geste.
      expect(
        destinationDemarrage(
          session: true,
          anonyme: false,
          enfants: 1,
          etablissements: 1,
        ),
        DestinationDemarrage.accueilParent,
      );
    });

    test('Ni l’un ni l’autre : la personne choisit', () {
      // Un compte tout juste créé, ou un professionnel qui n'a pas
      // encore rejoint d'établissement.
      expect(
        destinationDemarrage(
          session: true,
          anonyme: false,
          enfants: 0,
          etablissements: 0,
        ),
        DestinationDemarrage.choixEspace,
      );
    });
  });

  group('L’écran de démarrage applique la règle', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/welcome_page.dart');

    test('Il consulte la session, ce que rien ne faisait avant', () {
      expect(ecran, contains('_auth.hasSession'));
      expect(ecran, contains('_auth.isAnonymous'));
      expect(ecran, contains('destinationDemarrage('));
    });

    test('Le garde de suppression reste sur l’accueil parent', () {
      // Un compte en cours de suppression ne doit pas atterrir sur ses
      // enfants.
      expect(ecran, contains('GardeSuppression(enfant: HomePage())'));
    });

    test('Les deux secondes ne s’imposent qu’à qui n’a pas de session',
        () {
      // Elles ne coûtent rien à quelqu'un qui découvre l'application ;
      // elles coûtent beaucoup à un parent devant les pompiers.
      final debut = ecran.indexOf('if (!session || anonyme)');
      final fin = ecran.indexOf('return destinationDemarrage(');

      expect(
        ecran.substring(debut, fin),
        contains('Duration(seconds: 2)'),
      );

      // Et nulle part ailleurs.
      expect(
        'Duration(seconds: 2)'.allMatches(ecran).length,
        1,
      );
    });

    test('Hors connexion, le cache local fait foi', () {
      // Un parent sans réseau doit quand même arriver sur ses enfants.
      final debut = ecran.indexOf('Future<int> _nombreEnfants()');
      final fin = ecran.indexOf('Future<int> _nombreEtablissements()');
      final methode = ecran.substring(debut, fin);

      expect(methode, contains('catch (_)'));
      expect(methode, contains('children.length'));
    });

    test('Une erreur de session n’empêche pas l’application d’ouvrir',
        () {
      // Fournisseur non initialisé : on se comporte comme sans
      // session, plutôt que de planter au premier écran.
      final debut = ecran.indexOf('Future<DestinationDemarrage>');
      final fin = ecran.indexOf('Future<int> _nombreEnfants()');

      expect(ecran.substring(debut, fin), contains('session = false'));
    });
  });
}
