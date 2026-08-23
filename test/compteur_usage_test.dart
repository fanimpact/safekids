import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/usage/compteur_usage.dart';

// Compteurs d'usage : combien de familles distinctes ont utilisé chaque
// fonctionnalité chaque mois. Jamais laquelle des activités, jamais
// pour quel enfant, jamais à quel moment.
//
// Deux choses se jouent ici. La première est la garantie de discrétion :
// l'application n'envoie que le nom d'une fonctionnalité, et rien
// d'autre ne peut partir. La seconde est plus importante encore : un
// compteur ne doit jamais retarder ni faire échouer une action. Le Mode
// Urgence en particulier.

class _FauxCompteur implements CompteurUsage {
  final List<FonctionnaliteUsage> marques = [];
  final Completer<void>? attente;

  _FauxCompteur({this.attente});

  @override
  void marquer(FonctionnaliteUsage fonctionnalite) {
    // Avale, comme l'implementation reelle : ne rien laisser remonter
    // fait partie du contrat, pas de son implementation.
    marquerEtAttendre(fonctionnalite).catchError((_) {});
  }

  @override
  Future<void> marquerEtAttendre(
    FonctionnaliteUsage fonctionnalite,
  ) async {
    marques.add(fonctionnalite);

    if (attente != null) {
      await attente!.future;
    }
  }
}

void main() {
  group('Ce qui est transmis', () {
    test('Les quatre fonctionnalités demandées, et rien d’autre', () {
      expect(
        FonctionnaliteUsage.values.map((f) => f.code).toList(),
        [
          'activite_preparee',
          'fiche_secours_generee',
          'mode_urgence_ouvert',
          'lien_partage_cree',
        ],
      );
    });

    test('Un marquage ne transmet que le nom de la fonctionnalité', () {
      // La signature est la garantie : il n'y a aucun paramètre où
      // glisser un identifiant d'enfant, une date ou un compteur.
      final compteur = _FauxCompteur();

      compteur.marquer(FonctionnaliteUsage.modeUrgenceOuvert);

      expect(compteur.marques, [FonctionnaliteUsage.modeUrgenceOuvert]);
    });
  });

  group('Un compteur ne bloque jamais', () {
    test('marquer() rend la main avant la fin de l’envoi', () async {
      // Si cet appel attendait, le Mode Urgence attendrait avec lui.
      final attente = Completer<void>();
      final compteur = _FauxCompteur(attente: attente);

      var suiteExecutee = false;

      compteur.marquer(FonctionnaliteUsage.modeUrgenceOuvert);
      suiteExecutee = true;

      expect(suiteExecutee, isTrue);
      expect(attente.isCompleted, isFalse);

      attente.complete();
    });

    test(
      'L’implémentation réelle avale ses erreurs',
      () async {
        // Sans base initialisée, l'appel échoue forcément : c'est
        // exactement le cas d'un fichier SQL pas encore appliqué, ou
        // d'un téléphone hors ligne.
        const compteur = CompteurUsageSupabase();

        await expectLater(
          compteur.marquerEtAttendre(
            FonctionnaliteUsage.ficheSecoursGeneree,
          ),
          completes,
        );
      },
    );
  });

  group('Les branchements sont en place', () {
    // Garde de câblage : ces quatre appels sont faciles à supprimer
    // sans s'en apercevoir, et leur absence ne casserait aucun écran.
    // Le test lit les sources.

    String source(String chemin) => File(chemin).readAsStringSync();

    test('Une activité préparée est comptée', () {
      expect(
        source('lib/repositories/activity_session_repository.dart'),
        contains('FonctionnaliteUsage.activitePreparee'),
      );
    });

    test('Un lien de partage créé est compté', () {
      expect(
        source('lib/sharing/share_link_service.dart'),
        contains('FonctionnaliteUsage.lienPartageCree'),
      );
    });

    test('Le Mode Urgence ouvert est compté', () {
      expect(
        source('lib/home/home_page.dart'),
        contains('FonctionnaliteUsage.modeUrgenceOuvert'),
      );
    });

    test('Une fiche secours générée est comptée, des deux entrées', () {
      // Depuis l'accueil et depuis le profil de l'enfant.
      expect(
        source('lib/home/home_page.dart'),
        contains('FonctionnaliteUsage.ficheSecoursGeneree'),
      );
      expect(
        source('lib/children/child_profile_page.dart'),
        contains('FonctionnaliteUsage.ficheSecoursGeneree'),
      );
    });

    test(
      'Le Mode Urgence est marqué avant toute autre chose',
      () {
        // Si le marquage venait après une recherche d'enfants ou une
        // navigation, il pourrait ne jamais avoir lieu — et surtout, il
        // n'aurait aucune raison de passer avant.
        final texte = source('lib/home/home_page.dart');

        final debutMethode =
            texte.indexOf('void _openEmergencyMode(');
        final marquage = texte.indexOf(
          'FonctionnaliteUsage.modeUrgenceOuvert',
          debutMethode,
        );
        final premiereLecture = texte.indexOf(
          'ChildRepository.instance.children',
          debutMethode,
        );

        expect(marquage, greaterThan(debutMethode));
        expect(marquage, lessThan(premiereLecture));
      },
    );
  });
}
