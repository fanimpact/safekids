/// Identifiants de connexion au projet Supabase. La clé publique
/// ("publishable"/anon) est conçue pour être embarquée dans le client
/// (protection réelle assurée côté Supabase par les règles RLS, pas
/// par le secret de cette clé).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url =
      'https://xcugfdjaifdibwowlrpi.supabase.co';

  static const String publishableKey =
      'sb_publishable_3j5-ynSda2sUBJD6my4KEQ_-_gICd11';

  /// Page web qui termine les parcours ouverts par email (confirmation
  /// de compte, mot de passe oublié). Doit être ajoutée tel quel dans
  /// Supabase -> Authentication -> URL Configuration -> Redirect URLs.
  ///
  /// Remplace `kidsrelay://auth-callback` (22/08/2026). Ce schéma
  /// applicatif n'était compris que par un appareil où l'app est
  /// installée : un parent relevant ses mails sur un ordinateur, ou
  /// sur un téléphone sans l'app, ne pouvait ni confirmer son compte
  /// ni réinitialiser son mot de passe — le navigateur répondait
  /// seulement que l'adresse n'était pas valide.
  ///
  /// La page est un fichier statique hébergé chez OVH (serveurs en
  /// France), source dans `web_auth/public/`. Elle n'est pas servie
  /// par une Edge Function : elle n'a besoin d'aucun traitement
  /// serveur, et l'héberger sous le domaine du projet évite qu'un
  /// parent reçoive un lien vers une adresse `*.supabase.co`, qui a
  /// tout l'air d'un hameçonnage.
  ///
  /// Les deux modèles d'email pointent directement sur cette page avec
  /// `{{ .TokenHash }}` DANS LE FRAGMENT, et non via `redirect_to` :
  /// `supabase_flutter` utilise PKCE par défaut, dont l'échange exige
  /// un `code_verifier` propre à l'appareil qui a fait la demande —
  /// une redirection classique échouerait donc précisément dans le cas
  /// qu'on veut couvrir, l'ouverture depuis un autre appareil. Le
  /// fragment garantit en prime que le jeton n'atteint jamais un
  /// serveur, donc aucun journal.
  static const String authRedirectUrl =
      'https://auth.kidsrelay.fr/ouvrir-lien-email/';
}
