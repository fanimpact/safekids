// La consigne « regardez dans vos courriers indésirables ».
//
// POURQUOI ELLE EXISTE
//
// Le 28/08/2026, le premier mail réel de KidsRelay est arrivé dans les
// indésirables d'une boîte Hotmail. L'authentification n'était pas en
// cause : Microsoft a répondu `compauth=pass reason=100`, son verdict
// le plus élevé, et l'IP d'envoi n'était sur aucune liste noire.
//
// La seule explication restante : `kidsrelay.fr` n'a presque jamais
// envoyé de courrier. Un fournisseur qui ne connaît pas un domaine le
// classe en indésirable par défaut. C'est son comportement normal, et
// aucun réglage ne le contourne — cela se construit avec le temps.
//
// Fanny a refusé de laisser les parents découvrir le problème seuls.
// D'où cette consigne, **aux deux endroits à la fois** : à l'écran
// pendant l'attente du code, et en pied du mail lui-même.
//
// L'écran compte plus que le mail : si la consigne n'était que dans le
// message, la personne ne la lirait jamais — le message est justement
// dans les indésirables.
//
// LE TON
//
// Aucune conséquence évoquée, aucun enfant, aucun secours. Consigne
// ferme de Fanny : on parle d'une application jeune et d'un geste à
// faire, rien d'autre. Quelqu'un qui lit ça n'apprend pas qu'il court
// un risque, il apprend quoi faire si un message manque.
//
// « Courriers indésirables » et pas « spams » : c'est le terme affiché
// en français par Hotmail, Gmail et Outlook. Une personne peu à l'aise
// cherche le mot qu'elle a sous les yeux.
//
// « Légitime » partout, y compris là où le bouton du fournisseur dit
// autre chose : Fanny ne veut pas de formulation négative.
//
// COMMENT LA RETIRER
//
// **Passer [consigneDomaineJeuneActive] à `false`, ici et dans
// `supabase/functions/_logique/consigne_domaine_jeune.mts`.** Les deux
// textes disparaissent ensemble, de l'écran comme du mail.
//
// Un test refuse que les deux drapeaux diffèrent : on ne peut pas en
// éteindre un et oublier l'autre.
//
// **À quoi reconnaître le moment** : un mail de test envoyé à une
// boîte Hotmail neuve arrive en boîte de réception sans que personne
// ait rien marqué. Tant que ce n'est pas le cas, la consigne reste.

/// La consigne est-elle affichée ?
///
/// Temporaire par construction — voir l'en-tête de ce fichier.
const bool consigneDomaineJeuneActive = true;

/// Ne s'adresse qu'à celui qui a le problème.
///
/// Sans ce titre, tout le monde lit un paragraphe qui ne le concerne
/// pas, sur un écran où l'on attend déjà.
const String titreConsigneDomaineJeune = 'Vous ne recevez rien ?';

/// Ce que voit la personne qui attend son code.
const String consigneDomaineJeuneEcran =
    'KidsRelay est une application récente. Regardez dans vos '
    'courriers indésirables : si le message s’y trouve, marquez-le '
    'comme légitime. Les suivants arriveront normalement.';

/// Ce que porte le pied du mail de code.
///
/// **Recopié ici uniquement pour être comparé.** Le texte qui part
/// vraiment vit dans `_logique/consigne_domaine_jeune.mts`, du côté
/// serveur ; un test vérifie que les deux sont identiques au caractère
/// près. Deux langages, donc deux fichiers — mais jamais deux textes
/// qui divergent sans qu'on s'en aperçoive.
const String consigneDomaineJeuneEmail =
    'KidsRelay est une application récente. Si nos messages arrivent '
    'dans vos courriers indésirables, marquez-les comme légitimes — '
    'les suivants arriveront normalement.';
