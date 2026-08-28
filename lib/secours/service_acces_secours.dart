import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/service_exception.dart';

/// L'adresse de la page publique qui affiche une fiche partagée.
///
/// Le jeton part dans le **fragment** (`#jeton=`) et jamais dans la
/// requête : un fragment n'est pas envoyé au serveur, n'apparaît dans
/// aucun journal d'accès, et ne suit pas la personne dans un
/// `Referer`. C'est la même règle que sur la page elle-même.
const String adressePageFiche = 'https://fiche.kidsrelay.fr';

String adresseAccesSecours(String token) =>
    '$adressePageFiche/#jeton=$token';

/// Un accès secours ouvert, tel que le professionnel doit le montrer.
class AccesSecoursOuvert {
  final String id;
  final String token;
  final DateTime expireLe;
  final int appareilsMax;

  /// La fonction figée au déclenchement — nulle si elle n'était pas
  /// renseignée, ou si l'accès vient d'un lien de partage.
  final String? fonction;

  /// Faux quand le déclenchement a **retrouvé** un accès déjà ouvert
  /// au lieu d'en créer un. Deux personnes peuvent appuyer en même
  /// temps ; le parent ne doit être prévenu qu'une fois.
  final bool creeMaintenant;

  const AccesSecoursOuvert({
    required this.id,
    required this.token,
    required this.expireLe,
    required this.appareilsMax,
    this.fonction,
    this.creeMaintenant = true,
  });

  String get adresse => adresseAccesSecours(token);
}

/// L'accès secours déclenché depuis l'application, par un professionnel
/// qui a l'enfant par rattachement.
///
/// **Pourquoi ce chemin existe.** L'accès secours ne se déclenchait
/// que depuis la page publique d'un lien de partage. Or dans une école
/// le cas normal est le rattachement : le professionnel passe par
/// l'application et ne voyait jamais le bouton — exactement le
/// scénario qui a motivé le mécanisme.
///
/// **Pourquoi aucune fonction serveur ici.** Le professionnel est
/// authentifié, contrairement à l'inconnu qui ouvre un lien. Une
/// fonction `security definer` accordée à `authenticated` suffit :
/// elle vérifie l'appartenance, le rattachement et la préautorisation
/// du parent, et écrit la notification dans la même transaction.
class ServiceAccesSecours {
  ServiceAccesSecours._();

  static final ServiceAccesSecours instance = ServiceAccesSecours._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      throw ServiceException(error.message);
    }
  }

  AccesSecoursOuvert _lire(
    Map<String, dynamic> row, {
    required bool creeParDefaut,
  }) {
    return AccesSecoursOuvert(
      id: row['secours_id'] as String,
      token: row['secours_token'] as String,
      expireLe: DateTime.parse(
        row['secours_expire_le'] as String,
      ),
      appareilsMax:
          (row['secours_appareils_max'] as num?)?.toInt() ?? 10,
      fonction: row['secours_fonction'] as String?,
      creeMaintenant:
          row['secours_cree'] as bool? ?? creeParDefaut,
    );
  }

  /// L'accès secours déjà ouvert pour cet enfant, s'il y en a un.
  ///
  /// Lecture seule : elle n'en crée aucun et ne notifie personne. Sans
  /// elle, remontrer le QR obligerait à rappeler le déclenchement, qui
  /// préviendrait le parent une seconde fois pour rien.
  Future<AccesSecoursOuvert?> accesEnCours({
    required String enfantId,
    required String etablissementId,
  }) async {
    return _execute(() async {
      final reponse = await _client.rpc(
        'acces_secours_etablissement',
        params: {
          'p_enfant_id': enfantId,
          'p_etablissement_id': etablissementId,
        },
      );

      final lignes = (reponse as List?) ?? const [];

      if (lignes.isEmpty) {
        return null;
      }

      return _lire(
        Map<String, dynamic>.from(lignes.first as Map),
        creeParDefaut: false,
      );
    });
  }

  /// « L'enfant part avec les secours ».
  ///
  /// Si un accès est déjà ouvert et valide pour cet enfant, celui-ci
  /// est rendu au lieu d'en créer un second : une seule notification,
  /// une seule ligne dans la liste du parent.
  Future<AccesSecoursOuvert> declencher({
    required String enfantId,
    required String etablissementId,
  }) async {
    return _execute(() async {
      final reponse = await _client.rpc(
        'declencher_acces_secours_etablissement',
        params: {
          'p_enfant_id': enfantId,
          'p_etablissement_id': etablissementId,
        },
      );

      final lignes = (reponse as List?) ?? const [];

      if (lignes.isEmpty) {
        throw const ServiceException(
          'L’accès secours n’a pas pu être ouvert. '
          'Montrez la fiche depuis votre écran.',
        );
      }

      return _lire(
        Map<String, dynamic>.from(lignes.first as Map),
        creeParDefaut: true,
      );
    });
  }

  /// Ajoute des places quand les dix premières sont prises.
  ///
  /// Une intervention mobilise des gens successifs — pompiers, urgences,
  /// service. Un soignant refusé parce qu'un compteur est plein serait
  /// le pire mode d'échec possible : le geste reste ouvert, et le
  /// parent le voit dans sa liste.
  Future<int> etendreAppareils({
    required String partageId,
    required String etablissementId,
  }) async {
    return _execute(() async {
      final reponse = await _client.rpc(
        'etendre_appareils_acces_secours',
        params: {
          'p_partage_id': partageId,
          'p_etablissement_id': etablissementId,
        },
      );

      return (reponse as num).toInt();
    });
  }
}
