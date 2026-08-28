// Edge Function "declencher-acces-secours"
//
// Ouvre un accès secours de 24 heures sur la fiche secours d'un enfant,
// à la demande de la personne qui détient déjà un lien de partage — et
// **sans attendre la réponse du parent**.
//
// C'est le seul geste de KidsRelay qui donne un accès à des données de
// santé sans décision humaine au moment même. Il n'est possible que si
// le parent l'a préautorisé à froid, à la création du partage, et le
// parent est prévenu immédiatement.
//
// Accessible sans authentification, comme `consulter-partage` : celui
// qui déclenche est une maîtresse qui tient un lien, pas un titulaire
// de compte.
//
// Déploiement :
//   supabase functions deploy declencher-acces-secours --no-verify-jwt

import {
  estPreflight,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import { lireConfigurationBaseServiceSeul } from '../_enveloppe/environnement.mts';

import { clientServiceRole } from '../_enveloppe/supabase.mts';

import { depotPartagesSupabase } from '../_enveloppe/depot_partages.mts';

import { declencherAccesSecours } from '../_logique/acces_secours.mts';

/// Un seul message pour tous les refus qui touchent au lien lui-même.
/// Distinguer « inconnu », « expiré » et « révoqué » apprendrait à
/// l'appelant ce qu'il n'a pas à savoir.
const LIEN_INDISPONIBLE =
  'Ce lien ne permet pas d’ouvrir un accès secours.';

/// Distinct du précédent, et c'est voulu : ici le lien est bon, mais le
/// parent n'a pas donné cette autorisation. La personne doit
/// comprendre qu'il n'y a rien à réessayer.
const NON_AUTORISE =
  'Le parent n’a pas activé l’accès secours pour ce partage. ' +
  'Contactez-le, ou montrez la fiche depuis votre écran.';

Deno.serve(async (req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  let token: string | null;
  let secret: string | null;

  try {
    const parametres = new URL(req.url).searchParams;

    token = parametres.get('token');
    secret = parametres.get('secret');
  } catch {
    return reponseJson({ error: LIEN_INDISPONIBLE }, 400);
  }

  const base = lireConfigurationBaseServiceSeul();

  if (!base) {
    console.error(
      'SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant.',
    );

    return reponseJson({ error: LIEN_INDISPONIBLE }, 500);
  }

  const resultat = await declencherAccesSecours(
    depotPartagesSupabase(clientServiceRole(base)),
    token,
    secret,
    new Date(),
  );

  switch (resultat.statut) {
    case 'ok':
      return reponseJson(
        {
          token: resultat.acces.token,
          expire_le: resultat.acces.expireLe,
        },
        200,
      );

    case 'nonAutorise':
      return reponseJson({ error: NON_AUTORISE }, 403);

    // « Pas détenteur » répond comme un lien indisponible : dire à
    // quelqu'un qui n'a pas le lien que le lien existe lui apprendrait
    // déjà quelque chose.
    case 'pasDetenteur':
      return reponseJson({ error: LIEN_INDISPONIBLE }, 403);

    case 'tokenAbsent':
      return reponseJson({ error: LIEN_INDISPONIBLE }, 400);

    case 'tokenInconnu':
    case 'lienFini':
      return reponseJson({ error: LIEN_INDISPONIBLE }, 410);

    case 'erreurBase':
      return reponseJson({ error: LIEN_INDISPONIBLE }, 500);
  }
});
