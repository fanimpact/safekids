import 'auth_provider.dart';
import 'supabase_auth_provider.dart';

/// Identifie l'appareil auprès du fournisseur d'authentification sans
/// écran de connexion : un compte anonyme est créé au premier
/// lancement et sa session est ensuite conservée, donc les lancements
/// suivants retrouvent le même identifiant de parent.
///
/// La garde "ne rien faire si une session existe déjà" vit désormais
/// dans [AuthProvider.signInAnonymously] : ce fichier ne connaît plus
/// aucun SDK (23/08/2026).
Future<void> ensureSignedIn() {
  final AuthProvider auth = SupabaseAuthProvider.instance;

  return auth.signInAnonymously();
}
