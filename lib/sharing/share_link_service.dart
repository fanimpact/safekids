import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/share_link_data.dart';

/// Côté parent : lister et révoquer les liens de partage ponctuels
/// (`partages`) d'un enfant. Il n'existe pas de statut "révoqué" en
/// base pour cette table — supprimer la ligne coupe l'accès
/// immédiatement (le lien ne renvoie plus rien), c'est la révocation.
class ShareLinkService {
  ShareLinkService._();

  static final ShareLinkService instance = ShareLinkService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ShareLinkData>> linksForChild(String childId) async {
    final rows = await _client
        .from('partages')
        .select()
        .eq('enfant_id', childId)
        .order('date_creation', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => ShareLinkData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> revokeLink(String id) async {
    await _client.from('partages').delete().eq('id', id);
  }
}
