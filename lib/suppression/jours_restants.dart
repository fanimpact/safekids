/// Combien de temps reste-t-il avant l'effacement définitif, et
/// comment le dire.
///
/// Fonctions pures : la règle se teste sans écran et sans base.
library;

/// Nombre de jours **entamés** avant l'effacement.
///
/// Compté en jours entamés et non en jours pleins : à 23 heures de
/// l'échéance il reste « 1 jour », pas « 0 jour ». Annoncer zéro à
/// quelqu'un qui a encore le temps d'annuler serait une erreur dans le
/// sens qui fait mal.
///
/// Négatif ou nul si la date est passée — l'effacement n'a alors qu'un
/// passage de la tâche automatique de retard.
int joursRestants(DateTime effacementLe, DateTime maintenant) {
  final restant = effacementLe.difference(maintenant);

  if (restant.isNegative) {
    return 0;
  }

  // Arrondi au jour superieur, en minutes : compter en heures
  // entieres rendrait "0 jour" a trente minutes de l'echeance.
  const minutesParJour = 24 * 60;

  return (restant.inMinutes / minutesParJour).ceil();
}

String texteJoursRestants(int jours) {
  if (jours <= 0) {
    return 'L’effacement va avoir lieu';
  }

  if (jours == 1) {
    return 'Il vous reste 1 jour pour annuler';
  }

  return 'Il vous reste $jours jours pour annuler';
}

String formaterDateFr(DateTime date) {
  final jour = date.day.toString().padLeft(2, '0');
  final mois = date.month.toString().padLeft(2, '0');

  return '$jour/$mois/${date.year}';
}

String formaterDateHeureFr(DateTime date) {
  final heure = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${formaterDateFr(date)} à ${heure}h$minute';
}
