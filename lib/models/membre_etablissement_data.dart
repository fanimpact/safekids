enum RoleEtablissement { directeur, adjoint, membre }

RoleEtablissement _roleFromRow(String value) {
  switch (value) {
    case 'directeur':
      return RoleEtablissement.directeur;
    case 'adjoint':
      return RoleEtablissement.adjoint;
    case 'membre':
    default:
      return RoleEtablissement.membre;
  }
}

enum StatutMembre { invite, actif, revoque }

StatutMembre _statutFromRow(String value) {
  switch (value) {
    case 'actif':
      return StatutMembre.actif;
    case 'revoque':
      return StatutMembre.revoque;
    case 'invite':
    default:
      return StatutMembre.invite;
  }
}

/// Une personne du personnel d'un établissement — vu depuis l'écran
/// "Gérer l'équipe" (corrections de l'inventaire du 19/08/2026, point
/// 10). Directeur et adjoint ont exactement les mêmes pouvoirs de
/// gestion des comptes ; cette distinction de rôle ne restreint jamais
/// l'accès aux données des enfants (déjà réglé côté RLS depuis la
/// phase 4 de l'espace professionnel).
class MembreEtablissementData {
  final String id;
  final String etablissementId;
  final String email;
  final String? userId;
  final RoleEtablissement role;
  final StatutMembre statut;
  final DateTime inviteLe;
  final DateTime? accepteLe;
  final DateTime? revoqueLe;

  /// Ce que le parent lit sous une note écrite par cette personne.
  /// Nulle tant qu'elle ne l'a pas déclarée — jamais devinée par qui
  /// l'a invitée. Sans rapport avec [role], qui ne dit que qui gère
  /// l'équipe dans l'application.
  final String? fonction;

  const MembreEtablissementData({
    required this.id,
    required this.etablissementId,
    required this.email,
    required this.userId,
    required this.role,
    required this.statut,
    required this.inviteLe,
    required this.accepteLe,
    required this.revoqueLe,
    this.fonction,
  });

  factory MembreEtablissementData.fromRow(
    Map<String, dynamic> row,
  ) {
    final accepteLe = row['accepte_le'] as String?;
    final revoqueLe = row['revoque_le'] as String?;

    return MembreEtablissementData(
      id: row['id'] as String,
      etablissementId: row['etablissement_id'] as String,
      email: row['email'] as String,
      userId: row['user_id'] as String?,
      role: _roleFromRow(row['role'] as String),
      statut: _statutFromRow(row['statut'] as String),
      inviteLe: DateTime.parse(row['invite_le'] as String),
      accepteLe: accepteLe == null
          ? null
          : DateTime.parse(accepteLe),
      revoqueLe: revoqueLe == null
          ? null
          : DateTime.parse(revoqueLe),
      fonction: row['fonction'] as String?,
    );
  }
}
