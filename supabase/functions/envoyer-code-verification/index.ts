// Edge Function "envoyer-code-verification"
//
// Appelee par l'app juste apres qu'un mot de passe a ete valide, quand
// l'appareil utilise n'est pas dans "appareils_reconnus" pour ce
// compte. Genere un code a 6 chiffres, le stocke hache (jamais en
// clair) dans "codes_verification" avec une expiration courte, et
// l'envoie par email via Brevo.
//
// Ce fichier ne contient que l'enveloppe : lecture des variables,
// identification de l'appelant, branchement du depot sur Supabase,
// traduction des resultats en reponses HTTP. La logique est dans
// ../_logique/codes_verification.mts et ../_logique/emails.mts, ou
// elle est testee sans base ni reseau.
//
// Necessite un appelant authentifie (le mot de passe a deja ete
// verifie par Supabase Auth avant cet appel) : deployee AVEC
// verification JWT (pas de --no-verify-jwt).
//   supabase functions deploy envoyer-code-verification
//
// Variables d'environnement requises (Supabase -> Project Settings ->
// Edge Functions -> Secrets) :
//   BREVO_API_KEY        cle API Brevo (jamais dans le code)
//   BREVO_SENDER_EMAIL   adresse expediteur verifiee dans Brevo
//   BREVO_SENDER_NAME    nom affiche comme expediteur (ex. "KidsRelay")
//   BREVO_REPLY_TO_EMAIL optionnelle : adresse de reponse si differente
//                        de l'expediteur (sinon, BREVO_SENDER_EMAIL
//                        sert aussi de reply-to)

import {
  enTeteAutorisation,
  estPreflight,
  lireCorpsJson,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import {
  lireConfigurationBase,
  lireConfigurationEmail,
} from '../_enveloppe/environnement.mts';

import {
  clientServiceRole,
  identifierAppelant,
} from '../_enveloppe/supabase.mts';

import { depotCodesSupabase } from '../_enveloppe/depot_codes.mts';

import {
  CODE_VALIDE_MINUTES,
  aleaCryptographique,
  dateExpiration,
  genererCode,
  hacher,
  jetonAppareilValide,
} from '../_logique/codes_verification.mts';

import {
  envoyerParBrevo,
  messageCodeVerification,
} from '../_logique/emails.mts';

Deno.serve(async (req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  const base = lireConfigurationBase();
  const email = lireConfigurationEmail();

  if (!base || !email) {
    console.error(
      'Variable d’environnement manquante (Supabase ou Brevo).',
    );
    return reponseJson(
      { error: 'Configuration serveur incomplete.' },
      500,
    );
  }

  const autorisation = enTeteAutorisation(req);

  if (!autorisation) {
    return reponseJson({ error: 'Non authentifie.' }, 401);
  }

  const appelant = await identifierAppelant(base, autorisation);

  if (!appelant) {
    return reponseJson({ error: 'Non authentifie.' }, 401);
  }

  const corps = await lireCorpsJson(req);

  if (!corps) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  const jetonAppareilHash = corps.jetonAppareilHash;

  if (!jetonAppareilValide(jetonAppareilHash)) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  if (!appelant.email) {
    return reponseJson(
      { error: 'Compte sans adresse email.' },
      400,
    );
  }

  const code = genererCode(aleaCryptographique);
  const codeHash = await hacher(code);

  const depot = depotCodesSupabase(clientServiceRole(base));

  const { erreur: erreurInsertion } = await depot.enregistrerCode({
    userId: appelant.id,
    codeHash,
    jetonAppareilHash,
    expireLe: dateExpiration(new Date()),
  });

  if (erreurInsertion) {
    console.error(erreurInsertion);
    return reponseJson(
      { error: 'Impossible de generer le code.' },
      500,
    );
  }

  const resultat = await envoyerParBrevo(
    fetch,
    email,
    messageCodeVerification(
      appelant.email,
      code,
      CODE_VALIDE_MINUTES,
    ),
  );

  if (!resultat.envoye) {
    console.error(
      'Echec envoi Brevo',
      resultat.statut,
      resultat.detail,
    );
    return reponseJson(
      { error: 'Impossible d’envoyer le code.' },
      502,
    );
  }

  return reponseJson({ ok: true }, 200);
});
