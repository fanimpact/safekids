/// Qui consulte une fiche affichant des traitements — détermine si une
/// mention doit accompagner chaque traitement, et laquelle. Rappel du
/// cadre (pas un avertissement) : un traitement d'urgence ou régulier
/// ne s'administre que selon le PAI (structure d'accueil) ou selon les
/// indications du parent (particulier). Le parent qui consulte la
/// fiche de son propre enfant n'a besoin d'aucun rappel — il est la
/// source de l'information.
enum TreatmentAudience { owner, particulier, professionnel }

/// Courte, placée avec le traitement (jamais en bas de page) — voir
/// corrections_a_faire.md. `null` pour [TreatmentAudience.owner].
String? treatmentMentionSuffix(TreatmentAudience audience) {
  switch (audience) {
    case TreatmentAudience.owner:
      return null;
    case TreatmentAudience.particulier:
      return 'posologie et administration selon les indications du '
          'parent';
    case TreatmentAudience.professionnel:
      return 'posologie et administration selon le PAI';
  }
}
