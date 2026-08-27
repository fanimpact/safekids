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

/// Un lien de partage, vu côté parent.
///
/// **La révocation ne supprime plus la ligne** (27/08/2026). Elle pose
/// `revoqueLe` : le parent garde l'historique de ce qu'il a partagé, et
/// la preuve que la révocation a eu lieu. L'accès, lui, est coupé aussi
/// immédiatement qu'avant — c'est le serveur qui refuse.
///
/// **Un lien permanent n'a pas de date d'expiration**, et c'est pour
/// cela que [dateExpiration] est nulle : plutôt qu'une date lointaine
/// posée en douce, la base impose « soit une date, soit permanent,
/// jamais les deux ni aucun ».
class ShareLinkData {
  final String id;
  final String token;
  final String enfantId;
  final ShareFicheType ficheType;
  final ShareDestinataire destinataire;
  final DateTime dateCreation;

  /// Nulle si et seulement si [permanent].
  final DateTime? dateExpiration;

  final DateTime? dateDerniereConsultation;

  /// Saisi librement par le parent : « Aurélie, animatrice piscine ».
  /// Sans rapport avec [destinataire], qui porte le choix
  /// particulier / structure d'accueil.
  final String? nomDestinataire;

  final bool permanent;
  final DateTime? revoqueLe;

  /// Combien d'appareils peuvent consulter la fiche : 1, 2 ou 5,
  /// choisi par le parent à la création. Le choix s'applique partout,
  /// QR compris.
  final int appareilsMax;

  const ShareLinkData({
    required this.id,
    required this.token,
    required this.enfantId,
    required this.ficheType,
    required this.destinataire,
    required this.dateCreation,
    required this.dateExpiration,
    required this.dateDerniereConsultation,
    this.nomDestinataire,
    this.permanent = false,
    this.revoqueLe,
    this.appareilsMax = 1,
  });

  bool get estRevoque => revoqueLe != null;

  /// Un lien permanent n'expire jamais. Seule la révocation l'arrête.
  bool get estExpire {
    final expiration = dateExpiration;

    if (permanent || expiration == null) {
      return false;
    }

    return expiration.isBefore(DateTime.now());
  }

  /// Ce que le parent voit dans « Partages en cours ». Tout le reste
  /// va dans « Partages terminés » — jamais mêlé, pour qu'un coup
  /// d'œil suffise à savoir qui a accès aujourd'hui.
  bool get estActif => !estRevoque && !estExpire;

  factory ShareLinkData.fromRow(Map<String, dynamic> row) {
    final dateDerniereConsultation =
        row['date_derniere_consultation'] as String?;
    final dateExpiration = row['date_expiration'] as String?;
    final revoqueLe = row['revoque_le'] as String?;

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
      dateExpiration: dateExpiration == null
          ? null
          : DateTime.parse(dateExpiration),
      dateDerniereConsultation: dateDerniereConsultation == null
          ? null
          : DateTime.parse(dateDerniereConsultation),
      nomDestinataire: row['nom_destinataire'] as String?,
      permanent: row['permanent'] as bool? ?? false,
      appareilsMax: (row['appareils_max'] as num?)?.toInt() ?? 1,
      revoqueLe:
          revoqueLe == null ? null : DateTime.parse(revoqueLe),
    );
  }
}
