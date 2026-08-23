import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compteurs d'usage : combien de familles distinctes ont utilisé
/// chaque fonctionnalité chaque mois.
///
/// Ce qui n'est **jamais** enregistré : laquelle des activités, pour
/// quel enfant, à quel moment, ni combien de fois. L'application
/// n'envoie que le nom de la fonctionnalité ; l'identité vient de la
/// session côté base, dans une fonction que le client ne voit pas.
/// Voir `supabase/schema_conformite_rgpd.sql` pour le détail — dont le
/// fait que le mois en cours reste pseudonyme, et que la consolidation
/// mensuelle le réduit à un simple entier.
///
/// **Règle absolue : un compteur ne doit jamais retarder ni faire
/// échouer une action.** Le Mode Urgence en particulier : personne ne
/// doit attendre un aller-retour réseau statistique pendant qu'un
/// enfant fait un malaise. D'où [marquer], qui n'attend rien et
/// n'échoue jamais.
enum FonctionnaliteUsage {
  activitePreparee('activite_preparee'),
  ficheSecoursGeneree('fiche_secours_generee'),
  modeUrgenceOuvert('mode_urgence_ouvert'),
  lienPartageCree('lien_partage_cree');

  const FonctionnaliteUsage(this.code);

  /// Nom transmis à la base. La liste y est fermée : une valeur
  /// inconnue est ignorée plutôt que d'inventer une fonctionnalité.
  final String code;
}

abstract class CompteurUsage {
  /// N'attend rien et ne lève jamais. Voir la note de classe.
  void marquer(FonctionnaliteUsage fonctionnalite);

  /// Même chose, mais rend la Future — réservé aux tests, qui ont
  /// besoin de savoir quand l'envoi s'est terminé.
  @visibleForTesting
  Future<void> marquerEtAttendre(
    FonctionnaliteUsage fonctionnalite,
  );
}

class CompteurUsageSupabase implements CompteurUsage {
  const CompteurUsageSupabase();

  static const CompteurUsageSupabase instance =
      CompteurUsageSupabase();

  @override
  void marquer(FonctionnaliteUsage fonctionnalite) {
    // Volontairement non attendu : l'appelant continue immédiatement.
    marquerEtAttendre(fonctionnalite);
  }

  @override
  Future<void> marquerEtAttendre(
    FonctionnaliteUsage fonctionnalite,
  ) async {
    try {
      await Supabase.instance.client.rpc(
        'enregistrer_usage',
        params: {'p_fonctionnalite': fonctionnalite.code},
      );
    } catch (erreur) {
      // Hors ligne, session expirée, fonction absente de la base
      // parce que le fichier SQL n'a pas encore été appliqué : rien de
      // tout cela ne doit remonter à l'utilisateur. Un compteur perdu
      // est sans conséquence ; une action bloquée ne l'est pas.
      debugPrint('Compteur d’usage non enregistré : $erreur');
    }
  }
}

/// Le compteur utilisé par l'application. Remplaçable dans les tests.
CompteurUsage compteurUsage = CompteurUsageSupabase.instance;

@visibleForTesting
void reinitialiserCompteurUsage() {
  compteurUsage = CompteurUsageSupabase.instance;
}
