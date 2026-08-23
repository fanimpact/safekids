// Branchement du dépôt de notifications sur Supabase.
//
// Seule partie à réécrire si la base change de moteur : la logique de
// ../_logique/notification_note.mts ne connaît que l'interface
// DepotNotifications, jamais le SDK ni le nom des colonnes.

import type { SupabaseClient } from './supabase.mts';

import type {
  Activite,
  DepotNotifications,
  Enfant,
} from '../_logique/notification_note.mts';

export function depotNotificationsSupabase(
  service: SupabaseClient,
): DepotNotifications {
  return {
    async activite(activiteId) {
      const { data, error } = await service
        .from('activites_preparees')
        .select('etablissement_id, enfants_ids')
        .eq('id', activiteId)
        .maybeSingle();

      if (error) {
        return null;
      }

      return (data as Activite | null) ?? null;
    },

    async estMembreActif(etablissementId, userId) {
      const { data } = await service
        .from('membres_etablissement')
        .select('id')
        .eq('etablissement_id', etablissementId)
        .eq('user_id', userId)
        .eq('statut', 'actif')
        .maybeSingle();

      return Boolean(data);
    },

    async enfant(enfantId) {
      const { data } = await service
        .from('enfants')
        .select('prenom, parent_id')
        .eq('id', enfantId)
        .maybeSingle();

      return (data as Enfant | null) ?? null;
    },

    async nomEtablissement(etablissementId) {
      const { data } = await service
        .from('etablissements')
        .select('nom')
        .eq('id', etablissementId)
        .maybeSingle();

      return data?.nom ?? null;
    },

    async emailParent(parentId) {
      const { data } = await service
        .from('comptes_parents')
        .select('email')
        .eq('id', parentId)
        .maybeSingle();

      return data?.email ?? null;
    },

    async creerEvenement(entree) {
      const { data, error } = await service
        .from('evenements_notification_parent')
        .insert({
          parent_id: entree.parentId,
          enfant_id: entree.enfantId,
          type_evenement: entree.typeEvenement,
          donnees: entree.donnees,
        })
        .select('id')
        .single();

      return { id: data?.id ?? null, erreur: error };
    },

    async marquerEvenement(id, statut, envoyeLe) {
      const modification: Record<string, unknown> = {
        statut_email: statut,
      };

      if (envoyeLe) {
        modification.email_envoye_le = envoyeLe;
      }

      await service
        .from('evenements_notification_parent')
        .update(modification)
        .eq('id', id);
    },
  };
}
