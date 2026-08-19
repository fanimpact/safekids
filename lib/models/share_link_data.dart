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

/// À qui un lien est destiné — choisi obligatoirement par le parent à
/// la création (corrections de l'inventaire du 19/08/2026) : la
/// mention accolée à chaque traitement sur la page publique du lien
/// n'est pas la même selon qui le reçoit (rappel du PAI pour une
/// structure d'accueil, des indications du parent pour un particulier).
enum ShareDestinataire {
  particulier('particulier', 'Un particulier (grand-parent, nounou, ami...)'),
  structureAccueil(
    'structure_accueil',
    'Une structure d’accueil (école, centre de loisirs, colonie...)',
  );

  const ShareDestinataire(this.value, this.label);

  final String value;
  final String label;

  static ShareDestinataire fromValue(String value) {
    return ShareDestinataire.values.firstWhere(
      (destinataire) => destinataire.value == value,
      orElse: () => ShareDestinataire.particulier,
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
  final ShareDestinataire destinataire;
  final DateTime dateCreation;
  final DateTime dateExpiration;
  final DateTime? dateDerniereConsultation;

  const ShareLinkData({
    required this.id,
    required this.token,
    required this.enfantId,
    required this.ficheType,
    required this.destinataire,
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
      destinataire: ShareDestinataire.fromValue(
        row['destinataire'] as String,
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
