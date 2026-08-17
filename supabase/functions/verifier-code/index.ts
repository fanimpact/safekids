// Edge Function "verifier-code"
//
// Verifie le code a 6 chiffres envoye par "envoyer-code-verification".
// En cas de succes, enregistre l'appareil dans "appareils_reconnus"
// pour que les connexions suivantes depuis ce meme appareil n'aient
// plus besoin de code.
//
// Necessite un appelant authentifie : deployee AVEC verification JWT.
//   supabase functions deploy verifier-code
//
// Memes variables d'environnement Supabase que "envoyer-code-
// verification" (BREVO_* non necessaires ici).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const TENTATIVES_MAX = 5;

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

async function hacher(valeur: string): Promise<string> {
  const donnees = new TextEncoder().encode(valeur);
  const empreinte = await crypto.subtle.digest(
    'SHA-256',
    donnees,
  );

  return Array.from(new Uint8Array(empreinte))
    .map((octet) => octet.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  );

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error('Variable d’environnement Supabase manquante.');
    return jsonResponse(
      { error: 'Configuration serveur incomplete.' },
      500,
    );
  }

  const authHeader = req.headers.get('Authorization');

  if (!authHeader) {
    return jsonResponse({ error: 'Non authentifie.' }, 401);
  }

  const supabaseAppelant = createClient(
    supabaseUrl,
    anonKey,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: userData, error: userError } =
    await supabaseAppelant.auth.getUser();

  if (userError || !userData.user) {
    return jsonResponse({ error: 'Non authentifie.' }, 401);
  }

  let code: unknown;
  let jetonAppareilHash: unknown;
  let nomAppareil: unknown;

  try {
    const body = await req.json();
    code = body?.code;
    jetonAppareilHash = body?.jetonAppareilHash;
    nomAppareil = body?.nomAppareil;
  } catch {
    return jsonResponse({ error: 'Requete invalide.' }, 400);
  }

  if (
    typeof code !== 'string' ||
    typeof jetonAppareilHash !== 'string' ||
    jetonAppareilHash.length < 32
  ) {
    return jsonResponse({ error: 'Requete invalide.' }, 400);
  }

  const supabaseService = createClient(
    supabaseUrl,
    serviceRoleKey,
  );

  const { data: ligne, error: selectError } =
    await supabaseService
      .from('codes_verification')
      .select(
        'id, code_hash, expire_le, utilise_le, tentatives',
      )
      .eq('user_id', userData.user.id)
      .eq('jeton_appareil_hash', jetonAppareilHash)
      .is('utilise_le', null)
      .order('cree_le', { ascending: false })
      .limit(1)
      .maybeSingle();

  if (selectError) {
    console.error(selectError);
    return jsonResponse(
      { error: 'Code invalide ou expire.' },
      500,
    );
  }

  const CODE_INVALIDE = 'Code invalide ou expire.';

  if (!ligne) {
    return jsonResponse({ error: CODE_INVALIDE }, 400);
  }

  if (
    new Date(ligne.expire_le).getTime() < Date.now() ||
    ligne.tentatives >= TENTATIVES_MAX
  ) {
    return jsonResponse({ error: CODE_INVALIDE }, 400);
  }

  const codeHash = await hacher(code);

  if (codeHash !== ligne.code_hash) {
    await supabaseService
      .from('codes_verification')
      .update({ tentatives: ligne.tentatives + 1 })
      .eq('id', ligne.id);

    return jsonResponse({ error: CODE_INVALIDE }, 400);
  }

  const { error: updateError } = await supabaseService
    .from('codes_verification')
    .update({ utilise_le: new Date().toISOString() })
    .eq('id', ligne.id);

  if (updateError) {
    console.error(updateError);
    return jsonResponse(
      { error: 'Impossible de valider le code.' },
      500,
    );
  }

  const { error: upsertError } = await supabaseService
    .from('appareils_reconnus')
    .upsert(
      {
        user_id: userData.user.id,
        jeton_hash: jetonAppareilHash,
        nom_appareil:
          typeof nomAppareil === 'string'
            ? nomAppareil
            : null,
        derniere_utilisation_le:
          new Date().toISOString(),
      },
      { onConflict: 'user_id,jeton_hash' },
    );

  if (upsertError) {
    console.error(upsertError);
    return jsonResponse(
      { error: 'Impossible d’enregistrer l’appareil.' },
      500,
    );
  }

  return jsonResponse({ ok: true }, 200);
});
