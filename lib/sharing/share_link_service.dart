import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/share_link_data.dart';
import '../usage/compteur_usage.dart';

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

  /// Révoque par marquage, jamais par suppression (27/08/2026).
  ///
  /// Le `delete` d'avant coupait bien l'accès, mais il emportait avec
  /// lui l'historique de ce que le parent avait partagé et la preuve
  /// que la révocation avait eu lieu. Le lien cesse de fonctionner
  /// aussi immédiatement : c'est le serveur qui refuse, en voyant
  /// `revoque_le` renseigné.
  Future<void> revokeLink(String id) async {
    await _client
        .from('partages')
        .update({'revoque_le': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  /// Crée un lien de partage et renvoie son adresse complète.
  ///
  /// L'insertion était faite depuis l'écran `CreateShareLinkPage`
  /// (23/08/2026) : c'était le seul écran de l'app à écrire en base.
  /// [contenuFige] est la "photo" des recommandations au moment du
  /// partage, quand la fiche partagée est celle d'une activité.
  Future<String> createLink({
    required String childId,
    required String typeFiche,
    required String destinataire,
    /// Nulle si et seulement si [permanent]. La base impose « soit une
    /// date, soit permanent, jamais les deux ni aucun ».
    required DateTime? dateExpiration,
    Map<String, dynamic>? contenuFige,
    String? activiteId,
    String? nomDestinataire,
    bool permanent = false,
  }) async {
    compteurUsage.marquer(FonctionnaliteUsage.lienPartageCree);

    final response = await _client
        .from('partages')
        .insert({
          'enfant_id': childId,
          'type_fiche': typeFiche,
          'date_expiration':
              dateExpiration?.toUtc().toIso8601String(),
          'permanent': permanent,
          'destinataire': destinataire,
          // Distinct de `destinataire`, qui porte le choix particulier /
          // structure d'accueil. Vide plutot que chaine vide : le
          // parent n'est pas oblige de nommer qui que ce soit.
          'nom_destinataire': nomDestinataire,
          'contenu_fige': contenuFige,
          'activite_id': activiteId,
        })
        .select('token')
        .single();

    final token = response['token'] as String;

    return '${SupabaseConfig.url}/functions/v1/voir-partage'
        '?token=$token';
  }
}
