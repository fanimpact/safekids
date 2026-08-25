import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/professional/suite_note.dart';

// Ce que le professionnel apprend après avoir écrit une note
// (26/08/2026).
//
// Jusqu'ici, `saveNote` avalait l'exception de la notification ET
// ignorait le corps de la réponse. L'écran affichait le même succès
// que le parent ait été prévenu ou non — alors que la fonction serveur
// répond honnêtement `{ok: true, notifie: false}` quand il n'y a pas
// d'email exploitable ou que l'envoi échoue. L'information existait,
// le client la jetait.

void main() {
  group('Lire la réponse du serveur', () {
    test('Prévenu quand le serveur le dit', () {
      expect(
        suiteDepuisReponse({'ok': true, 'notifie': true}, statut: 200),
        SuiteNote.parentPrevenu,
      );
    });

    test('Pas prévenu quand le serveur le dit', () {
      // Cas réel : le parent n'a pas d'email exploitable, ou Brevo a
      // refusé. La fonction renvoie 200 quand même — la note, elle,
      // est bien enregistrée.
      expect(
        suiteDepuisReponse({'ok': true, 'notifie': false}, statut: 200),
        SuiteNote.parentNonPrevenu,
      );
    });

    test('Un statut d’erreur vaut « pas prévenu »', () {
      expect(
        suiteDepuisReponse({'error': 'Requete invalide.'}, statut: 400),
        SuiteNote.parentNonPrevenu,
      );
      expect(
        suiteDepuisReponse(null, statut: 500),
        SuiteNote.parentNonPrevenu,
      );
    });

    test('Une réponse illisible vaut « pas prévenu »', () {
      // L'écran doit dire ce qu'il sait. Il ne sait pas que le parent a
      // été prévenu : il dit qu'il ne l'a pas été.
      for (final corps in [null, 'ok', 42, <String>[]]) {
        expect(
          suiteDepuisReponse(corps, statut: 200),
          SuiteNote.parentNonPrevenu,
          reason: '« $corps » ne prouve pas que le parent a été prévenu',
        );
      }
    });

    test('Un champ `notifie` absent ne vaut pas prévenu', () {
      expect(
        suiteDepuisReponse({'ok': true}, statut: 200),
        SuiteNote.parentNonPrevenu,
      );
    });

    test('Le doute penche toujours du même côté', () {
      // Aucune entrée douteuse ne doit pouvoir rendre `parentPrevenu` :
      // annoncer à tort qu'un parent a été prévenu est le seul des
      // trois messages qui puisse tromper.
      for (final corps in [
        null,
        'ok',
        {'notifie': 'oui'},
        {'notifie': 1},
        {'ok': true},
      ]) {
        expect(
          suiteDepuisReponse(corps, statut: 200),
          isNot(SuiteNote.parentPrevenu),
        );
      }
    });
  });

  group('Les trois messages sont distincts', () {
    test('Chacun dit une chose différente', () {
      final messages = SuiteNote.values.map(messageSuiteNote).toSet();

      expect(messages, hasLength(3));
    });

    test('La note générale dit que personne n’est informé', () {
      // C'était le piège d'origine : le professionnel croyait avoir
      // informé le parent alors que non.
      final message = messageSuiteNote(SuiteNote.sansDestinataire);

      expect(message, contains('aucun parent'));
      expect(message, contains('enregistrée'));
    });

    test('L’échec d’email dit où la note reste lisible', () {
      // Depuis le 25/08/2026 elle l'est vraiment : l'écran parent
      // existe. Le dire évite une inquiétude sans objet.
      final message = messageSuiteNote(SuiteNote.parentNonPrevenu);

      expect(message, contains('son espace'));
      expect(message, contains('enregistrée'));
    });

    test('Aucun message ne prétend que la note a échoué', () {
      // Dans les trois cas la note EST enregistrée. Laisser croire le
      // contraire ferait ressaisir une observation déjà en base.
      for (final suite in SuiteNote.values) {
        final message = messageSuiteNote(suite);

        expect(message, contains('Note enregistrée'));
        expect(message, isNot(contains('Impossible d’enregistrer')));
      }
    });
  });

  group('Les deux écrans disent ce qu’ils ont appris', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    const ecrans = [
      'lib/professional/add_activity_note_page.dart',
      'lib/professional/activity_note_page.dart',
    ];

    test('Chacun affiche le message de la suite', () {
      for (final ecran in ecrans) {
        expect(
          source(ecran),
          contains('messageSuiteNote(suite)'),
          reason: '$ecran tait ce qui est arrivé au parent',
        );
      }
    });

    test('Le service ne jette plus la réponse du serveur', () {
      final service = source(
        'lib/professional/establishment_activity_service.dart',
      );

      expect(service, contains('Future<SuiteNote> saveNote('));
      expect(service, contains('suiteDepuisReponse('));
      expect(
        service,
        contains('return SuiteNote.sansDestinataire;'),
        reason:
            'Une note générale au groupe doit se distinguer d’un envoi '
            'réussi',
      );
    });
  });
}
