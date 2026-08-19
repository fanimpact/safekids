import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enfant_confiance_data.dart';

/// Côté parent : inviter, changer le niveau d'accès, révoquer une
/// personne de confiance (co-parent, tuteur) sur la fiche d'un enfant
/// — corrections de l'inventaire du 19/08/2026, point 9. Toutes les
/// écritures passent par des fonctions RPC (jamais d'écriture directe
/// sur `enfants_confiance`), pour qu'une personne de confiance ne
/// puisse jamais modifier son propre accès.
class EnfantConfianceService {
  EnfantConfianceService._();

  static final EnfantConfianceService instance =
      EnfantConfianceService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Active toute invitation "personne de confiance" en attente pour
  /// l'utilisateur connecté — à appeler juste après chaque connexion
  /// parent, avant de charger la liste des enfants.
  Future<void> activatePendingInvitations() async {
    await _client.rpc('rpc_activer_confiances_en_attente');
  }

  Future<List<EnfantConfianceData>> trustedPeopleForChild(
    String childId,
  ) async {
    final rows = await _client
        .from('enfants_confiance')
        .select()
        .eq('enfant_id', childId)
        .order('invite_le', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (row) => EnfantConfianceData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> invite({
    required String childId,
    required String email,
    required NiveauAccesConfiance niveauAcces,
  }) async {
    await _client.rpc(
      'rpc_inviter_personne_confiance',
      params: {
        'p_enfant_id': childId,
        'p_email': email,
        'p_niveau_acces': niveauAccesToValue(niveauAcces),
      },
    );
  }

  Future<void> changeAccessLevel({
    required String confianceId,
    required NiveauAccesConfiance niveauAcces,
  }) async {
    await _client.rpc(
      'rpc_changer_niveau_confiance',
      params: {
        'p_confiance_id': confianceId,
        'p_nouveau_niveau': niveauAccesToValue(niveauAcces),
      },
    );
  }

  Future<void> revoke(String confianceId) async {
    await _client.rpc(
      'rpc_revoquer_confiance',
      params: {'p_confiance_id': confianceId},
    );
  }
}
