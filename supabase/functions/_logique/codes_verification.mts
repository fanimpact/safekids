// Codes de verification a 6 chiffres, envoyes quand un compte est
// utilise depuis un appareil inconnu.
//
// Aucun import Deno, aucun SDK, aucun appel reseau : les acces base
// entrent par `DepotCodes`, l'horloge par `maintenant`. C'est ce qui
// rend ce fichier executable par `node --test` sans base ni reseau, et
// deplacable tel quel sous un autre hebergeur.
//
// Deux regles de securite tiennent ici et nulle part ailleurs :
//   - le code n'est jamais stocke en clair, seulement son empreinte ;
//   - un code faux incremente un compteur, et au-dela de
//     TENTATIVES_MAX le code est mort meme s'il n'a pas expire.

export const CODE_VALIDE_MINUTES = 10;
export const TENTATIVES_MAX = 5;

/// Meme message pour "code faux", "code expire", "trop de tentatives"
/// et "aucun code en cours" : donner le detail reviendrait a aider
/// quelqu'un qui essaie des codes au hasard.
export const CODE_INVALIDE = 'Code invalide ou expire.';

export interface CodeEnCours {
  id: string;
  code_hash: string;
  expire_le: string;
  tentatives: number;
}

/// Ce dont la logique a besoin de la base, et rien de plus.
/// L'implementation Supabase vit dans l'enveloppe de chaque fonction.
export interface DepotCodes {
  enregistrerCode(entree: {
    userId: string;
    codeHash: string;
    jetonAppareilHash: string;
    expireLe: string;
  }): Promise<{ erreur: unknown }>;

  dernierCodeNonUtilise(
    userId: string,
    jetonAppareilHash: string,
  ): Promise<{ ligne: CodeEnCours | null; erreur: unknown }>;

  incrementerTentatives(
    id: string,
    tentatives: number,
  ): Promise<void>;

  marquerUtilise(
    id: string,
    horodatage: string,
  ): Promise<{ erreur: unknown }>;

  enregistrerAppareil(entree: {
    userId: string;
    jetonHash: string;
    nomAppareil: string | null;
    derniereUtilisationLe: string;
  }): Promise<{ erreur: unknown }>;
}

/// Code a 6 chiffres, zeros de tete conserves. `alea` est injecte pour
/// que les tests puissent decrire une valeur precise ; en production
/// c'est `crypto.getRandomValues`.
export function genererCode(
  alea: () => number,
): string {
  return String(alea() % 1_000_000).padStart(6, '0');
}

export function aleaCryptographique(): number {
  const octets = new Uint32Array(1);
  crypto.getRandomValues(octets);

  return octets[0];
}

export async function hacher(
  valeur: string,
): Promise<string> {
  const donnees = new TextEncoder().encode(valeur);
  const empreinte = await crypto.subtle.digest(
    'SHA-256',
    donnees,
  );

  return Array.from(new Uint8Array(empreinte))
    .map((octet) => octet.toString(16).padStart(2, '0'))
    .join('');
}

/// Un jeton d'appareil trop court est refuse d'entree : il vient d'un
/// client qui ne suit pas le protocole, jamais d'un usage normal.
export function jetonAppareilValide(
  valeur: unknown,
): valeur is string {
  return typeof valeur === 'string' && valeur.length >= 32;
}

export function dateExpiration(maintenant: Date): string {
  return new Date(
    maintenant.getTime() + CODE_VALIDE_MINUTES * 60_000,
  ).toISOString();
}

export type ResultatVerification =
  | { statut: 'accepte' }
  | { statut: 'refuse' }
  | { statut: 'erreurBase' }
  | { statut: 'echecValidation' }
  | { statut: 'echecAppareil' };

/// Verifie un code et, s'il est bon, enregistre l'appareil pour que les
/// connexions suivantes depuis ce meme appareil n'en redemandent plus.
///
/// L'ordre compte : le code est marque utilise AVANT l'enregistrement
/// de l'appareil, pour qu'un code ne puisse jamais servir deux fois,
/// meme si l'enregistrement echoue ensuite.
export async function verifierCode(
  depot: DepotCodes,
  entree: {
    userId: string;
    code: string;
    jetonAppareilHash: string;
    nomAppareil: string | null;
  },
  maintenant: Date,
): Promise<ResultatVerification> {
  const { ligne, erreur } = await depot.dernierCodeNonUtilise(
    entree.userId,
    entree.jetonAppareilHash,
  );

  if (erreur) {
    return { statut: 'erreurBase' };
  }

  if (!ligne) {
    return { statut: 'refuse' };
  }

  const expire =
    new Date(ligne.expire_le).getTime() < maintenant.getTime();

  if (expire || ligne.tentatives >= TENTATIVES_MAX) {
    return { statut: 'refuse' };
  }

  const empreinte = await hacher(entree.code);

  if (empreinte !== ligne.code_hash) {
    await depot.incrementerTentatives(
      ligne.id,
      ligne.tentatives + 1,
    );

    return { statut: 'refuse' };
  }

  const { erreur: erreurUtilise } = await depot.marquerUtilise(
    ligne.id,
    maintenant.toISOString(),
  );

  if (erreurUtilise) {
    return { statut: 'echecValidation' };
  }

  const { erreur: erreurAppareil } =
    await depot.enregistrerAppareil({
      userId: entree.userId,
      jetonHash: entree.jetonAppareilHash,
      nomAppareil: entree.nomAppareil,
      derniereUtilisationLe: maintenant.toISOString(),
    });

  if (erreurAppareil) {
    return { statut: 'echecAppareil' };
  }

  return { statut: 'accepte' };
}
