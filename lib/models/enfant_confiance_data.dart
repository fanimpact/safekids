enum NiveauAccesConfiance { lecture, lectureEcriture }

NiveauAccesConfiance _niveauFromRow(String value) {
  switch (value) {
    case 'lecture_ecriture':
      return NiveauAccesConfiance.lectureEcriture;
    case 'lecture':
    default:
      return NiveauAccesConfiance.lecture;
  }
}

String niveauAccesToValue(NiveauAccesConfiance niveau) {
  switch (niveau) {
    case NiveauAccesConfiance.lectureEcriture:
      return 'lecture_ecriture';
    case NiveauAccesConfiance.lecture:
      return 'lecture';
  }
}

enum StatutConfiance { invite, actif, revoque }

StatutConfiance _statutFromRow(String value) {
  switch (value) {
    case 'actif':
      return StatutConfiance.actif;
    case 'revoque':
      return StatutConfiance.revoque;
    case 'invite':
    default:
      return StatutConfiance.invite;
  }
}

/// Une personne de confiance (co-parent, tuteur) invitée sur la fiche
/// d'un enfant — corrections de l'inventaire du 19/08/2026, point 9.
/// Le niveau d'accès est choisi par le parent à l'invitation, visible
/// et modifiable après coup ; jamais plus de 2 personnes actives ou
/// invitées à la fois pour un même enfant (imposé côté serveur).
class EnfantConfianceData {
  final String id;
  final String enfantId;
  final String email;
  final String? userId;
  final NiveauAccesConfiance niveauAcces;
  final StatutConfiance statut;
  final DateTime inviteLe;
  final DateTime? accepteLe;
  final DateTime? revoqueLe;

  const EnfantConfianceData({
    required this.id,
    required this.enfantId,
    required this.email,
    required this.userId,
    required this.niveauAcces,
    required this.statut,
    required this.inviteLe,
    required this.accepteLe,
    required this.revoqueLe,
  });

  factory EnfantConfianceData.fromRow(
    Map<String, dynamic> row,
  ) {
    final accepteLe = row['accepte_le'] as String?;
    final revoqueLe = row['revoque_le'] as String?;

    return EnfantConfianceData(
      id: row['id'] as String,
      enfantId: row['enfant_id'] as String,
      email: row['email'] as String,
      userId: row['user_id'] as String?,
      niveauAcces: _niveauFromRow(
        row['niveau_acces'] as String,
      ),
      statut: _statutFromRow(row['statut'] as String),
      inviteLe: DateTime.parse(row['invite_le'] as String),
      accepteLe: accepteLe == null
          ? null
          : DateTime.parse(accepteLe),
      revoqueLe: revoqueLe == null
          ? null
          : DateTime.parse(revoqueLe),
    );
  }
}
