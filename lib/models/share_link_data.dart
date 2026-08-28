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

  /// Ce partage EST un accès secours, dérivé d'un autre.
  final bool declencheEnSecours;

  /// Le partage dont celui-ci descend. Rend l'arbre lisible.
  final String? partageOrigineId;

  /// Le rattachement dont celui-ci descend, quand l'acces secours a
  /// ete ouvert depuis l'application par un professionnel plutot que
  /// depuis un lien. Exclusif de [partageOrigineId].
  final String? rattachementOrigineId;

  /// Jusqu'a quand ce code peut etre scanne pour la PREMIERE fois.
  ///
  /// Nulle pour un lien ordinaire. Sans rapport avec
  /// [dateExpiration], qui porte la duree de l'acces une fois
  /// accorde : les deux durees ne se melangent jamais, parce
  /// qu'elles ne sont pas dans la meme colonne.
  final DateTime? utilisableJusquA;

  /// La fonction declaree de la personne qui a declenche, figee a cet
  /// instant : « ATSEM », « Direction ».
  ///
  /// Jamais son nom. Le parent doit comprendre ce qui s'est passe, pas
  /// surveiller nominativement le personnel d'une ecole (28/08/2026).
  /// Nulle depuis un lien de partage, ou l'ouvreur est anonyme.
  final String? declencheParFonction;

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
    this.declencheEnSecours = false,
    this.partageOrigineId,
    this.rattachementOrigineId,
    this.utilisableJusquA,
    this.declencheParFonction,
  });

  /// Ce partage se remet en présentiel, par un code affiché à l'écran.
  bool get estCodeAScanner => utilisableJusquA != null;

  /// Personne ne l'a encore ouvert.
  ///
  /// La consultation et la prise de place vont ensemble : le verrou
  /// occupe une place à la première ouverture réussie, et c'est la
  /// même qui date la consultation.
  bool get jamaisScanne => dateDerniereConsultation == null;

  /// Le code est affiché et attend son scan.
  bool get codeEnAttente {
    final fin = utilisableJusquA;

    return fin != null && jamaisScanne && fin.isAfter(DateTime.now());
  }

  /// Les cinq minutes sont passées et personne n'a scanné.
  ///
  /// Ce n'est pas un accès : personne ne l'a jamais eu. La ligne
  /// bascule donc dans les partages terminés — elle n'est pas effacée,
  /// conformément à la règle du 27/08/2026, mais elle ne se fait pas
  /// passer pour un accès en cours.
  bool get codeNonScanne {
    final fin = utilisableJusquA;

    return fin != null && jamaisScanne && !fin.isAfter(DateTime.now());
  }

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
  bool get estActif => !estRevoque && !estExpire && !codeNonScanne;

  factory ShareLinkData.fromRow(Map<String, dynamic> row) {
    final dateDerniereConsultation =
        row['date_derniere_consultation'] as String?;
    final dateExpiration = row['date_expiration'] as String?;
    final revoqueLe = row['revoque_le'] as String?;
    final utilisableJusquA = row['utilisable_jusqu_a'] as String?;

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
      declencheEnSecours:
          row['declenche_en_secours'] as bool? ?? false,
      partageOrigineId: row['partage_origine_id'] as String?,
      rattachementOrigineId:
          row['rattachement_origine_id'] as String?,
      utilisableJusquA: utilisableJusquA == null
          ? null
          : DateTime.parse(utilisableJusquA),
      declencheParFonction:
          row['declenche_par_fonction'] as String?,
      revoqueLe:
          revoqueLe == null ? null : DateTime.parse(revoqueLe),
    );
  }
}
