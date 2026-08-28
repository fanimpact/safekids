/// Quand redemander le déverrouillage de l'appareil.
///
/// **Pourquoi un délai et non un verrou à chaque ouverture.** Pendant
/// une urgence, on ouvre et referme l'application sans arrêt — pour
/// lire une posologie, pour la relire, pour montrer un écran. Un
/// verrou à chaque fois arrêterait le parent à chaque geste, au pire
/// moment. Décision de Fanny, 28/08/2026.
///
/// Fonction pure : la règle se teste sans horloge réelle, sans plugin
/// et sans écran.
library;

/// Quinze minutes sans ouvrir l'application.
///
/// Assez court pour qu'un téléphone posé sur une table ne reste pas
/// ouvert toute la journée. Assez long pour couvrir une intervention
/// où l'on consulte la fiche à plusieurs reprises.
const Duration dureeGraceVerrou = Duration(minutes: 15);

/// Vrai s'il faut redemander le déverrouillage.
///
/// [derniereOuverture] est nulle au tout premier démarrage, ou quand
/// l'application n'a jamais enregistré d'ouverture : on demande, parce
/// qu'on ne sait pas.
///
/// Une date d'ouverture **dans le futur** demande aussi : un écart
/// d'horloge ne doit pas ouvrir une fenêtre sans fin. C'est la même
/// règle que pour la tolérance du verrou de partage.
bool verrouRequis({
  required DateTime? derniereOuverture,
  required DateTime maintenant,
  Duration grace = dureeGraceVerrou,
}) {
  if (derniereOuverture == null) {
    return true;
  }

  final ecoule = maintenant.difference(derniereOuverture);

  if (ecoule.isNegative) {
    return true;
  }

  return ecoule > grace;
}
