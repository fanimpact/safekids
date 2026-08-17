// Edge Function "envoyer-code-verification"
//
// Appelee par l'app juste apres qu'un mot de passe a ete valide, quand
// l'appareil utilise n'est pas dans "appareils_reconnus" pour ce
// compte. Genere un code a 6 chiffres, le stocke hache (jamais en
// clair) dans "codes_verification" avec une expiration courte, et
// l'envoie par email via Brevo.
//
// Necessite un appelant authentifie (le mot de passe a deja ete
// verifie par Supabase Auth avant cet appel) : deployee AVEC
// verification JWT (pas de --no-verify-jwt).
//   supabase functions deploy envoyer-code-verification
//
// Variables d'environnement requises (Supabase -> Project Settings ->
// Edge Functions -> Secrets) :
//   BREVO_API_KEY      cle API Brevo (jamais dans le code)
//   BREVO_SENDER_EMAIL adresse expediteur verifiee dans Brevo
//   BREVO_SENDER_NAME  nom affiche comme expediteur (ex. "SafeKids")

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const CODE_VALIDE_MINUTES = 10;

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function genererCode(): string {
  const bytes = new Uint32Array(1);
  crypto.getRandomValues(bytes);
  // 6 chiffres, toujours avec les zeros de tete conserves.
  return String(bytes[0] % 1_000_000).padStart(6, '0');
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
  const brevoApiKey = Deno.env.get('BREVO_API_KEY');
  const brevoSenderEmail = Deno.env.get(
    'BREVO_SENDER_EMAIL',
  );
  const brevoSenderName =
    Deno.env.get('BREVO_SENDER_NAME') ?? 'SafeKids';

  if (
    !supabaseUrl ||
    !anonKey ||
    !serviceRoleKey ||
    !brevoApiKey ||
    !brevoSenderEmail
  ) {
    console.error(
      'Variable d’environnement manquante (Supabase ou Brevo).',
    );
    return jsonResponse(
      { error: 'Configuration serveur incomplete.' },
      500,
    );
  }

  const authHeader = req.headers.get('Authorization');

  if (!authHeader) {
    return jsonResponse({ error: 'Non authentifie.' }, 401);
  }

  // Client "au nom de l'appelant" : sert uniquement a identifier
  // l'utilisateur a partir de son jeton, jamais a lire/ecrire les
  // tables sensibles (ca reste le role du client service_role).
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

  let jetonAppareilHash: unknown;

  try {
    const body = await req.json();
    jetonAppareilHash = body?.jetonAppareilHash;
  } catch {
    return jsonResponse(
      { error: 'Requete invalide.' },
      400,
    );
  }

  if (
    typeof jetonAppareilHash !== 'string' ||
    jetonAppareilHash.length < 32
  ) {
    return jsonResponse(
      { error: 'Requete invalide.' },
      400,
    );
  }

  const email = userData.user.email;

  if (!email) {
    return jsonResponse(
      { error: 'Compte sans adresse email.' },
      400,
    );
  }

  const code = genererCode();
  const codeHash = await hacher(code);

  const supabaseService = createClient(
    supabaseUrl,
    serviceRoleKey,
  );

  const expireLe = new Date(
    Date.now() + CODE_VALIDE_MINUTES * 60_000,
  ).toISOString();

  const { error: insertError } = await supabaseService
    .from('codes_verification')
    .insert({
      user_id: userData.user.id,
      code_hash: codeHash,
      jeton_appareil_hash: jetonAppareilHash,
      expire_le: expireLe,
    });

  if (insertError) {
    console.error(insertError);
    return jsonResponse(
      { error: 'Impossible de generer le code.' },
      500,
    );
  }

  // Contrainte de contenu : jamais de donnee de sante, jamais de nom
  // de famille d'enfant dans un email envoye par cette fonctionnalite.
  const brevoResponse = await fetch(
    'https://api.brevo.com/v3/smtp/email',
    {
      method: 'POST',
      headers: {
        'api-key': brevoApiKey,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        sender: {
          email: brevoSenderEmail,
          name: brevoSenderName,
        },
        to: [{ email }],
        subject: 'Votre code de vérification SafeKids',
        htmlContent:
          `<p>Nouvel appareil détecté sur votre compte SafeKids.</p>` +
          `<p>Votre code de vérification : ` +
          `<strong style="font-size:20px">${code}</strong></p>` +
          `<p>Ce code est valable ${CODE_VALIDE_MINUTES} minutes. ` +
          `Si vous n’êtes pas à l’origine de cette ` +
          `connexion, ignorez cet email.</p>`,
      }),
    },
  );

  if (!brevoResponse.ok) {
    console.error(
      'Echec envoi Brevo',
      brevoResponse.status,
      await brevoResponse.text(),
    );
    return jsonResponse(
      { error: 'Impossible d’envoyer le code.' },
      502,
    );
  }

  return jsonResponse({ ok: true }, 200);
});
