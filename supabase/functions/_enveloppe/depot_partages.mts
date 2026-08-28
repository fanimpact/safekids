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
          'id, enfant_id, type_fiche, date_expiration, contenu_fige, ' +
            'destinataire, revoque_le, permanent, appareils_max, ' +
            'declenche_en_secours',
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

    async journaliserOuverture(entree) {
      // Ecrit avec la cle de service, hors RLS : la policy d'ecriture
      // du journal exige user_id = auth.uid(), et une ouverture de lien
      // n'a pas d'utilisateur connecte. C'est aussi ce qui garantit que
      // personne d'authentifie ne peut fabriquer une fausse ouverture.
      //
      // Aucune adresse IP, aucun en-tete de requete, aucune empreinte
      // de navigateur : la fonction ne les lit meme pas.
      const { error } = await service
        .from('journal_consultations_fiche')
        .insert({
          enfant_id: entree.enfantId,
          partage_id: entree.partageId,
          type_fiche: entree.typeFiche,
          origine: 'lien_partage',
          user_id: null,
          consulte_le: entree.ouvertLe,
        });

      if (error) {
        console.error(error);
      }
    },

    async placesDuPartage(partageId) {
      const { data, error } = await service
        .from('appareils_partage')
        .select('id, empreinte, pris_le')
        .eq('partage_id', partageId);

      if (error) {
        console.error(error);
      }

      return { places: data ?? [], erreur: error };
    },

    async prendrePlace(partageId, empreinte, prisLe) {
      const { error } = await service
        .from('appareils_partage')
        .insert({
          partage_id: partageId,
          empreinte,
          pris_le: prisLe,
        });

      if (error) {
        console.error(error);
      }

      return { erreur: error };
    },

    async remplacerPlace(placeId, empreinte) {
      // `pris_le` n'est pas touche : c'est la date de premiere
      // occupation de la place, et la reecrire ferait glisser la
      // fenetre de tolerance.
      const { error } = await service
        .from('appareils_partage')
        .update({ empreinte })
        .eq('id', placeId);

      if (error) {
        console.error(error);
      }

      return { erreur: error };
    },

    async accesSecoursAutorise(enfantId) {
      const { data, error } = await service
        .from('enfants')
        .select('acces_secours_autorise')
        .eq('id', enfantId)
        .maybeSingle();

      if (error) {
        console.error(error);
      }

      return {
        autorise: data?.acces_secours_autorise === true,
        erreur: error,
      };
    },

    async creerAccesSecours(partageId) {
      // Les regles de contenu et de duree sont dans la fonction en
      // base, pas ici : elles doivent tenir meme si un autre appelant
      // s'adresse un jour a la meme table.
      const { data, error } = await service.rpc(
        'declencher_acces_secours',
        { p_partage_id: partageId },
      );

      if (error) {
        console.error(error);
        return { acces: null, erreur: error };
      }

      const ligne = Array.isArray(data) ? data[0] : data;

      if (!ligne) {
        return { acces: null, erreur: new Error('Aucun acces cree.') };
      }

      return {
        acces: {
          token: ligne.secours_token,
          expireLe: ligne.secours_expire_le,
          // La base dit si elle a cree ou retrouve. Sans ce
          // drapeau, une reprise notifierait le parent une
          // seconde fois pour le meme acces.
          creeMaintenant: ligne.secours_cree !== false,
        },
        erreur: null,
      };
    },

    async notifierParent(partageId, enfantId) {
      // Le parent est prevenu, jamais consulte. Un echec d'ecriture ne
      // remet pas l'acces en cause : c'est une urgence, elle passe
      // avant la notification.
      const { data: enfant, error: erreurEnfant } = await service
        .from('enfants')
        .select('parent_id')
        .eq('id', enfantId)
        .maybeSingle();

      if (erreurEnfant || !enfant?.parent_id) {
        console.error(erreurEnfant);
        return;
      }

      const { error } = await service
        .from('evenements_notification_parent')
        .insert({
          parent_id: enfant.parent_id,
          enfant_id: enfantId,
          type_evenement: 'acces_secours_declenche',
          donnees: { partageId },
        });

      if (error) {
        console.error(error);
      }
    },

    async journaliserTentative(entree) {
      // Aucune adresse IP, aucun en-tete, aucune empreinte de
      // navigateur : on enregistre qu'une tentative a eu lieu, jamais
      // qui l'a faite. Meme regle que le journal des ouvertures.
      const { error } = await service
        .from('tentatives_partage_refusees')
        .insert({
          partage_id: entree.partageId,
          tentee_le: entree.tenteeLe,
          toleree: entree.toleree,
        });

      if (error) {
        console.error(error);
      }
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
