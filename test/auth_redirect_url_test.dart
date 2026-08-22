import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/config/supabase_config.dart';

/// Garde-fou sur l'adresse des liens envoyés par email (confirmation
/// de compte, mot de passe oublié).
///
/// Elle a longtemps valu `kidsrelay://auth-callback`, un schéma que
/// seul un appareil avec l'app installée sait ouvrir : un parent
/// relevant ses mails sur un ordinateur restait bloqué hors de son
/// compte, sans recours. Revenir à un schéma applicatif rouvrirait ce
/// trou en silence — d'où ce test.
void main() {
  test(
    'L’adresse des liens email est une vraie adresse web',
    () {
      expect(
        SupabaseConfig.authRedirectUrl.startsWith('https://'),
        isTrue,
        reason:
            'Un schéma applicatif (kidsrelay://) ne s’ouvre que là où '
            'l’app est installée. Le lien doit fonctionner depuis '
            'n’importe quel navigateur.',
      );
    },
  );

  test(
    'Elle pointe sur la page d’accès au compte, avec sa barre finale',
    () {
      expect(
        SupabaseConfig.authRedirectUrl,
        equals('https://auth.kidsrelay.fr/ouvrir-lien-email/'),
      );

      expect(
        SupabaseConfig.authRedirectUrl.endsWith('/'),
        isTrue,
        reason:
            'Sans la barre finale, le serveur répond par une '
            'redirection 301. Les navigateurs conservent le fragment '
            'au passage, mais le parcours critique n’a pas à en '
            'dépendre.',
      );
    },
  );

  test(
    'Elle est servie sous le domaine du projet, pas sous supabase.co',
    () {
      expect(
        SupabaseConfig.authRedirectUrl.contains('supabase.co'),
        isFalse,
        reason:
            'Un lien vers une adresse *.supabase.co dans un email '
            'signé KidsRelay a tout l’air d’un hameçonnage.',
      );

      expect(
        Uri.parse(SupabaseConfig.authRedirectUrl).host,
        equals('auth.kidsrelay.fr'),
      );
    },
  );
}
