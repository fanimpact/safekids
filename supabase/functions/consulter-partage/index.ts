// Edge Function "consulter-partage"
//
// Accessible sans authentification (c'est tout l'intérêt du lien de
// partage). Reçoit un token en paramètre d'URL, vérifie sa validité,
// et renvoie uniquement les données de l'enfant lié à CE token — jamais
// d'autre enfant, même si le client fournissait un autre identifiant
// (l'enfant_id n'est jamais lu depuis la requête, seulement via la
// ligne "partages" trouvée par token).
//
// Utilise la clé service_role (variable d'environnement fournie
// automatiquement par Supabase à l'exécution) pour pouvoir lire les
// données malgré le RLS, puisque l'appelant n'est pas authentifié.
//
// Ce fichier ne contient que l'enveloppe. La validité du lien, le choix
// des données à charger selon le type de fiche et la forme de la
// réponse sont dans ../_logique/partage_consultation.mts, où ils sont
// testés sans base.
//
// Déploiement : cette fonction doit être publiée avec la vérification
// JWT désactivée, sinon Supabase exigera un en-tête d'autorisation que
// l'accompagnant (non connecté) n'a pas :
//   supabase functions deploy consulter-partage --no-verify-jwt

import {
  estPreflight,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import { lireConfigurationBaseServiceSeul } from '../_enveloppe/environnement.mts';

import { clientServiceRole } from '../_enveloppe/supabase.mts';

import { depotPartagesSupabase } from '../_enveloppe/depot_partages.mts';

import {
  LIEN_INVALIDE,
  consulterPartage,
} from '../_logique/partage_consultation.mts';

function erreur(statut: number) {
  return reponseJson({ error: LIEN_INVALIDE }, statut);
}

Deno.serve(async (req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  let token: string | null;

  try {
    token = new URL(req.url).searchParams.get('token');
  } catch {
    return erreur(400);
  }

  if (!token) {
    return erreur(400);
  }

  const base = lireConfigurationBaseServiceSeul();

  if (!base) {
    console.error(
      'SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant.',
    );
    return erreur(500);
  }

  const resultat = await consulterPartage(
    depotPartagesSupabase(clientServiceRole(base)),
    token,
    new Date(),
  );

  switch (resultat.statut) {
    case 'ok':
      return reponseJson(resultat.fiche, 200);

    // Token inconnu : même message que "expiré", pour ne pas
    // laisser deviner si un token a existé ou non.
    case 'tokenAbsent':
      return erreur(400);

    case 'tokenInconnu':
      return erreur(404);

    case 'lienExpire':
      return erreur(410);

    case 'enfantIntrouvable':
      return erreur(404);

    case 'erreurBase':
      return erreur(500);
  }
});
