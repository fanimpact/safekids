import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/etablissement_data.dart';

/// Regroupe les opérations côté espace professionnel : créer un
/// établissement, réclamer un rattachement envoyé par un parent, et
/// lister le trombinoscope. Les mutations sensibles passent par des
/// fonctions RPC côté serveur (`rpc_creer_etablissement`,
/// `rpc_reclamer_rattachement`) plutôt que par des écritures directes,
/// pour que l'app cliente ne puisse jamais réécrire un rôle, un statut,
/// ou l'enfant attaché à un rattachement.
class EstablishmentService {
  EstablishmentService._();

  static final EstablishmentService instance =
      EstablishmentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> createEstablishment({
    required String nom,
    String? type,
  }) async {
    final response = await _client.rpc(
      'rpc_creer_etablissement',
      params: {'p_nom': nom, 'p_type': type},
    );

    return response as String;
  }

  /// Établissements où l'utilisateur connecté est membre actif
  /// (directeur, adjoint ou membre — phase 2 ne crée que des
  /// directeurs, les autres rôles arrivent en phase 3).
  Future<List<EtablissementData>> myEstablishments() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return [];
    }

    final rows = await _client
        .from('membres_etablissement')
        .select('etablissements(id, nom, type_etablissement)')
        .eq('user_id', userId)
        .eq('statut', 'actif');

    return (rows as List<dynamic>)
        .map((row) => row['etablissements'])
        .whereType<Map<String, dynamic>>()
        .map(EtablissementData.fromRow)
        .toList();
  }

  /// Réclame un rattachement en attente : l'enfant rejoint le
  /// trombinoscope de [etablissementId]. Renvoie le prénom de l'enfant
  /// (uniquement) pour permettre une confirmation à l'écran.
  Future<String?> claimAttachment({
    required String token,
    required String etablissementId,
  }) async {
    final response = await _client.rpc(
      'rpc_reclamer_rattachement',
      params: {
        'p_token': token,
        'p_etablissement_id': etablissementId,
      },
    );

    return response as String?;
  }
}
