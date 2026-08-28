/// Une ouverture refusée — ou tolérée — sur un lien de partage.
///
/// Le lien se verrouille sur le premier appareil qui l'ouvre. Ce qui
/// est enregistré ici, c'est **qu'une autre ouverture a eu lieu**, et
/// rien d'autre : ni adresse IP, ni en-tête de requête, ni empreinte de
/// navigateur. La fonction serveur ne les lit même pas.
///
/// [toleree] distingue les deux cas que le parent doit lire
/// différemment :
///
///  - **tolérée** : dans les quinze minutes suivant la première
///    ouverture, un second appareil reprend le verrou au lieu d'être
///    refusé. Cela absorbe le cas très courant du navigateur intégré
///    d'un client mail suivi de « ouvrir dans Chrome ». C'est une
///    information, pas un refus — mais le parent la voit quand même,
///    sinon la fenêtre serait un trou de quinze minutes invisible ;
///  - **refusée** : quelqu'un a tenté d'ouvrir le lien depuis un autre
///    appareil, et n'a rien vu.
///
/// [reprise] est le troisième cas, ajouté le 28/08/2026 : quelqu'un a
/// été refusé, **a dit que c'était lui**, et a repris l'accès. Ce
/// n'est ni un refus ni une tolérance silencieuse — c'est un geste
/// délibéré, et le parent doit le lire comme tel.
class TentativePartageData {
  final String id;
  final String partageId;
  final DateTime tenteeLe;
  final bool toleree;

  /// Quelqu'un a demandé à reprendre l'accès après un refus.
  final bool reprise;

  const TentativePartageData({
    required this.id,
    required this.partageId,
    required this.tenteeLe,
    required this.toleree,
    this.reprise = false,
  });

  factory TentativePartageData.fromRow(Map<String, dynamic> row) {
    return TentativePartageData(
      id: row['id'] as String,
      partageId: row['partage_id'] as String,
      tenteeLe: DateTime.parse(row['tentee_le'] as String).toLocal(),
      toleree: row['toleree'] as bool? ?? false,
      reprise: row['reprise'] as bool? ?? false,
    );
  }
}

/// Ce que le parent lit sur la carte d'un lien qui a vu passer
/// d'autres appareils.
///
/// Les refus priment sur les tolérances : ce sont eux qui demandent
/// une décision.
String? libelleTentatives(List<TentativePartageData> tentatives) {
  if (tentatives.isEmpty) {
    return null;
  }

  final refus = tentatives.where((t) => !t.toleree).length;

  if (refus > 0) {
    return refus == 1
        ? 'Une ouverture a été refusée depuis un autre appareil.'
        : '$refus ouvertures ont été refusées depuis d’autres '
            'appareils.';
  }

  // La reprise passe avant la tolérance silencieuse : c'est un
  // geste que quelqu'un a posé, et le parent doit pouvoir décider.
  final reprises = tentatives.where((t) => t.reprise).length;

  if (reprises > 0) {
    return reprises == 1
        ? 'Quelqu’un a repris l’accès depuis un autre appareil, en '
            'indiquant que c’était bien lui.'
        : '$reprises reprises d’accès depuis d’autres appareils.';
  }

  return 'Ce lien a été rouvert depuis un autre appareil peu après '
      'la première ouverture.';
}
