// Edge Function "notifier-note-ajoutee"
//
// Appelee par l'app juste apres qu'un membre du personnel a enregistre
// une note rattachee a une activite ET a un enfant en particulier
// (jamais pour une note generale au groupe, enfant_id null : celle-ci
// n'est envoyee a personne). Retrouve cote serveur le prenom de
// l'enfant, le nom de l'etablissement et l'email du parent -- jamais
// transmis par le client, pour garantir qu'aucune donnee sensible ne
// peut etre injectee dans l'email envoye.
//
// Point d'entree unique pour toute notification parent (2026-08-19,
// demande de Fanny en preparation des notifications push, prevues au
// moment de la publication sur les stores) : chaque appel cree
// d'abord une ligne dans evenements_notification_parent (statut
// "en_attente"), envoie l'email, puis met a jour cette meme ligne
// ("envoye"/"echoue"). Quand le canal push sera branche, il lira/
// ecrira sur la meme table plutot que de dupliquer cette logique.
//
// Necessite un appelant authentifie, membre actif de l'etablissement
// proprietaire de l'activite : deployee AVEC verification JWT (pas de
// --no-verify-jwt).
//   supabase functions deploy notifier-note-ajoutee
//
// Variables d'environnement requises (Supabase -> Project Settings ->
// Edge Functions -> Secrets) :
//   BREVO_API_KEY        cle API Brevo (jamais dans le code)
//   BREVO_SENDER_EMAIL   adresse expediteur verifiee dans Brevo
//   BREVO_SENDER_NAME    nom affiche comme expediteur (ex. "SafeKids")
//   BREVO_REPLY_TO_EMAIL optionnelle : adresse de reponse si differente
//                        de l'expediteur (sinon, BREVO_SENDER_EMAIL
//                        sert aussi de reply-to)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
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
  const brevoReplyToEmail =
    Deno.env.get('BREVO_REPLY_TO_EMAIL') ?? brevoSenderEmail;

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
  // l'utilisateur a partir de son jeton.
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

  let enfantId: unknown;
  let activiteId: unknown;

  try {
    const body = await req.json();
    enfantId = body?.enfantId;
    activiteId = body?.activiteId;
  } catch {
    return jsonResponse(
      { error: 'Requete invalide.' },
      400,
    );
  }

  if (
    typeof enfantId !== 'string' ||
    typeof activiteId !== 'string'
  ) {
    return jsonResponse(
      { error: 'Requete invalide.' },
      400,
    );
  }

  const supabaseService = createClient(
    supabaseUrl,
    serviceRoleKey,
  );

  const { data: activite, error: activiteError } =
    await supabaseService
      .from('activites_preparees')
      .select('etablissement_id, enfants_ids')
      .eq('id', activiteId)
      .maybeSingle();

  if (activiteError || !activite?.etablissement_id) {
    return jsonResponse(
      { error: 'Activite introuvable.' },
      404,
    );
  }

  const enfantsIds: unknown = activite.enfants_ids;

  if (
    !Array.isArray(enfantsIds) ||
    !enfantsIds.includes(enfantId)
  ) {
    return jsonResponse(
      { error: 'Cet enfant ne fait pas partie de cette activite.' },
      400,
    );
  }

  // Verifie que l'appelant est bien membre actif de l'etablissement
  // proprietaire de l'activite (le service_role contourne le RLS, donc
  // ce controle doit etre refait explicitement ici).
  const { data: membre } = await supabaseService
    .from('membres_etablissement')
    .select('id')
    .eq('etablissement_id', activite.etablissement_id)
    .eq('user_id', userData.user.id)
    .eq('statut', 'actif')
    .maybeSingle();

  if (!membre) {
    return jsonResponse(
      { error: 'Vous n’etes pas membre actif de cet etablissement.' },
      403,
    );
  }

  const { data: enfant } = await supabaseService
    .from('enfants')
    .select('prenom, parent_id')
    .eq('id', enfantId)
    .maybeSingle();

  if (!enfant?.parent_id) {
    return jsonResponse(
      { error: 'Enfant introuvable.' },
      404,
    );
  }

  const { data: etablissement } = await supabaseService
    .from('etablissements')
    .select('nom')
    .eq('id', activite.etablissement_id)
    .maybeSingle();

  const { data: compteParent } = await supabaseService
    .from('comptes_parents')
    .select('email')
    .eq('id', enfant.parent_id)
    .maybeSingle();

  const emailParent = compteParent?.email;

  // La ligne d'evenement est creee avant toute tentative d'envoi,
  // qu'un email exploitable existe ou non -- c'est elle qui fait foi
  // de "cette notification a ete declenchee", independamment du canal.
  const { data: evenement, error: evenementError } =
    await supabaseService
      .from('evenements_notification_parent')
      .insert({
        parent_id: enfant.parent_id,
        enfant_id: enfantId,
        type_evenement: 'note_ajoutee',
        donnees: {
          activiteId,
          etablissementId: activite.etablissement_id,
        },
      })
      .select('id')
      .single();

  if (evenementError || !evenement) {
    console.error(
      'Impossible de creer l’evenement de notification',
      evenementError,
    );
    return jsonResponse(
      { error: 'Impossible de journaliser la notification.' },
      500,
    );
  }

  if (!emailParent) {
    await supabaseService
      .from('evenements_notification_parent')
      .update({ statut_email: 'echoue' })
      .eq('id', evenement.id);

    // Rien a notifier, mais la note reste bien enregistree cote base
    // (deja fait avant cet appel) : ce n'est pas une erreur bloquante.
    return jsonResponse({ ok: true, notifie: false }, 200);
  }

  const prenom = enfant.prenom ?? 'Votre enfant';
  const nomEtablissement = etablissement?.nom ?? 'l’établissement';

  // Contrainte de contenu : jamais de donnee de sante, jamais le nom
  // de famille de l'enfant, jamais le texte de la note elle-meme dans
  // un email envoye par cette fonctionnalite.
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
        replyTo: { email: brevoReplyToEmail },
        to: [{ email: emailParent }],
        subject: 'Une note a été ajoutée sur SafeKids',
        htmlContent:
          `<p>Une note a été ajoutée sur le profil de ` +
          `${prenom} par ${nomEtablissement}.</p>` +
          `<p>Connectez-vous à l’application SafeKids pour la consulter.</p>`,
      }),
    },
  );

  if (!brevoResponse.ok) {
    console.error(
      'Echec envoi Brevo',
      brevoResponse.status,
      await brevoResponse.text(),
    );

    await supabaseService
      .from('evenements_notification_parent')
      .update({ statut_email: 'echoue' })
      .eq('id', evenement.id);

    return jsonResponse(
      { error: 'Impossible d’envoyer la notification.' },
      502,
    );
  }

  await supabaseService
    .from('evenements_notification_parent')
    .update({
      statut_email: 'envoye',
      email_envoye_le: new Date().toISOString(),
    })
    .eq('id', evenement.id);

  return jsonResponse({ ok: true, notifie: true }, 200);
});
