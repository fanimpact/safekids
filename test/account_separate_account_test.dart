import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/auth/account_service.dart';

import 'support/fake_auth_provider.dart';

/// `createSeparateAccount` protège le scénario qui a réellement fait
/// perdre l'accès à Théo et Noé : créer un compte professionnel alors
/// qu'un compte parent est connecté.
///
/// Sans la déconnexion préalable, `attachAccountToCurrentSession`
/// écraserait l'email et le mot de passe du parent connecté — sa
/// session serait réutilisée, donc son `auth.uid()`, donc ses enfants.
///
/// La condition a été réécrite le 23/08/2026 lors de l'isolation de
/// l'authentification. Elle n'était couverte par aucun test.
///
/// **Ce que ces tests couvrent** : la décision de se déconnecter, et
/// l'ordre des opérations. La suite de `createAccount` (écriture dans
/// `comptes_parents`, enregistrement de l'appareil) touche la base et
/// échoue ici faute de Supabase initialisé — c'est attendu, et sans
/// importance : la protection se joue **avant**.
void main() {
  late FakeAuthProvider auth;

  setUp(() {
    auth = FakeAuthProvider.compteReel(email: 'parent@exemple.fr');
    AccountService.instance.useAuthProviderForTesting(auth);
  });

  tearDown(() {
    // Sans ça, le double fuiterait vers les autres tests : le service
    // est un singleton.
    AccountService.instance.useAuthProviderForTesting(null);
  });

  /// Lance la création et absorbe l'échec des appels à la base, qui
  /// arrivent après la partie qui nous intéresse.
  Future<void> tenterCreation(String email) async {
    try {
      await AccountService.instance.createSeparateAccount(
        email: email,
        password: 'motdepasse-solide',
      );
    } catch (_) {
      // Supabase n'est pas initialisé dans un test : l'écriture en
      // base échoue. La décision testée est déjà prise.
    }
  }

  test(
    'Un compte parent connecté est déconnecté avant la création',
    () async {
      await tenterCreation('professionnel@exemple.fr');

      expect(
        auth.operations.take(3).toList(),
        equals([
          'signOut',
          'signInAnonymously',
          'attachAccountToCurrentSession(professionnel@exemple.fr)',
        ]),
        reason:
            'L’ordre compte : se déconnecter, ouvrir une session '
            'anonyme neuve, PUIS y attacher le nouveau compte. Sans '
            'cette séquence, le compte professionnel reprendrait '
            'l’identité du parent — et ses enfants.',
      );
    },
  );

  test(
    'La déconnexion précède toujours le rattachement',
    () async {
      await tenterCreation('professionnel@exemple.fr');

      final indexSignOut = auth.operations.indexOf('signOut');
      final indexRattachement = auth.operations.indexWhere(
        (operation) =>
            operation.startsWith('attachAccountToCurrentSession'),
      );

      expect(indexSignOut, greaterThanOrEqualTo(0));
      expect(indexRattachement, greaterThan(indexSignOut));
    },
  );

  test(
    'Une session anonyme n’est pas déconnectée : elle est convertie',
    () async {
      auth = FakeAuthProvider.sessionAnonyme();
      AccountService.instance.useAuthProviderForTesting(auth);

      await tenterCreation('parent@exemple.fr');

      expect(
        auth.operations,
        isNot(contains('signOut')),
        reason:
            'C’est tout l’intérêt de la session anonyme : la convertir '
            'conserve auth.uid(), donc les enfants déjà enregistrés. '
            'La déconnecter les perdrait.',
      );

      expect(
        auth.operations.first,
        equals('attachAccountToCurrentSession(parent@exemple.fr)'),
      );
    },
  );

  test(
    'Sans aucune session, aucune déconnexion inutile',
    () async {
      auth = FakeAuthProvider.sansSession();
      AccountService.instance.useAuthProviderForTesting(auth);

      await tenterCreation('professionnel@exemple.fr');

      expect(auth.operations, isNot(contains('signOut')));
    },
  );

  test(
    'L’identité change bien entre un compte parent et le nouveau '
    'compte',
    () async {
      final identiteParent = auth.currentUserId;

      await tenterCreation('professionnel@exemple.fr');

      expect(
        auth.currentUserId,
        isNot(equals(identiteParent)),
        reason:
            'Si l’identité était conservée, les enfants du parent '
            'suivraient le compte professionnel.',
      );
      expect(
        auth.currentUserEmail,
        equals('professionnel@exemple.fr'),
      );
    },
  );

  test(
    'À l’inverse, convertir une session anonyme conserve l’identité',
    () async {
      auth = FakeAuthProvider.sessionAnonyme();
      AccountService.instance.useAuthProviderForTesting(auth);

      final identiteAvant = auth.currentUserId;

      await tenterCreation('parent@exemple.fr');

      expect(
        auth.currentUserId,
        equals(identiteAvant),
        reason:
            'Les deux comportements sont opposés et voulus : '
            'conserver l’identité pour un parent, la remplacer pour un '
            'compte séparé.',
      );
    },
  );
}
