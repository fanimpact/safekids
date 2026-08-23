// Edge Function "verifier-code"
//
// Verifie le code a 6 chiffres envoye par "envoyer-code-verification".
// En cas de succes, enregistre l'appareil dans "appareils_reconnus"
// pour que les connexions suivantes depuis ce meme appareil n'aient
// plus besoin de code.
//
// Ce fichier ne contient que l'enveloppe. La decision d'accepter ou de
// refuser un code — expiration, compteur de tentatives, comparaison des
// empreintes, ordre des ecritures — est dans
// ../_logique/codes_verification.mts, ou elle est testee sans base.
//
// Necessite un appelant authentifie : deployee AVEC verification JWT.
//   supabase functions deploy verifier-code
//
// Memes variables d'environnement Supabase que "envoyer-code-
// verification" (BREVO_* non necessaires ici).

import {
  enTeteAutorisation,
  estPreflight,
  lireCorpsJson,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import { lireConfigurationBase } from '../_enveloppe/environnement.mts';

import {
  clientServiceRole,
  identifierAppelant,
} from '../_enveloppe/supabase.mts';

import { depotCodesSupabase } from '../_enveloppe/depot_codes.mts';

import {
  CODE_INVALIDE,
  jetonAppareilValide,
  verifierCode,
} from '../_logique/codes_verification.mts';

Deno.serve(async (req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  const base = lireConfigurationBase();

  if (!base) {
    console.error('Variable d’environnement Supabase manquante.');
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

  const code = corps.code;
  const jetonAppareilHash = corps.jetonAppareilHash;
  const nomAppareil = corps.nomAppareil;

  if (
    typeof code !== 'string' ||
    !jetonAppareilValide(jetonAppareilHash)
  ) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  const resultat = await verifierCode(
    depotCodesSupabase(clientServiceRole(base)),
    {
      userId: appelant.id,
      code,
      jetonAppareilHash,
      nomAppareil:
        typeof nomAppareil === 'string' ? nomAppareil : null,
    },
    new Date(),
  );

  switch (resultat.statut) {
    case 'accepte':
      return reponseJson({ ok: true }, 200);

    case 'refuse':
      return reponseJson({ error: CODE_INVALIDE }, 400);

    case 'erreurBase':
      return reponseJson({ error: CODE_INVALIDE }, 500);

    case 'echecValidation':
      return reponseJson(
        { error: 'Impossible de valider le code.' },
        500,
      );

    case 'echecAppareil':
      return reponseJson(
        { error: 'Impossible d’enregistrer l’appareil.' },
        500,
      );
  }
});
