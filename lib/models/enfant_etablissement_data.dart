enum RattachementStatut { enAttente, actif, revoque }

RattachementStatut _statutFromRow(String value) {
  switch (value) {
    case 'actif':
      return RattachementStatut.actif;
    case 'revoque':
      return RattachementStatut.revoque;
    case 'en_attente':
    default:
      return RattachementStatut.enAttente;
  }
}

/// Un rattachement d'enfant à un établissement, vu côté parent : le
/// lien qu'il a généré, avec sa durée choisie et son état actuel.
/// `etablissementNom` est `null` tant que personne n'a encore "réclamé"
/// le lien (statut `enAttente`).
class EnfantEtablissementData {
  final String id;
  final String token;
  final String enfantId;
  final String? etablissementId;
  final String? etablissementNom;
  final RattachementStatut statut;
  final DateTime dateCreation;
  final DateTime dateExpiration;

  const EnfantEtablissementData({
    required this.id,
    required this.token,
    required this.enfantId,
    required this.etablissementId,
    required this.etablissementNom,
    required this.statut,
    required this.dateCreation,
    required this.dateExpiration,
  });

  bool get estExpire =>
      statut != RattachementStatut.revoque &&
      dateExpiration.isBefore(DateTime.now());

  factory EnfantEtablissementData.fromRow(
    Map<String, dynamic> row,
  ) {
    final etablissement =
        row['etablissements'] as Map<String, dynamic>?;

    return EnfantEtablissementData(
      id: row['id'] as String,
      token: row['token'] as String,
      enfantId: row['enfant_id'] as String,
      etablissementId: row['etablissement_id'] as String?,
      etablissementNom: etablissement?['nom'] as String?,
      statut: _statutFromRow(row['statut'] as String),
      dateCreation: DateTime.parse(
        row['date_creation'] as String,
      ),
      dateExpiration: DateTime.parse(
        row['date_expiration'] as String,
      ),
    );
  }
}
