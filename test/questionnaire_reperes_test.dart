import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/widgets/questionnaire_page.dart';

// Les repères des 17 écrans de questionnaire (25/08/2026).
//
// Avant : la barre de titre disait « Profil de l'enfant » sur les deux
// questionnaires, cinq écrans du questionnaire santé n'avaient aucun
// titre, dix des onze écrans du profil Activités portaient le même
// sous-titre — « Répondez aux questions concernant votre enfant. » —
// et rien n'indiquait où l'on en était, sauf « Dernière étape » au
// onzième.
//
// Ces écrans ne se montent pas facilement : ils ont besoin d'un
// contrôleur et, pour certains, du dépôt. Les tests lisent donc les
// sources — ce qui suffit, parce que ce qu'on protège ici est la
// présence d'un repère, pas son rendu.

const _ecransSante = [
  'identity',
  'diagnosed_pathologies',
  'medical_events',
  'trigger_factors',
  'treatments',
  'contacts',
];

const _ecransActivites = [
  'aquatic_activity',
  'transport',
  'walking_effort',
  'overnight_stay',
  'clothing',
  'toilets',
  'communication',
  'transitions',
  'safety',
  'meals',
  'other_information',
];

String _sourceSante(String nom) =>
    File('lib/transmission_pages/${nom}_page.dart').readAsStringSync();

String _sourceActivites(String nom) =>
    File('lib/activity_profile_pages/${nom}_page.dart')
        .readAsStringSync();

void main() {
  group('Le cadre porte les trois repères', () {
    testWidgets('Barre de titre, étape et titre sont affichés',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QuestionnairePage(
            barreTitre: 'Profil Activités',
            etape: 9,
            total: 11,
            title: 'Sécurité',
            subtitle: 'Un sous-titre.',
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Profil Activités'), findsOneWidget);
      expect(find.text('Étape 9 sur 11'), findsOneWidget);
      expect(find.text('Sécurité'), findsOneWidget);
      expect(find.text('Un sous-titre.'), findsOneWidget);
    });

    testWidgets('La consigne n’apparaît que si elle existe',
        (tester) async {
      // Volontairement propre à chaque écran : le régime de champs
      // obligatoires n'est pas le même partout, et une phrase générale
      // serait fausse quelque part.
      await tester.pumpWidget(
        const MaterialApp(
          home: QuestionnairePage(
            barreTitre: 'Questionnaire santé',
            etape: 1,
            total: 6,
            title: 'Identité',
            subtitle: 'Un sous-titre.',
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.textContaining('à renseigner'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: QuestionnairePage(
            barreTitre: 'Profil Activités',
            etape: 1,
            total: 11,
            title: 'Baignade',
            subtitle: 'Un sous-titre.',
            consigne: 'Toutes les questions sont à renseigner.',
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(
        find.text('Toutes les questions sont à renseigner.'),
        findsOneWidget,
      );
    });
  });

  group('Les deux questionnaires se distinguent', () {
    test('Les six écrans de santé annoncent le questionnaire santé', () {
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          contains("barreTitre: 'Questionnaire santé'"),
          reason: '$ecran n’annonce pas son questionnaire',
        );
      }
    });

    test('Les onze écrans d’activités annoncent le profil Activités',
        () {
      for (final ecran in _ecransActivites) {
        expect(
          _sourceActivites(ecran),
          contains("barreTitre: 'Profil Activités'"),
          reason: '$ecran n’annonce pas son questionnaire',
        );
      }
    });

    test('Plus aucun écran ne dit « Profil de l’enfant »', () {
      // C'était la barre de titre unique des deux questionnaires : un
      // parent au milieu du profil Activités ne savait pas lequel des
      // deux il remplissait.
      for (final ecran in _ecransSante) {
        expect(_sourceSante(ecran), isNot(contains('Profil de l’enfant')));
      }

      expect(
        File('lib/widgets/questionnaire_page.dart').readAsStringSync(),
        isNot(contains('Profil de l’enfant')),
      );
    });
  });

  group('Chaque écran sait où il en est', () {
    test('Les six écrans de santé sont numérotés de 1 à 6', () {
      for (var i = 0; i < _ecransSante.length; i++) {
        final source = _sourceSante(_ecransSante[i]);

        expect(
          source,
          contains('etape: ${i + 1},'),
          reason: '${_ecransSante[i]} n’est pas à l’étape ${i + 1}',
        );
        expect(source, contains('total: 6,'));
      }
    });

    test('Les onze écrans d’activités sont numérotés de 1 à 11', () {
      for (var i = 0; i < _ecransActivites.length; i++) {
        final source = _sourceActivites(_ecransActivites[i]);

        expect(
          source,
          contains('etape: ${i + 1},'),
          reason: '${_ecransActivites[i]} n’est pas à l’étape ${i + 1}',
        );
        expect(source, contains('total: 11,'));
      }
    });

    test('Aucun écran ne garde « Dernière étape du questionnaire »', () {
      // Seule mention d'étape de tout le parcours, au onzième écran :
      // le repère la remplace, et mieux.
      for (final ecran in _ecransActivites) {
        expect(
          _sourceActivites(ecran),
          isNot(contains('Dernière étape')),
        );
      }
    });
  });

  group('Chaque écran a un titre et un sous-titre propre', () {
    test('Plus aucun titre vide', () {
      // Cinq écrans du questionnaire santé passaient `title: ""`.
      for (final ecran in _ecransSante) {
        final source = _sourceSante(ecran);

        expect(source, isNot(contains('title: ""')));
        expect(source, isNot(contains("title: ''")));
      }
    });

    test('Plus aucun sous-titre recopié d’un écran à l’autre', () {
      // Dix des onze écrans d'activités portaient la même phrase.
      final vus = <String>{};

      for (final ecran in _ecransActivites) {
        final source = _sourceActivites(ecran);

        expect(
          source,
          isNot(
            contains('Répondez aux questions concernant votre enfant'),
          ),
          reason: '$ecran porte encore le sous-titre générique',
        );

        final debut = source.indexOf('subtitle:');
        final fin = source.indexOf('consigne:', debut);
        final soustitre = source.substring(debut, fin);

        expect(
          vus.add(soustitre),
          isTrue,
          reason: '$ecran partage son sous-titre avec un autre écran',
        );
      }
    });

    test(
      'Le vocabulaire de structure d’accueil a quitté l’identité',
      () {
        // « Qui est l'enfant pris en charge ? » : un parent qui remplit
        // la fiche de son propre enfant ne se reconnaît pas dedans.
        expect(
          _sourceSante('identity'),
          isNot(contains('pris en charge')),
        );
      },
    );
  });

  group('Chaque écran dit ce qu’il exige, avant l’appui', () {
    test('Chacun porte sa consigne, avant l’appui', () {
      // Le bouton « Continuer » n'est jamais grisé : sans cette ligne,
      // le parent découvre l'exigence en étant refusé.
      for (final ecran in _ecransActivites) {
        expect(
          _sourceActivites(ecran),
          contains('consigne:'),
          reason: '$ecran ne dit pas ce qu’il exige',
        );
      }
    });

    test('Les six écrans de santé portent chacun la leur', () {
      // Vérifié écran par écran le 25/08/2026 : le régime diffère
      // vraiment d'un écran à l'autre — dix questions obligatoires sur
      // les facteurs déclenchants, aucune sur les contacts. C'est
      // pourquoi il n'y a pas de phrase commune ici, contrairement au
      // profil Activités : six lignes sur mesure, validées le
      // 25/08/2026.
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          contains('consigne:'),
          reason: '$ecran ne dit pas ce qu’il exige',
        );
      }
    });

    test('Aucune de ces six lignes n’est recopiée d’un écran à l’autre',
        () {
      // Une consigne copiée serait fausse quelque part : c'est
      // précisément ce qu'on a refusé d'écrire.
      final vues = <String>{};

      for (final ecran in _ecransSante) {
        final source = _sourceSante(ecran);
        final debut = source.indexOf('consigne:');
        final fin = source.indexOf('child:', debut);

        expect(
          vues.add(source.substring(debut, fin)),
          isTrue,
          reason: '$ecran partage sa consigne avec un autre écran',
        );
      }
    });

    test('La phrase générale écartée n’est revenue nulle part', () {
      // « Seuls les champs indispensables sont à renseigner, vous
      // pouvez laisser le reste vide » : vérifiée le 25/08/2026 et
      // trouvée fausse — les facteurs déclenchants exigent dix
      // réponses d'affilée, l'identité exige une date de naissance.
      // Un parent bloqué après avoir lu qu'il pouvait laisser vide,
      // c'est pire que pas de phrase du tout.
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          isNot(contains('laisser le reste vide')),
        );
        expect(
          _sourceSante(ecran),
          isNot(contains('champs indispensables')),
        );
      }
    });
  });
}
