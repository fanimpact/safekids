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
// Déploiement : cette fonction doit être publiée avec la vérification
// JWT désactivée, sinon Supabase exigera un en-tête d'autorisation que
// l'accompagnant (non connecté) n'a pas :
//   supabase functions deploy consulter-partage --no-verify-jwt

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const LIEN_INVALIDE = 'Lien expiré ou invalide.';

function jsonResponse(
  body: unknown,
  status: number,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function erreur(status: number) {
  return jsonResponse({ error: LIEN_INVALIDE }, status);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  let token: string | null;

  try {
    const url = new URL(req.url);
    token = url.searchParams.get('token');
  } catch {
    return erreur(400);
  }

  if (!token) {
    return erreur(400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  );

  if (!supabaseUrl || !serviceRoleKey) {
    console.error(
      'SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant.',
    );
    return erreur(500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: partage, error: partageError } =
    await supabase
      .from('partages')
      .select(
        'id, enfant_id, type_fiche, date_expiration, contenu_fige',
      )
      .eq('token', token)
      .maybeSingle();

  if (partageError) {
    console.error(partageError);
    return erreur(500);
  }

  // Token inconnu : même message que "expiré", pour ne pas
  // laisser deviner si un token a existé ou non.
  if (!partage) {
    return erreur(404);
  }

  const dateExpiration = new Date(
    partage.date_expiration,
  );

  if (
    Number.isNaN(dateExpiration.getTime()) ||
    dateExpiration.getTime() < Date.now()
  ) {
    return erreur(410);
  }

  const { data: enfant, error: enfantError } =
    await supabase
      .from('enfants')
      .select(
        'id, prenom, nom, date_naissance, poids, taille, date_maj_poids',
      )
      .eq('id', partage.enfant_id)
      .maybeSingle();

  if (enfantError || !enfant) {
    console.error(enfantError);
    return erreur(404);
  }

  // "recommandations_activite" est une photo figée au moment du
  // partage (contenu_fige) : jamais recalculée ici, le moteur de
  // recommandations n'existe qu'en Dart/Flutter. Les profils santé et
  // activités ne sont donc pas nécessaires pour ce type de fiche.
  let profilSante = null;
  let profilActivites = null;

  if (partage.type_fiche !== 'recommandations_activite') {
    const { data: profilSanteRow } = await supabase
      .from('profils_sante')
      .select('*')
      .eq('enfant_id', partage.enfant_id)
      .maybeSingle();

    const { data: profilActivitesRow } = await supabase
      .from('profils_activites')
      .select('*')
      .eq('enfant_id', partage.enfant_id)
      .maybeSingle();

    profilSante = profilSanteRow ?? null;
    profilActivites = profilActivitesRow ?? null;
  }

  // Mise à jour de la date de dernière consultation. Une erreur ici
  // ne doit pas empêcher de renvoyer la fiche à l'accompagnant.
  const { error: updateError } = await supabase
    .from('partages')
    .update({
      date_derniere_consultation:
        new Date().toISOString(),
    })
    .eq('id', partage.id);

  if (updateError) {
    console.error(updateError);
  }

  return jsonResponse(
    {
      type_fiche: partage.type_fiche,
      enfant,
      profil_sante: profilSante,
      profil_activites: profilActivites,
      contenu_fige: partage.contenu_fige ?? null,
    },
    200,
  );
});
