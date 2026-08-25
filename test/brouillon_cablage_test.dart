import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Le câblage du brouillon sur les dix-sept écrans (25/08/2026).
//
// Ce test lit les sources. Ces écrans ne se montent pas facilement —
// contrôleur, dépôt, navigation — et ce qu'on protège ici n'est pas un
// rendu mais une ligne qui peut disparaître sans bruit : un écran
// refondu qui perd son enregistrement ne casse aucun test, et le
// parent perd son travail des mois plus tard.

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
];

String _lire(String chemin) => File(chemin).readAsStringSync();

String _sourceSante(String nom) =>
    _lire('lib/transmission_pages/${nom}_page.dart');

String _sourceActivites(String nom) =>
    _lire('lib/activity_profile_pages/${nom}_page.dart');

void main() {
  group('Chaque écran validé écrit le brouillon', () {
    test('Les six écrans du questionnaire santé', () {
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          contains('enregistrerBrouillonSante('),
          reason: '$ecran n’enregistre pas le brouillon',
        );
      }
    });

    test('Les dix écrans intermédiaires du profil Activités', () {
      // Le onzième — other_information — n'enregistre pas : il valide
      // et écrit en base, puis jette le brouillon.
      for (final ecran in _ecransActivites) {
        expect(
          _sourceActivites(ecran),
          contains('enregistrerBrouillonActivites('),
          reason: '$ecran n’enregistre pas le brouillon',
        );
      }
    });
  });

  group('L’écriture ne fait jamais attendre le parent', () {
    test('Aucun écran n’attend le disque avant de naviguer', () {
      // Vérifié le 25/08/2026 : sous `testWidgets`, la réponse de
      // SharedPreferences arrive hors de l'horloge simulée et le futur
      // ne se termine jamais pendant les pumps. Attendre l'écriture
      // avant `Navigator.push` gelait la navigation — quatorze tests
      // sont tombés, et sur un appareil dont le stockage tousse c'est
      // le parent qui serait resté bloqué. L'écriture est donc lancée
      // sans être attendue.
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          isNot(contains('await enregistrerBrouillon')),
          reason: '$ecran attend l’écriture du brouillon',
        );
      }

      for (final ecran in _ecransActivites) {
        expect(
          _sourceActivites(ecran),
          isNot(contains('await enregistrerBrouillon')),
          reason: '$ecran attend l’écriture du brouillon',
        );
      }
    });

    test('Les deux validations finales n’attendent pas non plus', () {
      expect(
        _lire('lib/transmission_pages/transition_to_activities_page.dart'),
        isNot(contains('await supprimerBrouillon')),
      );
      expect(
        _lire('lib/activity_profile_pages/other_information_page.dart'),
        isNot(contains('await supprimerBrouillon')),
      );
    });

    test('Personne n’appelle le dépôt directement depuis un écran', () {
      // Les écrans passent par les fonctions qui avalent les erreurs.
      // Un appel direct à `BrouillonRepository` rendrait à nouveau
      // l'échec d'écriture bloquant.
      for (final ecran in _ecransSante) {
        expect(
          _sourceSante(ecran),
          isNot(contains('BrouillonRepository.instance')),
          reason: '$ecran appelle le dépôt sans filet',
        );
      }

      for (final ecran in [..._ecransActivites, 'other_information']) {
        expect(
          _sourceActivites(ecran),
          isNot(contains('BrouillonRepository.instance')),
          reason: '$ecran appelle le dépôt sans filet',
        );
      }
    });
  });

  group('Au bout du questionnaire, le brouillon est jeté', () {
    test('Le questionnaire santé le jette après l’écriture en base',
        () {
      final source = _lire(
        'lib/transmission_pages/transition_to_activities_page.dart',
      );

      expect(source, contains('addChild('));
      expect(source, contains('supprimerBrouillon('));
      expect(source, contains('TypeBrouillon.sante'));

      // L'ordre compte : jeter le brouillon avant que la base ait
      // accepté l'enfant ferait perdre le travail en cas d'échec.
      expect(
        source.indexOf('supprimerBrouillon('),
        greaterThan(source.indexOf('addChild(')),
      );
    });

    test('Le profil Activités le jette après l’écriture en base', () {
      final source =
          _lire('lib/activity_profile_pages/other_information_page.dart');

      expect(source, contains('saveActivityProfile('));
      expect(source, contains('supprimerBrouillon('));
      expect(source, contains('TypeBrouillon.activites'));
      expect(
        source.indexOf('supprimerBrouillon('),
        greaterThan(source.indexOf('saveActivityProfile(')),
      );
    });
  });

  group('« Mes enfants » propose la reprise', () {
    test('L’écran charge les brouillons et les écoute', () {
      final source = _lire('lib/children/children_page.dart');

      expect(source, contains('BrouillonRepository.instance.charger()'));
      expect(source, contains('BrouillonRepository.instance'));
      expect(source, contains('Listenable.merge('));
    });

    test('La reprise est annoncée, jamais silencieuse', () {
      // Le parent doit comprendre qu'il reprend quelque chose de
      // commencé, et qu'il lui reste des écrans à remplir.
      final source = _lire('lib/children/children_page.dart');

      expect(source, contains('libelleReprise('));
    });
  });
}
