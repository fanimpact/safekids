import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifie l'appareil auprès de Supabase sans écran de connexion :
/// un compte anonyme est créé au premier lancement et sa session est
/// ensuite conservée automatiquement par supabase_flutter, donc les
/// lancements suivants retrouvent le même `parent_id`.
Future<void> ensureSignedIn() async {
  final client = Supabase.instance.client;

  if (client.auth.currentSession != null) {
    return;
  }

  await client.auth.signInAnonymously();
}
