enum TypeFicheConsultee {
  secours,
  ceQuIlFautSavoir,
  profilActivites,
  modeUrgence,
}

TypeFicheConsultee _typeFicheFromRow(String value) {
  switch (value) {
    case 'secours':
      return TypeFicheConsultee.secours;
    case 'ce_qu_il_faut_savoir':
      return TypeFicheConsultee.ceQuIlFautSavoir;
    case 'profil_activites':
      return TypeFicheConsultee.profilActivites;
    case 'mode_urgence':
    default:
      return TypeFicheConsultee.modeUrgence;
  }
}

String typeFicheConsulteeLabel(TypeFicheConsultee type) {
  switch (type) {
    case TypeFicheConsultee.secours:
      return 'Informations pour les secours';
    case TypeFicheConsultee.ceQuIlFautSavoir:
      return 'Ce qu’il faut savoir sur l’enfant';
    case TypeFicheConsultee.profilActivites:
      return 'Profil Activités';
    case TypeFicheConsultee.modeUrgence:
      return 'Mode Urgence';
  }
}

/// Une consultation de la fiche d'un enfant par un membre du personnel
/// d'un établissement — traçabilité RGPD, corrections de l'audit passe
/// 1 : le parent doit pouvoir voir qui (quel établissement) a consulté
/// la fiche de son enfant, et quand.
class JournalConsultationData {
  final String id;
  final String enfantId;
  final String? etablissementId;
  final String? etablissementNom;
  final TypeFicheConsultee typeFiche;
  final DateTime consulteLe;

  const JournalConsultationData({
    required this.id,
    required this.enfantId,
    required this.etablissementId,
    required this.etablissementNom,
    required this.typeFiche,
    required this.consulteLe,
  });

  factory JournalConsultationData.fromRow(
    Map<String, dynamic> row,
  ) {
    final etablissement =
        row['etablissements'] as Map<String, dynamic>?;

    return JournalConsultationData(
      id: row['id'] as String,
      enfantId: row['enfant_id'] as String,
      etablissementId: row['etablissement_id'] as String?,
      etablissementNom: etablissement?['nom'] as String?,
      typeFiche: _typeFicheFromRow(
        row['type_fiche'] as String,
      ),
      consulteLe: DateTime.parse(
        row['consulte_le'] as String,
      ),
    );
  }
}
