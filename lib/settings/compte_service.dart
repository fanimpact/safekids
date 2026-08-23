import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_provider.dart';

/// Ce que l'application sait du compte du parent au-delà de son
/// authentification : adresse de secours, état d'une demande de
/// suppression.
///
/// Interface d'abord, implémentation Supabase ensuite — comme
/// `AuthProvider` et `SourceExport`. Les règles (validation d'une
/// adresse, décision d'afficher tel écran) vivent hors de cette classe
/// et se testent sans base.
abstract class CompteService {
  Future<String?> lireEmailSecours();

  /// `null` efface l'adresse enregistrée.
  Future<void> enregistrerEmailSecours(String? email);
}

class CompteServiceSupabase implements CompteService {
  const CompteServiceSupabase();

  SupabaseClient get _client => Supabase.instance.client;

  String get _compteId {
    final id = SupabaseAuthProvider.instance.currentUserId;

    if (id == null) {
      throw StateError('Aucun compte connecté.');
    }

    return id;
  }

  @override
  Future<String?> lireEmailSecours() async {
    final ligne = await _client
        .from('comptes_parents')
        .select('email_secours')
        .eq('id', _compteId)
        .maybeSingle();

    return ligne?['email_secours'] as String?;
  }

  @override
  Future<void> enregistrerEmailSecours(String? email) async {
    // La ligne peut ne pas exister : un compte créé avant l'espace
    // professionnel n'a pas forcément de ligne `comptes_parents`.
    await _client.from('comptes_parents').upsert({
      'id': _compteId,
      'email_secours': email,
    });
  }
}
