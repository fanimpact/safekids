import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enfant_etablissement_data.dart';

/// Côté parent : générer un lien de rattachement vers un établissement,
/// pour une durée que le parent choisit toujours lui-même (jamais de
/// durée par défaut implicite), et garder le contrôle total dessus —
/// voir tous les rattachements d'un enfant, les révoquer à tout moment.
class EstablishmentAttachmentService {
  EstablishmentAttachmentService._();

  static final EstablishmentAttachmentService instance =
      EstablishmentAttachmentService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Crée un rattachement en attente pour [childId], valable jusqu'à
  /// [dateExpiration] (obligatoire, choisie par l'appelant). Renvoie le
  /// code à transmettre à l'établissement.
  Future<String> generateAttachmentToken({
    required String childId,
    required DateTime dateExpiration,
  }) async {
    final response = await _client
        .from('enfants_etablissements')
        .insert({
          'enfant_id': childId,
          'date_expiration':
              dateExpiration.toUtc().toIso8601String(),
        })
        .select('token')
        .single();

    return response['token'] as String;
  }

  Future<List<EnfantEtablissementData>> attachmentsForChild(
    String childId,
  ) async {
    final rows = await _client
        .from('enfants_etablissements')
        .select('*, etablissements(nom)')
        .eq('enfant_id', childId)
        .order('date_creation', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => EnfantEtablissementData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> revokeAttachment(String attachmentId) async {
    await _client
        .from('enfants_etablissements')
        .update({
          'statut': 'revoque',
          'revoque_le': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', attachmentId);
  }
}
