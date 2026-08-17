import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safekids/auth/device_identity.dart';

/// Vérifie le comportement attendu du jeton d'appareil utilisé pour la
/// vérification par email sur nouvel appareil (voir espace
/// professionnel, phase 1) : un jeton unique généré une seule fois,
/// stable tant que l'app n'est pas réinstallée, jamais transmis en
/// clair (seule son empreinte SHA-256 doit être exposée).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DeviceIdentity.resetForTesting();
  });

  test(
    'Le hash du jeton reste identique à deux appels successifs '
    '(même appareil, pas de réinstallation)',
    () async {
      final firstHash = await DeviceIdentity.tokenHash();
      final secondHash = await DeviceIdentity.tokenHash();

      expect(firstHash, equals(secondHash));
    },
  );

  test(
    'Le hash est bien une empreinte SHA-256 hexadécimale (64 caractères), '
    'jamais le jeton en clair',
    () async {
      final hash = await DeviceIdentity.tokenHash();

      expect(hash.length, equals(64));
      expect(
        RegExp(r'^[0-9a-f]{64}$').hasMatch(hash),
        isTrue,
        reason:
            'Le hash doit être une chaîne hexadécimale, pas le jeton brut.',
      );
    },
  );

  test(
    'Deux appareils différents (aucun jeton stocké au départ) '
    'obtiennent des jetons différents, pas une valeur fixe',
    () async {
      final firstHash = await DeviceIdentity.tokenHash();

      // Simule un second appareil : préférences vides et cache
      // mémoire réinitialisé, comme au tout premier lancement.
      SharedPreferences.setMockInitialValues({});
      DeviceIdentity.resetForTesting();

      final secondHash = await DeviceIdentity.tokenHash();

      expect(firstHash, isNot(equals(secondHash)));
    },
  );
}
