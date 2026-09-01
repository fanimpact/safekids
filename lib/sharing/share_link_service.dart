import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/demande_acces_data.dart';
import '../models/share_link_data.dart';
import '../services/service_exception.dart';
import '../models/tentative_partage_data.dart';
import '../usage/compteur_usage.dart';

/// Ce qu'un partage tout juste créé rend à l'écran qui l'a demandé.
///
/// L'identifiant en plus du jeton : un code à scanner doit pouvoir se
/// rafraîchir, et le rafraîchissement s'adresse à la ligne, pas au
/// jeton — qui change justement à chaque fois.
class PartageCree {
  final String id;
  final String token;

  const PartageCree({required this.id, required this.token});

  /// L'adresse de la page publique. Le jeton passe après le `#` : le
  /// fragment n'est pas transmis au serveur, donc il n'apparaît dans
  /// aucun journal d'accès de l'hébergeur.
  String get url =>
      '${SupabaseConfig.adressePagePartage}/#jeton=$token';
}

/// L'état d'un code à scanner, tel que le serveur le rend.
class CodePartage {
  final String token;

  /// Jusqu'à quand ce code peut être scanné pour la **première** fois.
  /// Sans rapport avec la durée de l'accès, choisie par le parent
  /// avant d'afficher le code.
  final DateTime utilisableJusquA;

  /// Quelqu'un a déjà scanné. Le code a servi : il ne se rafraîchit
  /// plus, et le parent doit le savoir plutôt que de continuer à
  /// tendre son téléphone.
  final bool dejaScanne;

  const CodePartage({
    required this.token,
    required this.utilisableJusquA,
    required this.dejaScanne,
  });

  String get url =>
      '${SupabaseConfig.adressePagePartage}/#jeton=$token';
}

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
  /// Les demandes d'accès déposées sur les partages d'un enfant.
  ///
  /// Le parent les lit — et lit la raison saisie — **uniquement
  /// ici**. Le mail qui l'a prévenu n'en dit rien : elle est écrite
  /// par une personne inconnue et pourrait contenir n'importe quoi.
  Future<List<DemandeAccesData>> demandesPourEnfant(
    String childId,
  ) async {
    final rows = await _client
        .from('demandes_acces_partage')
        .select('*, partages!inner(enfant_id)')
        .eq('partages.enfant_id', childId)
        .order('cree_le', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => DemandeAccesData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Autorise **un** appareil, et un seul.
  ///
  /// Le plafond du partage monte d'une unité : le cinquième appareil
  /// redemandera. Pas de « ne plus me demander » — l'application ne
  /// sait pas distinguer les appareils d'une personne de ceux de
  /// plusieurs, et cette option ouvrirait exactement la porte qu'on
  /// cherche à fermer.
  Future<int> autoriserAppareil(String demandeId) async {
    final reponse = await _client.rpc(
      'autoriser_appareil_partage',
      params: {'p_demande_id': demandeId},
    );

    return (reponse as num).toInt();
  }

  /// Libère la place la plus récemment prise, pour qu'un nouvel
  /// appareil puisse ouvrir le lien.
  ///
  /// **Cette méthode ne faisait rien jusqu'au 28/08/2026.** Elle
  /// remettait à zéro `verrou_empreinte` et `verrou_pose_le`, deux
  /// colonnes que plus personne ne lit depuis que la décision se
  /// prend sur `appareils_partage`. Le bouton affichait pourtant
  /// « Le prochain appareil qui ouvrira ce lien pourra le
  /// consulter » : une personne refusée n'avait aucune issue, ni
  /// par elle-même, ni par le parent.
  ///
  /// Une place, pas toutes : libérer tout évincerait des lecteurs
  /// légitimes que le parent n'a pas visés.
  Future<void> libererVerrou(String id) async {
    await _client.rpc(
      'liberer_place_partage',
      params: {'p_partage_id': id},
    );
  }

  /// Crée un lien de partage et renvoie son adresse complète.
  ///
  /// L'insertion était faite depuis l'écran `CreateShareLinkPage`
  /// (23/08/2026) : c'était le seul écran de l'app à écrire en base.
  /// [contenuFige] est la "photo" des recommandations au moment du
  /// partage, quand la fiche partagée est celle d'une activité.
  Future<PartageCree> createLink({
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
        .select('id, token')
        .single();

    // Le jeton passe apres le `#` : le fragment n'est pas transmis au
    // serveur, donc il n'apparait dans aucun journal d'acces de
    // l'hebergeur. Meme choix que pour auth.kidsrelay.fr.
    return PartageCree(
      id: response['id'] as String,
      token: response['token'] as String,
    );
  }

  /// Ouvre — ou rouvre — la fenêtre de cinq minutes d'un code à
  /// scanner, et rend le jeton à afficher.
  ///
  /// **Le jeton tourne à chaque appel**, tant que personne n'a
  /// scanné. Se contenter de repousser la fenêtre laisserait le même
  /// jeton, et une photo du code précédent redeviendrait valable —
  /// ce qui viderait la règle des cinq minutes de son sens.
  ///
  /// La durée vit en base, pas ici : l'écran compte à rebours sur la
  /// date rendue plutôt que d'avoir sa propre idée de cinq minutes.
  Future<CodePartage> rafraichirCode(String partageId) async {
    final reponse = await _client.rpc(
      'rafraichir_code_partage',
      params: {'p_partage_id': partageId},
    );

    final lignes = (reponse as List?) ?? const [];

    if (lignes.isEmpty) {
      throw const ServiceException(
        'Le code n’a pas pu être affiché. Réessayez.',
      );
    }

    final ligne = Map<String, dynamic>.from(lignes.first as Map);

    return CodePartage(
      token: ligne['code_token'] as String,
      utilisableJusquA: DateTime.parse(
        ligne['code_utilisable_jusqu_a'] as String,
      ),
      dejaScanne: ligne['code_deja_scanne'] as bool? ?? false,
    );
  }
}
