import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/share_link_data.dart';

// Le QR de partage (28/08/2026).
//
// Distinct du QR de l'accès secours, déjà en production : celui-ci est
// un partage ordinaire que le parent remet en présentiel, en faisant
// scanner un code affiché à son écran.
//
// Ce que ces tests protègent, ce sont les règles de Fanny, pas ce que
// le code fait aujourd'hui.

String _source(String chemin) => File(chemin).readAsStringSync();

String _codeSansCommentaires(String chemin) {
  return _source(chemin)
      .split('\n')
      .where((ligne) {
        final nu = ligne.trimLeft();
        return !nu.startsWith('//') && !nu.startsWith('///');
      })
      .join('\n');
}

ShareLinkData _partage({
  DateTime? utilisableJusquA,
  DateTime? dateDerniereConsultation,
  DateTime? dateExpiration,
  DateTime? revoqueLe,
  bool permanent = false,
}) {
  return ShareLinkData(
    id: 'p1',
    token: 't1',
    enfantId: 'e1',
    ficheType: ShareFicheType.secours,
    destinataire: ShareDestinataire.particulier,
    dateCreation: DateTime(2026, 8, 28, 10),
    dateExpiration: dateExpiration,
    dateDerniereConsultation: dateDerniereConsultation,
    nomDestinataire: 'Mamie',
    permanent: permanent,
    revoqueLe: revoqueLe,
    utilisableJusquA: utilisableJusquA,
  );
}

void main() {
  final futur = DateTime.now().add(const Duration(minutes: 4));
  final passe = DateTime.now().subtract(const Duration(minutes: 1));
  final dansTroisJours = DateTime.now().add(const Duration(days: 3));

  group('Les deux durées ne se mélangent jamais', () {
    test('La fenêtre du code est une colonne à part', () {
      // Cinq minutes pour scanner, trois jours d'accès : ce sont deux
      // choses différentes, et elles ne vivent pas au même endroit.
      final code = _partage(
        utilisableJusquA: futur,
        dateExpiration: dansTroisJours,
      );

      expect(code.utilisableJusquA, futur);
      expect(code.dateExpiration, dansTroisJours);
      expect(code.estCodeAScanner, isTrue);
    });

    test('Un lien ordinaire n’a pas de fenêtre', () {
      final lien = _partage(dateExpiration: dansTroisJours);

      expect(lien.estCodeAScanner, isFalse);
      expect(lien.codeEnAttente, isFalse);
      expect(lien.codeNonScanne, isFalse);
    });

    test('Une ligne d’avant le 28/08/2026 reste un lien ordinaire', () {
      // La colonne est nulle sur toutes les lignes existantes : les
      // traiter comme des codes fermés couperait tous les partages en
      // cours.
      final ancienne = ShareLinkData.fromRow({
        'id': 'p1',
        'token': 't1',
        'enfant_id': 'e1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00.000Z',
        'date_expiration': '2026-12-01T10:00:00.000Z',
        'date_derniere_consultation': null,
      });

      expect(ancienne.utilisableJusquA, isNull);
      expect(ancienne.estActif, isTrue);
    });
  });

  group('Le sort d’un code selon qu’il a été scanné', () {
    test('Fenêtre ouverte, jamais scanné : en attente', () {
      final code = _partage(
        utilisableJusquA: futur,
        dateExpiration: dansTroisJours,
      );

      expect(code.codeEnAttente, isTrue);
      expect(code.codeNonScanne, isFalse);
      expect(code.estActif, isTrue, reason: 'il attend, il n’est pas fini');
    });

    test('Fenêtre fermée sans scan : il bascule dans les terminés', () {
      // Décision de Fanny : rien n'est effacé, mais une ligne que
      // personne n'a jamais eue ne se fait pas passer pour un accès.
      final code = _partage(
        utilisableJusquA: passe,
        dateExpiration: dansTroisJours,
      );

      expect(code.codeNonScanne, isTrue);
      expect(code.estActif, isFalse);
    });

    test('Scanné : la fenêtre ne compte plus', () {
      // C'est le point qui casserait tout s'il était faux : le
      // destinataire perdrait son accès cinq minutes après l'avoir
      // reçu, alors que le parent lui a donné trois jours.
      final code = _partage(
        utilisableJusquA: passe,
        dateDerniereConsultation: DateTime.now(),
        dateExpiration: dansTroisJours,
      );

      expect(code.codeNonScanne, isFalse);
      expect(code.codeEnAttente, isFalse);
      expect(code.estActif, isTrue);
    });

    test('Scanné puis révoqué : révoqué gagne', () {
      final code = _partage(
        utilisableJusquA: passe,
        dateDerniereConsultation: DateTime.now(),
        dateExpiration: dansTroisJours,
        revoqueLe: DateTime.now(),
      );

      expect(code.estActif, isFalse);
    });

    test('Un accès sans date de fin reste possible par code', () {
      // La liste des durées n'a pas changé : « Sans date de fin » y
      // figure toujours, et le code y donne accès comme le lien.
      final code = _partage(
        utilisableJusquA: futur,
        permanent: true,
      );

      expect(code.estExpire, isFalse);
      expect(code.estActif, isTrue);
    });
  });

  group('Ce que le parent lit dans sa liste', () {
    final ecran = _codeSansCommentaires('lib/children/child_profile_page.dart');

    test('En attente de scan pendant la fenêtre', () {
      expect(ecran, contains('link.codeEnAttente'));
      expect(ecran, contains('En attente de scan'));
    });

    test('Code non scanné après, et rien n’est effacé', () {
      expect(ecran, contains('link.codeNonScanne'));
      expect(ecran, contains('Code non scanné'));

      // La révocation par marquage reste la seule façon de couper.
      expect(ecran, isNot(contains('.delete()')));
    });
  });

  group('L’écran du code', () {
    final ecran = _codeSansCommentaires('lib/sharing/ecran_code_partage.dart');
    final brut = _source('lib/sharing/ecran_code_partage.dart');

    test('Rien à imprimer, partager, copier ni enregistrer', () {
      // Règle 4, sans exception. Le code s'affiche, c'est tout.
      for (final interdit in [
        'SharePlus',
        'Clipboard',
        'Printing',
        'printing',
        'saveAs',
        'writeAsBytes',
      ]) {
        expect(
          ecran,
          isNot(contains(interdit)),
          reason: '$interdit permettrait de sortir le code de l’écran',
        );
      }
    });

    test('Aucune protection à deux vitesses contre la capture', () {
      // Fanny : le même comportement sur les deux systèmes. Pas de
      // FLAG_SECURE Android, puisque iOS n'a pas d'équivalent.
      expect(brut, isNot(contains('FLAG_SECURE')));
      expect(brut, isNot(contains('secureFlag')));
    });

    test('L’adresse en clair est sous le code', () {
      // Une seule logique dans toute l'application : comme sur l'écran
      // de l'accès secours. Si le scan ne prend pas, elle dépanne.
      expect(ecran, contains('CodeQr('));
      expect(ecran, contains('SelectableText('));
      expect(
        ecran.indexOf('CodeQr('),
        lessThan(ecran.indexOf('SelectableText(')),
      );
    });

    test('Le décompte repart à chaque retour sur l’écran', () {
      // Décision de Fanny : le code n'est visible que sur le téléphone
      // du parent, rien n'a été transmis tant que personne n'a scanné.
      expect(ecran, contains('didChangeAppLifecycleState'));
      expect(ecran, contains('AppLifecycleState.resumed'));
      expect(ecran, contains('WidgetsBindingObserver'));
    });

    test('Un code déjà scanné ne se rafraîchit plus', () {
      // Faire tourner le jeton couperait le destinataire, qui n'a
      // rien demandé.
      expect(ecran, contains('dejaScanne'));
    });

    test('La durée de l’accès est dite à côté du code', () {
      // Deux durées sur le même écran : elles doivent se distinguer
      // sans effort.
      expect(ecran, contains('texteDuree'));
    });
  });

  group('L’écran de création reste le seul chemin', () {
    final ecran =
        _codeSansCommentaires('lib/sharing/create_share_link_page.dart');

    test('Le même formulaire sert aux deux remises', () {
      // Pas de second écran de création, pas de seconde liste de
      // durées, pas de second service.
      expect(ecran, contains('_generateLink(codeAScanner: true)'));
      expect(ecran, contains('Montrer un code à scanner'));
    });

    test('La liste des durées n’a pas bougé', () {
      // Règle de Fanny du 27/08/2026 : les durées proposées ne sont
      // pas des choix d'ergonomie.
      for (final duree in [
        "jour1('24 heures'",
        "jours3('3 jours'",
        "jours7('7 jours'",
        "mois1('1 mois'",
        "an1('1 an'",
        "permanent('Sans date de fin'",
      ]) {
        expect(ecran, contains(duree));
      }
    });

    test('Le nom du destinataire reste obligatoire', () {
      expect(ecran, contains('if (nomDestinataire == null)'));
    });
  });

  group('Ce que le serveur garantit', () {
    final sql = _source('supabase/schema_code_partage.sql')
        .split('\n')
        .where((ligne) => !ligne.trimLeft().startsWith('--'))
        .join('\n');

    final logique = _codeSansCommentaires(
      'supabase/functions/_logique/partage_consultation.mts',
    );

    test('La fenêtre ne vaut que tant que personne n’a scanné', () {
      expect(logique, contains('places.length === 0 &&'));
      expect(logique, contains('fenetreEncoreOuverte('));
    });

    test('Une fenêtre nulle vaut ouverte', () {
      // Sinon tous les partages existants seraient coupés.
      expect(logique, contains('if (!utilisableJusquA) {'));
    });

    test('Le jeton tourne à chaque rafraîchissement', () {
      // Sans rotation, une photo du code précédent redeviendrait
      // valable et les cinq minutes ne voudraient plus rien dire.
      expect(sql, contains('set token = encode(gen_random_bytes(24)'));
    });

    test('Il ne tourne plus une fois scanné', () {
      expect(sql, contains('if public.code_partage_scanne(p_partage_id) then'));
    });

    test('Les cinq minutes vivent en base, à un seul endroit', () {
      expect(sql, contains("interval '5 minutes'"));

      final service = _codeSansCommentaires('lib/sharing/share_link_service.dart');
      final ecranCode = _codeSansCommentaires('lib/sharing/ecran_code_partage.dart');

      expect(service, isNot(contains('minutes: 5')));
      expect(ecranCode, isNot(contains('minutes: 5')));
    });

    test('Le refus a son propre message', () {
      // « Demandez un nouveau lien » enverrait chercher un SMS qui
      // n'existe pas : le parent est à côté de la personne.
      final consultation = _source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(consultation, contains('CODE_EXPIRE'));
      expect(consultation, contains('d’en afficher un nouveau'));
    });

    test('La page publique distingue ce refus des autres', () {
      final page = _codeSansCommentaires(
        'supabase/functions/_logique/page_partage.mts',
      );

      expect(page, contains("data.code === 'code_expire'"));
      expect(page, contains('Ce code n’est plus valable'));
    });
  });
}
