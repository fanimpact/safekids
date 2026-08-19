/// Les 3 valeurs autorisées par la contrainte SQL sur
/// `partages.type_fiche`. `recommandationsActivite` existe côté base de
/// données mais n'est pas encore proposé à la création (voir
/// `CreateShareLinkPage`) tant que le partage figé au moment du partage
/// n'est pas construit.
enum ShareFicheType {
  secours('secours', 'Informations pour les secours'),
  ceQuIlFautSavoir(
    'ce_qu_il_faut_savoir',
    'Ce qu’il faut savoir sur l’enfant',
  ),
  recommandationsActivite(
    'recommandations_activite',
    'Recommandations d’activité',
  );

  const ShareFicheType(this.value, this.label);

  final String value;
  final String label;

  static ShareFicheType fromValue(String value) {
    return ShareFicheType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ShareFicheType.secours,
    );
  }
}

/// Un lien de partage ponctuel (fiche secours ou "ce qu'il faut savoir"),
/// vu côté parent : pas de statut de révocation en base — supprimer la
/// ligne EST la révocation, elle coupe l'accès immédiatement.
class ShareLinkData {
  final String id;
  final String token;
  final String enfantId;
  final ShareFicheType ficheType;
  final DateTime dateCreation;
  final DateTime dateExpiration;
  final DateTime? dateDerniereConsultation;

  const ShareLinkData({
    required this.id,
    required this.token,
    required this.enfantId,
    required this.ficheType,
    required this.dateCreation,
    required this.dateExpiration,
    required this.dateDerniereConsultation,
  });

  bool get estExpire => dateExpiration.isBefore(DateTime.now());

  factory ShareLinkData.fromRow(Map<String, dynamic> row) {
    final dateDerniereConsultation =
        row['date_derniere_consultation'] as String?;

    return ShareLinkData(
      id: row['id'] as String,
      token: row['token'] as String,
      enfantId: row['enfant_id'] as String,
      ficheType: ShareFicheType.fromValue(
        row['type_fiche'] as String,
      ),
      dateCreation: DateTime.parse(
        row['date_creation'] as String,
      ),
      dateExpiration: DateTime.parse(
        row['date_expiration'] as String,
      ),
      dateDerniereConsultation: dateDerniereConsultation == null
          ? null
          : DateTime.parse(dateDerniereConsultation),
    );
  }
}
