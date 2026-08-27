import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/share_link_data.dart';
import '../models/tentative_partage_data.dart';
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

  /// Change l'échéance d'un partage en cours, dans les deux sens :
  /// prolonger, ou raccourcir.
  ///
  /// Existe depuis le 27/08/2026. L'écran de création disait jusque-là
  /// « Il ne peut pas être prolongé : il faudra en créer un nouveau » —
  /// ce qui obligeait le parent à révoquer et à retransmettre un
  /// nouveau lien pour gagner un jour.
  ///
  /// [dateExpiration] et [permanent] vont toujours ensemble : la base
  /// impose « soit une date, soit permanent, jamais les deux ni
  /// aucun ». Passer une date rend le lien non permanent, et
  /// inversement.
  Future<void> updateExpiration({
    required String id,
    required DateTime? dateExpiration,
    bool permanent = false,
  }) async {
    await _client.from('partages').update({
      'date_expiration':
          permanent ? null : dateExpiration?.toUtc().toIso8601String(),
      'permanent': permanent,
    }).eq('id', id);
  }

  /// Les ouvertures refusées ou tolérées sur les liens d'un enfant.
  ///
  /// Lecture seule, garantie par le RLS : le parent voit celles qui
  /// concernent ses enfants, personne n'écrit depuis un compte — seule
  /// la clé de service le fait, hors RLS, puisque celui qui tente
  /// d'ouvrir n'est pas authentifié.
  Future<List<TentativePartageData>> tentativesForChild(
    String childId,
  ) async {
    final rows = await _client
        .from('tentatives_partage_refusees')
        .select('*, partages!inner(enfant_id)')
        .eq('partages.enfant_id', childId)
        .order('tentee_le', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => TentativePartageData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Rend le lien réouvrable depuis n'importe quel appareil, une fois.
  ///
  /// C'est l'amortisseur du verrouillage. Sans lui, un destinataire
  /// légitime qui a ouvert le lien depuis le navigateur intégré de sa
  /// messagerie, puis l'a rouvert dans son navigateur habituel plus de
  /// quinze minutes après, resterait dehors sans recours — et le
  /// parent n'aurait d'autre choix que de révoquer et de tout
  /// retransmettre.
  ///
  /// Le prochain appareil qui ouvre le lien reprend le verrou.
  Future<void> libererVerrou(String id) async {
    await _client.from('partages').update({
      'verrou_empreinte': null,
      'verrou_pose_le': null,
    }).eq('id', id);
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
