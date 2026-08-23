// Branchement du dépôt de partages sur Supabase.
//
// Seule partie à réécrire si la base change de moteur : la logique de
// ../_logique/partage_consultation.mts ne connaît que l'interface
// DepotPartages, jamais le SDK ni le nom des colonnes.

import type { SupabaseClient } from './supabase.mts';

import type {
  DepotPartages,
  Partage,
} from '../_logique/partage_consultation.mts';

export function depotPartagesSupabase(
  service: SupabaseClient,
): DepotPartages {
  return {
    async partageParToken(token) {
      const { data, error } = await service
        .from('partages')
        .select(
          'id, enfant_id, type_fiche, date_expiration, contenu_fige, destinataire',
        )
        .eq('token', token)
        .maybeSingle();

      if (error) {
        console.error(error);
      }

      return {
        partage: (data as Partage | null) ?? null,
        erreur: error,
      };
    },

    async enfant(enfantId) {
      const { data, error } = await service
        .from('enfants')
        .select(
          'id, prenom, nom, date_naissance, poids, taille, date_maj_poids',
        )
        .eq('id', enfantId)
        .maybeSingle();

      if (error) {
        console.error(error);
      }

      return { enfant: data ?? null, erreur: error };
    },

    async profilSante(enfantId) {
      const { data } = await service
        .from('profils_sante')
        .select('*')
        .eq('enfant_id', enfantId)
        .maybeSingle();

      return data ?? null;
    },

    async profilActivites(enfantId) {
      const { data } = await service
        .from('profils_activites')
        .select('*')
        .eq('enfant_id', enfantId)
        .maybeSingle();

      return data ?? null;
    },

    async marquerConsulte(partageId, horodatage) {
      const { error } = await service
        .from('partages')
        .update({ date_derniere_consultation: horodatage })
        .eq('id', partageId);

      if (error) {
        console.error(error);
      }

      return { erreur: error };
    },
  };
}
