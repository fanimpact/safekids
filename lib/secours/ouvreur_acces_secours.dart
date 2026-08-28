/// D'où vient un accès secours, tel que le parent le lira.
///
/// Décision de Fanny du 28/08/2026 : le parent doit savoir qui a
/// ouvert — mais **la fonction et l'établissement, jamais le nom de la
/// personne**. Il doit comprendre ce qui s'est passé, pas surveiller
/// nominativement le personnel d'une école.
///
/// **Pourquoi la fonction est citée entre guillemets.** La règle posée
/// le 25/08/2026 dans `fonction_professionnelle.dart` interdit à
/// l'application d'ajouter « une », « (e) » ou un féminin de
/// circonstance : la personne écrit ce qu'elle est. « ouvert par une
/// Enseignant·e » serait faux, et « une ATSEM » ne se généralise pas.
/// Les guillemets marquent un libellé rapporté, pas un accord.
///
/// **Pourquoi le silence est dit.** Depuis un lien de partage,
/// l'ouvreur est anonyme : personne ne s'est identifié, et on n'invente
/// rien. La ligne le dit plutôt que de rester vide.
library;

String texteOuvreurAccesSecours({
  String? fonction,
  String? etablissement,
}) {
  final f = fonction?.trim();
  final e = etablissement?.trim();

  final aFonction = f != null && f.isNotEmpty;
  final aEtablissement = e != null && e.isNotEmpty;

  if (aEtablissement && aFonction) {
    return 'Ouvert depuis $e, par « $f ».';
  }

  if (aEtablissement) {
    return 'Ouvert depuis $e. La fonction de la personne '
        'n’était pas renseignée.';
  }

  if (aFonction) {
    return 'Ouvert par « $f ».';
  }

  return 'Ouvert depuis un lien de partage : la personne qui l’a '
      'fait ne s’était pas identifiée.';
}
