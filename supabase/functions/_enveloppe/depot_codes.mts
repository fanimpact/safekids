// Branchement du depot de codes sur Supabase.
//
// C'est la seule partie a reecrire si la base change de moteur : la
// logique de ../_logique/codes_verification.mts ne connait que
// l'interface DepotCodes, jamais le SDK ni le nom des colonnes.

import type { SupabaseClient } from './supabase.mts';

import type {
  CodeEnCours,
  DepotCodes,
} from '../_logique/codes_verification.mts';

export function depotCodesSupabase(
  service: SupabaseClient,
): DepotCodes {
  return {
    async enregistrerCode(entree) {
      const { error } = await service
        .from('codes_verification')
        .insert({
          user_id: entree.userId,
          code_hash: entree.codeHash,
          jeton_appareil_hash: entree.jetonAppareilHash,
          expire_le: entree.expireLe,
        });

      return { erreur: error };
    },

    async dernierCodeNonUtilise(userId, jetonAppareilHash) {
      const { data, error } = await service
        .from('codes_verification')
        .select('id, code_hash, expire_le, utilise_le, tentatives')
        .eq('user_id', userId)
        .eq('jeton_appareil_hash', jetonAppareilHash)
        .is('utilise_le', null)
        .order('cree_le', { ascending: false })
        .limit(1)
        .maybeSingle();

      return {
        ligne: (data as CodeEnCours | null) ?? null,
        erreur: error,
      };
    },

    async incrementerTentatives(id, tentatives) {
      await service
        .from('codes_verification')
        .update({ tentatives })
        .eq('id', id);
    },

    async marquerUtilise(id, horodatage) {
      const { error } = await service
        .from('codes_verification')
        .update({ utilise_le: horodatage })
        .eq('id', id);

      return { erreur: error };
    },

    async enregistrerAppareil(entree) {
      const { error } = await service
        .from('appareils_reconnus')
        .upsert(
          {
            user_id: entree.userId,
            jeton_hash: entree.jetonHash,
            nom_appareil: entree.nomAppareil,
            derniere_utilisation_le: entree.derniereUtilisationLe,
          },
          { onConflict: 'user_id,jeton_hash' },
        );

      return { erreur: error };
    },
  };
}
