import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verrouille la frontière posée le 23/08/2026 : la dépendance à
/// Supabase doit rester confinée.
///
/// Avant ce chantier, 19 fichiers de `lib/` importaient
/// `supabase_flutter`, dont 5 écrans, `main.dart` et un utilitaire
/// d'affichage. Le jour où l'hébergeur change, chacun aurait été à
/// relire.
///
/// Ce test échoue dès qu'un nouveau fichier franchit la frontière. Il
/// ne demande pas d'exécuter l'app : il lit les sources.
void main() {
  /// Fichiers autorisés à connaître le SDK.
  ///
  /// **N'ajouter une entrée ici qu'en connaissance de cause.** La
  /// bonne réponse est presque toujours de passer par un service
  /// existant ou par `AuthProvider`.
  ///
  /// Les 10 services conservent l'import pour l'accès aux données :
  /// l'abstraction de cette couche est un chantier séparé, non décidé
  /// à ce jour (voir docs/migration/prerequis_base_cible.md).
  const autorises = {
    // L'implémentation de l'authentification — la seule qui doit
    // survivre à un changement d'hébergeur en étant réécrite.
    'lib/auth/supabase_auth_provider.dart',

    // Services et dépôts : accès aux données.
    //
    // `source_export.dart` a rejoint la liste le 23/08/2026 avec le
    // bouton « Exporter mes données ». C'est un accès aux données de
    // plus, mais d'une nature particulière : il lit huit tables pour
    // le droit d'accès RGPD, sans passer par les services existants
    // qui, eux, sont taillés pour l'affichage et filtrent déjà. La
    // règle de cloisonnement, elle, est hors du SDK et testée sans
    // base (voir test/export_cloisonnement_test.dart).
    'lib/auth/account_service.dart',
    'lib/professional/establishment_activity_service.dart',
    'lib/professional/establishment_service.dart',
    'lib/professional/professional_child_repository.dart',
    'lib/repositories/activity_session_repository.dart',
    'lib/repositories/child_repository.dart',
    'lib/sharing/consultation_journal_service.dart',
    'lib/sharing/enfant_confiance_service.dart',
    'lib/sharing/establishment_attachment_service.dart',
    'lib/sharing/notes_enfant_service.dart',
    'lib/sharing/share_link_service.dart',

    // Export RGPD.
    'lib/export/source_export.dart',

    // Suppression du compte avec delai de grace : trois fonctions de
    // la base et un appel a l'Edge Function qui previent par email.
    'lib/suppression/suppression_compte_service.dart',

    // L'acces secours declenche depuis un rattachement : trois
    // fonctions de la base, accordees a `authenticated`. Le
    // professionnel etant authentifie, aucune Edge Function n'est
    // necessaire ici — contrairement au lien de partage, ou
    // l'ouvreur est anonyme.
    'lib/secours/service_acces_secours.dart',

    // Compteurs d'usage : un seul appel, a une fonction de la base
    // qui ne recoit que le nom d'une fonctionnalite.
    'lib/usage/compteur_usage.dart',

    // Etat administratif du compte : adresse de secours, demande de
    // suppression. Ajoute le 23/08/2026 avec le chantier de
    // conformite. Les regles (validation, decisions d'affichage) sont
    // hors de ce fichier et testees sans base.
    'lib/settings/compte_service.dart',
  };

  List<String> fichiersDartDeLib() {
    return Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.dart'))
        .toList()
      ..sort();
  }

  test(
    'seuls les fichiers autorisés importent supabase_flutter',
    () {
      final importateurs = <String>[];

      for (final chemin in fichiersDartDeLib()) {
        final source = File(chemin).readAsStringSync();

        if (source.contains('package:supabase_flutter')) {
          importateurs.add(chemin);
        }
      }

      final nouveaux =
          importateurs.where((f) => !autorises.contains(f)).toList();

      expect(
        nouveaux,
        isEmpty,
        reason:
            'Ces fichiers importent supabase_flutter sans y être '
            'autorisés. Passez par AuthProvider (authentification) ou '
            'par un service existant (données) plutôt que d’élargir '
            'la liste.',
      );
    },
  );

  test(
    'la liste des fichiers autorisés ne contient rien de périmé',
    () {
      final importateurs = <String>[];

      for (final chemin in fichiersDartDeLib()) {
        if (File(chemin)
            .readAsStringSync()
            .contains('package:supabase_flutter')) {
          importateurs.add(chemin);
        }
      }

      final perimes =
          autorises.where((f) => !importateurs.contains(f)).toList();

      expect(
        perimes,
        isEmpty,
        reason:
            'Ces fichiers n’importent plus supabase_flutter : retirez-'
            'les de la liste, pour qu’elle reste le reflet exact de la '
            'dépendance restante.',
      );
    },
  );

  test(
    'aucun écran n’appelle le SDK d’authentification',
    () {
      final fautifs = <String>[];

      for (final chemin in fichiersDartDeLib()) {
        if (chemin == 'lib/auth/supabase_auth_provider.dart') {
          continue;
        }

        final source = File(chemin).readAsStringSync();

        if (source.contains('Supabase.instance.client.auth') ||
            source.contains('_client.auth')) {
          fautifs.add(chemin);
        }
      }

      expect(
        fautifs,
        isEmpty,
        reason:
            'L’accès au SDK d’authentification doit rester dans '
            'SupabaseAuthProvider. Ces 30 appels étaient dispersés '
            'dans 12 fichiers avant le 23/08/2026.',
      );
    },
  );

  test(
    'aucun écran ne lit ni n’écrit directement en base',
    () {
      final fautifs = <String>[];

      for (final chemin in fichiersDartDeLib()) {
        if (!chemin.endsWith('_page.dart')) {
          continue;
        }

        final source = File(chemin).readAsStringSync();

        if (source.contains('.from(') || source.contains('.rpc(')) {
          fautifs.add(chemin);
        }
      }

      expect(
        fautifs,
        isEmpty,
        reason:
            'Un écran doit passer par un service. '
            'create_share_link_page.dart était le dernier à écrire '
            'directement dans `partages`.',
      );
    },
  );
}
