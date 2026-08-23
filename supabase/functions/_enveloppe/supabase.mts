// Acces au SDK Supabase.
//
// C'est le seul fichier du dossier `functions/` qui importe le SDK, et
// le seul qui sait qu'on parle a Supabase. Les modules de `_logique/`
// n'en connaissent rien : ils recoivent des interfaces (voir les
// `Depot*` de chaque module) dont les implementations vivent ici ou
// dans l'enveloppe de chaque fonction.
//
// L'import vient d'esm.sh, la CDN utilisee par Deno. Hors de Supabase,
// c'est le premier point a changer : un environnement Node prendrait
// le paquet npm, un autre moteur son equivalent.

import {
  createClient,
  type SupabaseClient,
} from 'https://esm.sh/@supabase/supabase-js@2';

import type { ConfigurationBase } from './environnement.mts';

export type { SupabaseClient };

/// Client "au nom de l'appelant" : sert uniquement a identifier
/// l'utilisateur a partir de son jeton, jamais a lire ou ecrire les
/// tables sensibles — c'est le role du client service_role.
export function clientAuNomDeLAppelant(
  configuration: Pick<ConfigurationBase, 'url' | 'cleAnonyme'>,
  jetonAutorisation: string,
): SupabaseClient {
  return createClient(
    configuration.url,
    configuration.cleAnonyme,
    {
      global: {
        headers: { Authorization: jetonAutorisation },
      },
    },
  );
}

/// Client qui contourne le RLS. Tout controle de droit qui reposait sur
/// le RLS doit donc etre refait explicitement dans la logique.
export function clientServiceRole(
  configuration: Pick<
    ConfigurationBase,
    'url' | 'cleServiceRole'
  >,
): SupabaseClient {
  return createClient(
    configuration.url,
    configuration.cleServiceRole,
  );
}

export interface Appelant {
  id: string;
  email: string | null;
}

/// `null` couvre les trois cas que les fonctions traitent de la meme
/// facon : pas d'en-tete, jeton refuse, ou aucun utilisateur derriere
/// le jeton. Toutes repondent "Non authentifie." avec un statut 401.
export async function identifierAppelant(
  configuration: Pick<ConfigurationBase, 'url' | 'cleAnonyme'>,
  jetonAutorisation: string,
): Promise<Appelant | null> {
  const client = clientAuNomDeLAppelant(
    configuration,
    jetonAutorisation,
  );

  const { data, error } = await client.auth.getUser();

  if (error || !data.user) {
    return null;
  }

  return {
    id: data.user.id,
    email: data.user.email ?? null,
  };
}
