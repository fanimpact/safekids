// Email envoyé au parent au moment où il demande la suppression de son
// compte.
//
// Aucun import Deno, aucun SDK, aucun appel réseau direct : la date
// courante et l'envoi entrent par paramètre.
//
// Ce que cet email doit contenir, et pourquoi :
//
//   - la date d'effacement définitif, en clair. C'est la seule chose
//     que le parent ne peut pas retrouver s'il ferme l'application ;
//   - comment annuler. Un délai de grâce dont on ne sait pas sortir
//     n'est pas un délai de grâce ;
//   - ce qui se passe s'il ne fait rien. Le silence ne doit pas être
//     interprétable.
//
// Ce que cet email ne contient pas : aucun nom d'enfant, aucune donnée
// de santé, aucun lien cliquable. L'annulation se fait dans
// l'application, où le parent est déjà authentifié — un lien
// d'annulation dans un email serait un moyen supplémentaire de
// détourner un compte.

export const DELAI_GRACE_JOURS = 7;

export interface MessageSuppression {
  destinataire: string;
  sujet: string;
  html: string;
}

/// Date au format français, sans heure : l'heure exacte n'aide pas et
/// donne une fausse précision sur le passage d'une tâche automatique
/// qui tourne une fois par jour.
export function formaterDateFr(date: Date): string {
  const jour = String(date.getUTCDate()).padStart(2, '0');
  const mois = String(date.getUTCMonth() + 1).padStart(2, '0');

  return `${jour}/${mois}/${date.getUTCFullYear()}`;
}

/// `null` si la date est absente ou illisible. L'appelant refuse alors
/// d'envoyer : un email qui annoncerait « Invalid Date » serait pire
/// que pas d'email du tout.
export function lireDateEffacement(
  valeur: unknown,
): Date | null {
  if (typeof valeur !== 'string') {
    return null;
  }

  const date = new Date(valeur);

  return Number.isNaN(date.getTime()) ? null : date;
}

export function messageSuppressionDemandee(
  destinataire: string,
  effacementLe: Date,
): MessageSuppression {
  const date = formaterDateFr(effacementLe);

  return {
    destinataire,
    sujet: 'Votre compte KidsRelay va être supprimé',
    html:
      `<p>Vous avez demandé la suppression de votre compte ` +
      `KidsRelay. Votre compte n’est déjà plus accessible.</p>` +
      `<p><strong>Vos données seront effacées définitivement le ` +
      `${date}.</strong> Passé cette date, rien ne pourra être ` +
      `restauré.</p>` +
      `<p>Si vous changez d’avis, ouvrez l’application KidsRelay et ` +
      `connectez-vous : l’écran d’accueil vous proposera d’annuler ` +
      `la suppression. Vous retrouverez alors tout en l’état.</p>` +
      `<p>Si vous ne faites rien, l’effacement aura lieu à la date ` +
      `indiquée.</p>` +
      `<p>Vous n’êtes pas à l’origine de cette demande ? ` +
      `Connectez-vous dès maintenant pour l’annuler, puis changez ` +
      `votre mot de passe.</p>`,
  };
}
