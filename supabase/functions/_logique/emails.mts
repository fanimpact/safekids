// Emails transactionnels : ce qu'ils disent, et comment on les envoie.
//
// Le contenu est construit par des fonctions pures, testables sans
// reseau. L'envoi passe par `fetch`, injecte pour la meme raison.
//
// Brevo n'est pas une dependance a Supabase : ces emails partiraient
// par Brevo quel que soit l'hebergeur. Ce qui est ici derriere une
// interface, c'est la possibilite d'en changer un jour sans toucher au
// contenu des messages.
//
// Contrainte de contenu, valable pour tout message construit ici :
// jamais de donnee de sante, jamais de nom de famille d'enfant, jamais
// le texte d'une note. Les tests de `_tests/emails.test.mjs` la
// verifient message par message.

import {
  piedConsigneHtml,
  piedConsigneTexte,
} from './consigne_domaine_jeune.mts';

export interface Message {
  destinataire: string;
  sujet: string;
  html: string;

  /// La même chose en texte simple, quand elle existe.
  ///
  /// Un message qui n'existe qu'en HTML est un signal de courrier
  /// indésirable pour une partie des filtres. Facultative pour ne
  /// pas réécrire les messages qui existaient avant le 28/08/2026,
  /// mais à fournir pour tout nouveau message.
  texte?: string;
}

export interface ExpediteurEmail {
  cleApi: string;
  expediteurEmail: string;
  expediteurNom: string;
  repondreAEmail: string;
}

export const URL_BREVO = 'https://api.brevo.com/v3/smtp/email';

/// Nouvel appareil detecte : le code, sa duree de validite, et la
/// marche a suivre si l'on n'est pas a l'origine de la connexion.
export function messageCodeVerification(
  destinataire: string,
  code: string,
  validiteMinutes: number,
): Message {
  return {
    destinataire,
    sujet: 'Votre code de vérification KidsRelay',
    html:
      `<p>Nouvel appareil détecté sur votre compte KidsRelay.</p>` +
      `<p>Votre code de vérification : ` +
      `<strong style="font-size:20px">${code}</strong></p>` +
      `<p>Ce code est valable ${validiteMinutes} minutes. ` +
      `Si vous n’êtes pas à l’origine de cette ` +
      `connexion, ignorez cet email.</p>` +
      // Le domaine est jeune : ce mail est celui que le plus de
      // gens attendent vraiment, c'est donc le bon endroit pour
      // dire quoi faire s'il manque. Voir
      // `consigne_domaine_jeune.mts`.
      piedConsigneHtml(),
    // Un message qui n'existe qu'en HTML est un signal de
    // courrier indesirable pour une partie des filtres — et
    // c'est precisement le probleme qu'on traite ici.
    texte:
      `Nouvel appareil détecté sur votre compte KidsRelay.\n\n` +
      `Votre code de vérification : ${code}\n\n` +
      `Ce code est valable ${validiteMinutes} minutes. ` +
      `Si vous n’êtes pas à l’origine de cette connexion, ` +
      `ignorez cet email.` +
      piedConsigneTexte(),
  };
}

/// Note ajoutee par un etablissement : le prenom de l'enfant et le nom
/// de l'etablissement, jamais le contenu de la note. Le parent doit
/// ouvrir l'application pour la lire — c'est la seule facon de garantir
/// qu'une note ne transite pas par une boite mail.
export function messageNoteAjoutee(
  destinataire: string,
  prenomEnfant: string,
  nomEtablissement: string,
): Message {
  return {
    destinataire,
    sujet: 'Une note a été ajoutée sur KidsRelay',
    html:
      `<p>Une note a été ajoutée sur le profil de ` +
      `${prenomEnfant} par ${nomEtablissement}.</p>` +
      `<p>Connectez-vous à l’application KidsRelay pour la consulter.</p>`,
  };
}

export interface ResultatEnvoi {
  envoye: boolean;
  statut: number;
  detail: string | null;
}

/// `envoyer` recoit `fetch` en parametre : les tests decrivent la
/// reponse de l'API sans reseau, exactement comme pour la page
/// `auth.kidsrelay.fr`.
export async function envoyerParBrevo(
  fetchImpl: typeof fetch,
  expediteur: ExpediteurEmail,
  message: Message,
): Promise<ResultatEnvoi> {
  const reponse = await fetchImpl(URL_BREVO, {
    method: 'POST',
    headers: {
      'api-key': expediteur.cleApi,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      sender: {
        email: expediteur.expediteurEmail,
        name: expediteur.expediteurNom,
      },
      replyTo: { email: expediteur.repondreAEmail },
      to: [{ email: message.destinataire }],
      subject: message.sujet,
      htmlContent: message.html,
      // Omis quand il n'y en a pas : Brevo refuse une valeur vide.
      ...(message.texte ? { textContent: message.texte } : {}),
    }),
  });

  if (reponse.ok) {
    return { envoye: true, statut: reponse.status, detail: null };
  }

  return {
    envoye: false,
    statut: reponse.status,
    detail: await reponse.text(),
  };
}
