import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/verrou/regle_verrou.dart';

// Le verrou de l'appareil (28/08/2026).
//
// Le verrou est celui du téléphone — empreinte, visage, ou code — et
// jamais le mot de passe du compte : c'est exactement celui qu'un
// parent ne retrouve pas au moment où il en a besoin.

DateTime get _maintenant => DateTime(2026, 8, 28, 14, 0);

DateTime _ilYA(Duration duree) => _maintenant.subtract(duree);

void main() {
  group('Quand redemander le déverrouillage', () {
    test('Jamais ouverte : on demande', () {
      // Premier démarrage, ou stockage vidé : on ne sait pas, donc on
      // demande.
      expect(
        verrouRequis(
          derniereOuverture: null,
          maintenant: _maintenant,
        ),
        isTrue,
      );
    });

    test('Il y a une minute : on ne demande pas', () {
      // Pendant une urgence, on ouvre et referme l'application sans
      // arrêt — pour lire une posologie, pour la relire, pour montrer
      // un écran. Un verrou à chaque fois arrêterait le parent à
      // chaque geste, au pire moment.
      expect(
        verrouRequis(
          derniereOuverture: _ilYA(const Duration(minutes: 1)),
          maintenant: _maintenant,
        ),
        isFalse,
      );
    });

    test('À la quinzième minute pile : on ne demande pas encore', () {
      expect(
        verrouRequis(
          derniereOuverture: _ilYA(dureeGraceVerrou),
          maintenant: _maintenant,
        ),
        isFalse,
      );
    });

    test('Une seconde plus tard : on demande', () {
      expect(
        verrouRequis(
          derniereOuverture: _ilYA(
            dureeGraceVerrou + const Duration(seconds: 1),
          ),
          maintenant: _maintenant,
        ),
        isTrue,
      );
    });

    test('Le délai est de quinze minutes', () {
      expect(dureeGraceVerrou, const Duration(minutes: 15));
    });

    test('Une ouverture dans le futur fait redemander', () {
      // Horloge désaccordée : un écart ne doit pas ouvrir une fenêtre
      // sans fin. Même règle que pour la tolérance du verrou de
      // partage.
      expect(
        verrouRequis(
          derniereOuverture: _maintenant.add(
            const Duration(hours: 2),
          ),
          maintenant: _maintenant,
        ),
        isTrue,
      );
    });

    test('Le délai est réglable', () {
      expect(
        verrouRequis(
          derniereOuverture: _ilYA(const Duration(minutes: 3)),
          maintenant: _maintenant,
          grace: const Duration(minutes: 2),
        ),
        isTrue,
      );
    });
  });

  group('Le repli n’est jamais le mot de passe du compte', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final service = source('lib/verrou/verrou_appareil.dart');
    final garde = source('lib/verrou/garde_verrou.dart');

    test('Le code de l’appareil est autorisé en repli', () {
      // `biometricOnly: false` est ce qui laisse le système proposer
      // le code du téléphone quand la biométrie échoue. Le passer à
      // `true` enfermerait dehors un parent aux doigts mouillés.
      expect(service, contains('biometricOnly: false'));
    });

    test('Un appareil sans verrou ouvre sans rien demander', () {
      // Exiger un mot de passe sur un téléphone que n'importe qui peut
      // allumer ne protégerait rien : cela gênerait le parent sans
      // arrêter personne.
      expect(service, contains('aucunVerrouSurLAppareil'));
      expect(service, contains('isDeviceSupported()'));
    });

    test('Aucun écran du verrou ne demande le mot de passe', () {
      for (final code in [service, garde]) {
        expect(code, isNot(contains('signInWithPassword')));
        expect(code, isNot(contains('Mot de passe')));
      }
    });

    test('Personne ne reste enfermé : se déconnecter reste possible',
        () {
      expect(garde, contains('Se déconnecter'));
      expect(garde, contains('Réessayer'));
    });
  });

  group('Le verrou se pose aussi au retour d’arrière-plan', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final garde = source('lib/verrou/garde_verrou.dart');

    test('Le cycle de vie est observé', () {
      // Sans cela, un téléphone repris trois heures plus tard
      // s'ouvrirait sur la fiche de l'enfant sans rien demander.
      expect(garde, contains('WidgetsBindingObserver'));
      expect(garde, contains('AppLifecycleState.resumed'));
    });

    test('Le passage en arrière-plan ne repousse pas l’échéance', () {
      // Marquer une ouverture au moment où l'on quitte l'application
      // repousserait le délai à chaque coup d'œil, et le verrou ne
      // tomberait jamais.
      final debut = garde.indexOf('didChangeAppLifecycleState');
      final fin = garde.indexOf('Future<void> _verifier()');

      expect(
        garde.substring(debut, fin),
        isNot(contains('marquerOuverture')),
      );
    });
  });

  group('Le verrou est posé devant les espaces connectés', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/welcome_page.dart');

    test('Les trois destinations d’une session le traversent', () {
      expect(
        'GardeVerrou('.allMatches(ecran).length,
        3,
        reason:
            'accueil parent, accueil professionnel et choix d’espace',
      );
    });

    test('Le parcours d’entrée ne le traverse pas', () {
      // Il n'y a rien à protéger avant la connexion.
      final debut = ecran.indexOf('case DestinationDemarrage.concept:');

      expect(
        ecran.substring(debut),
        isNot(contains('GardeVerrou')),
      );
    });

    test('Le garde de suppression reste à l’intérieur', () {
      expect(
        ecran,
        contains('GardeVerrou(\n          enfant: GardeSuppression'),
      );
    });
  });
}
