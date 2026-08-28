// La consigne « regardez dans vos courriers indésirables », côté mail.
//
// Le raisonnement complet est dans `lib/textes/consigne_domaine_jeune.dart`,
// qui porte la même consigne pour l'écran. En bref : le 28/08/2026, le
// premier mail réel est arrivé dans les indésirables d'une boîte
// Hotmail alors que l'authentification était parfaite
// (`compauth=pass reason=100`) et l'IP d'envoi propre. Il ne restait
// qu'une explication : `kidsrelay.fr` n'a pas d'historique d'envoi.
//
// **Ce fichier est la source du texte qui part réellement.** Le côté
// Flutter en garde une copie pour la comparer : un test refuse que les
// deux divergent, et refuse que les deux drapeaux diffèrent.
//
// POUR LA RETIRER : passer le drapeau à `false` ici **et** dans le
// fichier Dart. Les deux textes disparaissent ensemble.

/// La consigne est-elle ajoutée aux emails ?
///
/// Temporaire par construction. À éteindre quand un mail de test
/// envoyé à une boîte Hotmail neuve arrivera en boîte de réception
/// sans que personne ait rien marqué.
export const CONSIGNE_DOMAINE_JEUNE_ACTIVE = true;

/// Le pied de message.
///
/// « Courriers indésirables » et pas « spams » : c'est le terme
/// affiché en français par Hotmail, Gmail et Outlook. « Légitimes »
/// même là où le bouton du fournisseur dit autre chose — Fanny ne veut
/// pas de formulation négative.
export const CONSIGNE_DOMAINE_JEUNE =
  'KidsRelay est une application récente. Si nos messages arrivent ' +
  'dans vos courriers indésirables, marquez-les comme légitimes — ' +
  'les suivants arriveront normalement.';

/// Le pied en HTML, discret, ou une chaîne vide si la consigne est
/// éteinte.
export function piedConsigneHtml(): string {
  if (!CONSIGNE_DOMAINE_JEUNE_ACTIVE) {
    return '';
  }

  return (
    `<p style="font-size:13px;color:#5f6368">` +
    `${CONSIGNE_DOMAINE_JEUNE}</p>`
  );
}

/// Le même pied en texte simple.
export function piedConsigneTexte(): string {
  if (!CONSIGNE_DOMAINE_JEUNE_ACTIVE) {
    return '';
  }

  return `\n\n${CONSIGNE_DOMAINE_JEUNE}`;
}
