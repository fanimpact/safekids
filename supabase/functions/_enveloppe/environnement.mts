// Lecture des variables d'environnement.
//
// Ce fichier est le seul endroit qui sait que les variables Supabase
// sont injectees automatiquement a l'execution (SUPABASE_URL,
// SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY) et n'apparaissent donc
// nulle part dans la configuration du projet. Hors de Supabase, ces
// trois-la deviendraient des secrets a fournir explicitement.
//
// Les variables BREVO_* sont, elles, deja des secrets declares a la
// main : elles ne changeraient pas d'hebergeur en hebergeur.

export interface ConfigurationBase {
  url: string;
  cleAnonyme: string;
  cleServiceRole: string;
}

export interface ConfigurationEmail {
  cleApi: string;
  expediteurEmail: string;
  expediteurNom: string;
  repondreAEmail: string;
}

/// `null` si une variable manque : l'appelant repond alors
/// "Configuration serveur incomplete." avec un statut 500.
export function lireConfigurationBase(): ConfigurationBase | null {
  const url = Deno.env.get('SUPABASE_URL');
  const cleAnonyme = Deno.env.get('SUPABASE_ANON_KEY');
  const cleServiceRole = Deno.env.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  );

  if (!url || !cleAnonyme || !cleServiceRole) {
    return null;
  }

  return { url, cleAnonyme, cleServiceRole };
}

/// Variante pour les fonctions publiques, qui n'identifient personne et
/// n'ont donc pas besoin de la cle anonyme.
export function lireConfigurationBaseServiceSeul():
  | Pick<ConfigurationBase, 'url' | 'cleServiceRole'>
  | null {
  const url = Deno.env.get('SUPABASE_URL');
  const cleServiceRole = Deno.env.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  );

  if (!url || !cleServiceRole) {
    return null;
  }

  return { url, cleServiceRole };
}

export function lireConfigurationEmail():
  | ConfigurationEmail
  | null {
  const cleApi = Deno.env.get('BREVO_API_KEY');
  const expediteurEmail = Deno.env.get('BREVO_SENDER_EMAIL');

  if (!cleApi || !expediteurEmail) {
    return null;
  }

  return {
    cleApi,
    expediteurEmail,
    expediteurNom:
      Deno.env.get('BREVO_SENDER_NAME') ?? 'KidsRelay',
    repondreAEmail:
      Deno.env.get('BREVO_REPLY_TO_EMAIL') ?? expediteurEmail,
  };
}
