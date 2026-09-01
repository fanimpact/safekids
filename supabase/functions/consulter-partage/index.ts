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
  lireCorpsJson,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import { lireConfigurationBaseServiceSeul } from '../_enveloppe/environnement.mts';

import { clientServiceRole } from '../_enveloppe/supabase.mts';

import { depotPartagesSupabase } from '../_enveloppe/depot_partages.mts';

import {
  LIEN_INVALIDE,
  CODE_EXPIRE,
  TROIS_APPAREILS_ATTEINTS,
  TROP_DE_DEMANDES,
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
  let secretPresente: string | null = null;
  let raisonDemande: string | null = null;

  try {
    const parametres = new URL(req.url).searchParams;

    token = parametres.get('token');

    // Le secret que l'appareil a garde de sa premiere ouverture. Nul
    // la premiere fois, et nul aussi pour quelqu'un a qui le lien a
    // ete transfere.
    secretPresente = parametres.get('secret');

    // La raison passe par le CORPS d'un POST, jamais par l'adresse.
    //
    // Une adresse se retrouve dans les journaux d'acces du serveur ;
    // ce champ est ecrit par une personne inconnue et peut contenir
    // n'importe quoi. Il n'a rien a faire dans un journal.
    if (req.method === 'POST') {
      const corps = await lireCorpsJson(req);

      if (corps && typeof corps === 'object') {
        const brut = (corps as Record<string, unknown>).raison;
        raisonDemande = typeof brut === 'string' ? brut : null;
      }
    }
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
    { secretPresente, raisonDemande },
  );

  switch (resultat.statut) {
    case 'ok':
      // `secret` n'accompagne la fiche qu'a la pose ou a la reprise du
      // verrou. La page le range et le represente aux ouvertures
      // suivantes.
      return reponseJson(
        resultat.secret
          ? { ...resultat.fiche, secret: resultat.secret }
          : resultat.fiche,
        200,
      );

    // Token inconnu : même message que "expiré", pour ne pas
    // laisser deviner si un token a existé ou non.
    case 'tokenAbsent':
      return erreur(400);

    case 'tokenInconnu':
      return erreur(404);

    case 'lienExpire':
      return erreur(410);

    // Meme message et meme code qu'un lien expire : dire « revoque »
    // apprendrait a qui detient le lien que le parent a coupe l'acces
    // volontairement, ce qui ne le regarde pas. Le parent, lui, le voit
    // dans sa liste.
    case 'lienRevoque':
      return erreur(410);

    // Trois appareils sont pris. Ce n'est pas un refus definitif :
    // la personne dit qui elle est, et le parent decide. Le code 423
    // est conserve, la page le reconnait deja.
    //
    // `secret` accompagne la reponse pour que la page le range :
    // sans lui, la personne reviendrait en inconnue et sa demande
    // serait orpheline. Il ne donne aucun acces.
    case 'demandeRequise':
      return reponseJson(
        {
          error: TROIS_APPAREILS_ATTEINTS,
          code: 'demande_requise',
          secret: resultat.secret,
        },
        423,
      );

    case 'demandeEnAttente':
      return reponseJson(
        {
          error: TROIS_APPAREILS_ATTEINTS,
          code: 'demande_en_attente',
        },
        423,
      );

    case 'demandeEnregistree':
      return reponseJson({ code: 'demande_enregistree' }, 202);

    case 'tropDeDemandes':
      return reponseJson(
        { error: TROP_DE_DEMANDES, code: 'trop_de_demandes' },
        429,
      );

    // Meme raison : celui qui vient de scanner n'a rien fait de mal,
    // et le parent est a cote de lui. Lui dire d'en demander un
    // nouveau lui epargne de croire a une panne.
    //
    // 410 comme un lien expire : c'est bien une ressource qui a
    // cesse d'exister, pas un refus d'acces.
    case 'codeExpire':
      // `code` en plus du texte : la page ne peut pas deviner, a
      // partir d'un 410, si elle doit dire « demandez un nouveau
      // lien » ou « demandez un nouveau code ». Un champ lisible
      // par la machine vaut mieux qu'un code HTTP detourne.
      return reponseJson(
        { error: CODE_EXPIRE, code: 'code_expire' },
        410,
      );

    case 'enfantIntrouvable':
      return erreur(404);

    case 'erreurBase':
      return erreur(500);
  }
});
