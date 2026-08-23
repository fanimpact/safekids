// Enveloppe HTTP des Edge Functions.
//
// Ce que toutes les fonctions font pareil autour de leur logique :
// en-tetes CORS, requete de preflight, reponse JSON, lecture du corps.
// Rien ici ne connait le metier de KidsRelay.
//
// Le contenu de ce fichier est du HTTP standard, pas du Supabase : il
// resterait valable tel quel derriere un autre hebergeur. Ce qui est
// propre a Supabase vit dans `environnement.mts` et `supabase.mts`.

export const enTetesCors: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

export function estPreflight(requete: Request): boolean {
  return requete.method === 'OPTIONS';
}

export function reponsePreflight(): Response {
  return new Response('ok', { headers: enTetesCors });
}

export function reponseJson(
  corps: unknown,
  statut: number,
): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: {
      ...enTetesCors,
      'Content-Type': 'application/json',
    },
  });
}

export function reponseHtml(html: string): Response {
  return new Response(html, {
    headers: {
      ...enTetesCors,
      'Content-Type': 'text/html; charset=utf-8',
    },
  });
}

/// Renvoie `null` si le corps n'est pas du JSON exploitable, pour que
/// l'appelant reponde "Requete invalide." sans avoir a intercepter
/// l'exception lui-meme.
export async function lireCorpsJson(
  requete: Request,
): Promise<Record<string, unknown> | null> {
  try {
    const corps = await requete.json();

    return corps && typeof corps === 'object'
      ? corps as Record<string, unknown>
      : null;
  } catch {
    return null;
  }
}

/// Jeton d'appel brut, tel que transmis par le client. Absent quand la
/// fonction est deployee sans verification JWT et appelee par un
/// accompagnant non connecte.
export function enTeteAutorisation(
  requete: Request,
): string | null {
  return requete.headers.get('Authorization');
}
