/// Une demande d'accès déposée par un quatrième appareil.
///
/// **Pourquoi elle existe.** Un partage ordinaire accepte trois
/// appareils. Au-delà, la personne est arrêtée : elle dit qui elle est
/// en soixante caractères, et le parent décide.
///
/// **Ce que la ligne contient, et ce qu'elle ne contient pas.** Le
/// haché du secret du navigateur — jamais le secret — et la raison
/// saisie. Ni adresse IP, ni en-tête de requête, ni empreinte de
/// navigateur : même règle que le journal des tentatives.
///
/// **La raison ne sort jamais de l'application.** Le mail au parent
/// annonce seulement qu'une demande attend. Elle est écrite par une
/// personne inconnue et pourrait contenir n'importe quoi, et la règle
/// permanente interdit toute donnée de santé ou nom de famille dans un
/// email.
class DemandeAccesData {
  final String id;
  final String partageId;

  /// Ce que la personne a écrit pour se présenter.
  final String raison;

  final DateTime creeLe;

  /// Nulle tant que le parent n'a pas répondu.
  ///
  /// **Le silence ne vaut jamais accord** : une demande sans réponse
  /// s'efface au bout de trente jours sans rien autoriser.
  final DateTime? autoriseeLe;

  const DemandeAccesData({
    required this.id,
    required this.partageId,
    required this.raison,
    required this.creeLe,
    this.autoriseeLe,
  });

  bool get estEnAttente => autoriseeLe == null;

  factory DemandeAccesData.fromRow(Map<String, dynamic> row) {
    final autoriseeLe = row['autorisee_le'] as String?;

    return DemandeAccesData(
      id: row['id'] as String,
      partageId: row['partage_id'] as String,
      raison: row['raison'] as String,
      creeLe: DateTime.parse(row['cree_le'] as String).toLocal(),
      autoriseeLe:
          autoriseeLe == null ? null : DateTime.parse(autoriseeLe).toLocal(),
    );
  }
}

/// Ce que le parent lit au-dessus des demandes d'un partage.
///
/// Rend `null` quand il n'y a rien à dire : une carte sans demande ne
/// doit pas porter de ligne vide.
String? libelleDemandes(List<DemandeAccesData> demandes) {
  final enAttente = demandes.where((d) => d.estEnAttente).length;

  if (enAttente == 0) {
    return null;
  }

  return enAttente == 1
      ? 'Un appareil de plus demande à ouvrir cette fiche.'
      : '$enAttente appareils de plus demandent à ouvrir cette fiche.';
}
