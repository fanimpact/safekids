// Branchement du dépôt des notifications en attente sur Supabase.
//
// Seule partie à réécrire si la base change de moteur : la logique de
// ../_logique/notifications_en_attente.mts ne connaît que l'interface,
// jamais le SDK ni le nom des colonnes.

import type { SupabaseClient } from './supabase.mts';

import {
  envoyerParBrevo,
  type ExpediteurEmail,
} from '../_logique/emails.mts';

import type {
  DepotNotifications,
} from '../_logique/notifications_en_attente.mts';

export function depotNotificationsEnAttenteSupabase(
  service: SupabaseClient,
  expediteur: ExpediteurEmail,
): DepotNotifications {
  return {
    async evenementsEnAttente(limite) {
      // Les plus anciennes d'abord : un accès secours déclenché il y a
      // dix minutes passe avant une notification de la seconde qui
      // vient de s'écrire.
      const { data, error } = await service
        .from('evenements_notification_parent')
        .select('id, parent_id, enfant_id, type_evenement, donnees')
        .eq('statut_email', 'en_attente')
        .order('cree_le', { ascending: true })
        .limit(limite);

      if (error) {
        console.error(error);
        return { evenements: [], erreur: error };
      }

      const evenements = (data ?? []).map((ligne) => ({
        id: ligne.id as string,
        parentId: ligne.parent_id as string,
        enfantId: ligne.enfant_id as string,
        typeEvenement: ligne.type_evenement as string,
        donnees:
          (ligne.donnees as Record<string, unknown> | null) ?? null,
      }));

      return { evenements, erreur: null };
    },

    async emailParent(parentId) {
      const { data } = await service
        .from('comptes_parents')
        .select('email')
        .eq('id', parentId)
        .maybeSingle();

      return (data?.email as string | undefined) ?? null;
    },

    async prenomEnfant(enfantId) {
      // Le prénom seul, et c'est la requête elle-même qui le garantit :
      // le nom de famille n'est même pas lu.
      const { data } = await service
        .from('enfants')
        .select('prenom')
        .eq('id', enfantId)
        .maybeSingle();

      return (data?.prenom as string | undefined) ?? null;
    },

    async accesSecours(partageId) {
      const { data } = await service
        .from('partages')
        .select('date_expiration')
        .eq('id', partageId)
        .maybeSingle();

      if (!data) {
        return null;
      }

      return {
        expireLe: (data.date_expiration as string | null) ?? null,
      };
    },

    async envoyer(message) {
      return envoyerParBrevo(fetch, expediteur, message);
    },

    async marquerEnvoye(id, envoyeLe) {
      await service
        .from('evenements_notification_parent')
        .update({ statut_email: 'envoye', email_envoye_le: envoyeLe })
        .eq('id', id);
    },

    async marquerEchoue(id) {
      await service
        .from('evenements_notification_parent')
        .update({ statut_email: 'echoue' })
        .eq('id', id);
    },
  };
}
