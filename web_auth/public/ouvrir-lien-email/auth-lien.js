// Logique de la page "ouvrir-lien-email" : vérification du jeton reçu
// par email, puis changement de mot de passe.
//
// Volontairement séparée de index.html et sans aucune dépendance :
// c'est la porte d'entrée de tout parent bloqué hors de son compte,
// elle doit être couverte par des tests automatiques (voir
// ../../test/auth-lien.test.mjs, lancés par `node --test`).
//
// Aucun appel réseau n'est fait directement ici : `fetch` est injecté,
// pour que les tests décrivent les réponses de l'API sans réseau.
//
// RGPD : ce module ne lit, n'affiche et ne transmet aucune donnée
// d'enfant ni de santé. Il ne journalise rien — en particulier jamais
// le jeton, qui vit dans le fragment de l'URL et n'est donc jamais
// envoyé à un serveur d'hébergement.

/// Longueur minimale, alignée sur l'app (`set_new_password_page.dart`).
export const LONGUEUR_MINIMALE_MOT_DE_PASSE = 8;

export const MESSAGES = {
  lienInvalide:
    'Ce lien n’est pas valide. Redemandez un email depuis '
    + 'l’application KidsRelay.',
  // Un seul message pour "expiré" et "déjà utilisé" : l'API ne permet
  // pas de les distinguer de façon fiable, et un message précis mais
  // faux une fois sur deux vaut moins qu'un message honnête.
  lienPerime:
    'Ce lien n’est plus valable : il a peut-être expiré, ou déjà été '
    + 'utilisé. Redemandez un email depuis l’application KidsRelay.',
  motDePasseTropCourt:
    'Le mot de passe doit contenir au moins '
    + `${LONGUEUR_MINIMALE_MOT_DE_PASSE} caractères.`,
  motsDePasseDifferents:
    'Les deux mots de passe ne correspondent pas.',
  motDePasseTropSimple:
    'Ce mot de passe est trop simple. Choisissez-en un plus solide.',
  motDePasseIdentique:
    'Le nouveau mot de passe doit être différent de l’ancien.',
  reseau:
    'Impossible de contacter le serveur. Vérifiez votre connexion.',
  generique:
    'Une erreur est survenue. Réessayez dans quelques instants.',
};

/// Types de lien acceptés. `recovery` = mot de passe oublié,
/// `signup` = confirmation de compte.
const TYPES_ACCEPTES = ['recovery', 'signup'];

/// Lit `token_hash` et `type` dans le fragment de l'URL
/// (`#token_hash=...&type=recovery`).
///
/// Le fragment, contrairement à la chaîne de requête, n'est jamais
/// transmis au serveur : c'est ce qui garantit que le jeton n'apparaît
/// dans aucun journal d'hébergement.
///
/// Retourne `null` si le fragment est absent, incomplet, ou porte un
/// type inconnu.
export function lireParametresDuFragment(fragment) {
  if (typeof fragment !== 'string') {
    return null;
  }

  const parametres = new URLSearchParams(
    fragment.startsWith('#') ? fragment.slice(1) : fragment,
  );

  const tokenHash = parametres.get('token_hash');
  const type = parametres.get('type');

  if (!tokenHash || !type || !TYPES_ACCEPTES.includes(type)) {
    return null;
  }

  return { tokenHash, type };
}

/// Vérifie que les deux saisies forment un mot de passe acceptable.
/// Retourne `null` si tout va bien, sinon le message à afficher.
export function validerMotDePasse(motDePasse, confirmation) {
  if (
    typeof motDePasse !== 'string'
    || motDePasse.length < LONGUEUR_MINIMALE_MOT_DE_PASSE
  ) {
    return MESSAGES.motDePasseTropCourt;
  }

  if (motDePasse !== confirmation) {
    return MESSAGES.motsDePasseDifferents;
  }

  return null;
}

/// Traduit un échec de l'API Auth en message français, dans la même
/// veine que `auth_error_message.dart` côté app.
export function messagePourEchec(statut, corps) {
  const code = corps?.error_code ?? corps?.code ?? null;

  if (code === 'weak_password') {
    return MESSAGES.motDePasseTropSimple;
  }

  if (code === 'same_password') {
    return MESSAGES.motDePasseIdentique;
  }

  // 4xx sur la vérification d'un jeton à usage unique : expiré,
  // déjà consommé, ou inconnu. Tous se présentent au parent de la
  // même façon — il doit redemander un email.
  if (statut >= 400 && statut < 500) {
    return MESSAGES.lienPerime;
  }

  return MESSAGES.generique;
}

async function appelerApi(
  { fetch: fetchInjecte, apiUrl, apiKey },
  chemin,
  options,
) {
  let reponse;

  try {
    reponse = await fetchInjecte(`${apiUrl}${chemin}`, {
      ...options,
      headers: {
        apikey: apiKey,
        'Content-Type': 'application/json',
        ...(options.headers ?? {}),
      },
    });
  } catch {
    // Panne réseau, DNS, hors-ligne : jamais l'erreur brute, qui
    // pourrait contenir l'URL et donc le jeton.
    return { ok: false, message: MESSAGES.reseau };
  }

  let corps = null;

  try {
    corps = await reponse.json();
  } catch {
    corps = null;
  }

  if (!reponse.ok) {
    return {
      ok: false,
      message: messagePourEchec(reponse.status, corps),
    };
  }

  return { ok: true, corps };
}

/// Point d'entrée de la page : lit le fragment, vérifie le jeton, et
/// dit quoi afficher.
///
/// Retourne une "vue" que index.html se contente de rendre :
///   { type: 'erreur', message }
///   { type: 'formulaire-mot-de-passe', accessToken }
///   { type: 'compte-confirme' }
export async function demarrer({ fragment, fetch, apiUrl, apiKey }) {
  const parametres = lireParametresDuFragment(fragment);

  if (parametres === null) {
    return { type: 'erreur', message: MESSAGES.lienInvalide };
  }

  const resultat = await appelerApi(
    { fetch, apiUrl, apiKey },
    '/auth/v1/verify',
    {
      method: 'POST',
      body: JSON.stringify({
        type: parametres.type,
        token_hash: parametres.tokenHash,
      }),
    },
  );

  if (!resultat.ok) {
    return { type: 'erreur', message: resultat.message };
  }

  if (parametres.type === 'signup') {
    return { type: 'compte-confirme' };
  }

  const accessToken = resultat.corps?.access_token ?? null;

  if (!accessToken) {
    return { type: 'erreur', message: MESSAGES.generique };
  }

  return { type: 'formulaire-mot-de-passe', accessToken };
}

/// Enregistre le nouveau mot de passe. Retourne `{ ok: true }` ou
/// `{ ok: false, message }`.
export async function soumettreMotDePasse({
  fetch,
  apiUrl,
  apiKey,
  accessToken,
  motDePasse,
  confirmation,
}) {
  const erreurDeSaisie = validerMotDePasse(motDePasse, confirmation);

  if (erreurDeSaisie !== null) {
    return { ok: false, message: erreurDeSaisie };
  }

  const resultat = await appelerApi(
    { fetch, apiUrl, apiKey },
    '/auth/v1/user',
    {
      method: 'PUT',
      headers: { Authorization: `Bearer ${accessToken}` },
      body: JSON.stringify({ password: motDePasse }),
    },
  );

  if (!resultat.ok) {
    return { ok: false, message: resultat.message };
  }

  return { ok: true };
}
