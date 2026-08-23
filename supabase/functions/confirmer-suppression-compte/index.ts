// Edge Function "confirmer-suppression-compte"
//
// Appelee par l'app juste apres qu'un parent a demande la suppression
// de son compte. Envoie un email rappelant la date d'effacement
// definitif et la facon d'annuler.
//
// Ne decide rien et n'ecrit rien : la demande est deja enregistree en
// base par la fonction demander_suppression_compte(), qui a pose les
// dates et rendu le compte inaccessible. Cette fonction ne fait que
// prevenir.
//
// C'est aussi pour cela que son echec n'annule pas la demande cote
// application : voir section_suppression_compte.dart.
//
// Ce fichier ne contient que l'enveloppe. Le contenu du message est
// dans ../_logique/suppression_compte.mts, ou il est teste sans
// reseau.
//
// Necessite un appelant authentifie : deployee AVEC verification JWT.
//   supabase functions deploy confirmer-suppression-compte
//
// Variables d'environnement requises : les memes BREVO_* que
// envoyer-code-verification.

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

import { identifierAppelant } from '../_enveloppe/supabase.mts';

import { envoyerParBrevo } from '../_logique/emails.mts';

import {
  lireDateEffacement,
  messageSuppressionDemandee,
} from '../_logique/suppression_compte.mts';

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

  const effacementLe = lireDateEffacement(corps.effacementLe);

  if (!effacementLe) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  // Un compte sans adresse email ne peut pas etre prevenu. Ce n'est
  // pas une erreur : la demande de suppression, elle, est bien
  // enregistree, et le parent a la date sous les yeux dans l'app.
  if (!appelant.email) {
    return reponseJson({ ok: true, notifie: false }, 200);
  }

  const resultat = await envoyerParBrevo(
    fetch,
    email,
    messageSuppressionDemandee(appelant.email, effacementLe),
  );

  if (!resultat.envoye) {
    console.error(
      'Echec envoi Brevo',
      resultat.statut,
      resultat.detail,
    );
    return reponseJson(
      { error: 'Impossible d’envoyer la confirmation.' },
      502,
    );
  }

  return reponseJson({ ok: true, notifie: true }, 200);
});
