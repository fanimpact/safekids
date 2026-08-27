import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/share_link_data.dart';

// La révocation sans effacement (27/08/2026).
//
// Avant : révoquer faisait un `delete` sur la ligne. L'accès était bien
// coupé, mais le parent perdait l'historique de ce qu'il avait partagé,
// et il ne restait aucune preuve que la révocation avait eu lieu.
//
// Désormais la ligne reste et porte `revoque_le`. Ce fichier teste ce
// qui décide de l'affichage — actif ou terminé — et vérifie par lecture
// de source que le service ne supprime plus.

ShareLinkData _lien({
  DateTime? dateExpiration,
  bool permanent = false,
  DateTime? revoqueLe,
  String? nomDestinataire,
  DateTime? dateDerniereConsultation,
}) {
  return ShareLinkData(
    id: 'partage-1',
    token: 'jeton',
    enfantId: 'enfant-1',
    ficheType: ShareFicheType.secours,
    destinataire: ShareDestinataire.particulier,
    dateCreation: DateTime(2026, 8, 20),
    dateExpiration: dateExpiration,
    dateDerniereConsultation: dateDerniereConsultation,
    nomDestinataire: nomDestinataire,
    permanent: permanent,
    revoqueLe: revoqueLe,
  );
}

/// Le code d'un fichier Dart, sans ses commentaires.
///
/// Une assertion « cette phrase a disparu » posee sur le fichier
/// entier se heurte au commentaire qui explique le retrait, et cite
/// donc la phrase retiree. Deja rencontre le 26/08/2026 sur les
/// scripts SQL : meme piege, meme parade.
String _codeSansCommentaires(String chemin) {
  return File(chemin)
      .readAsStringSync()
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('//'))
      .join('\n');
}

DateTime get _demain => DateTime.now().add(const Duration(days: 1));
DateTime get _hier => DateTime.now().subtract(const Duration(days: 1));

void main() {
  group('Actif, révoqué, expiré', () {
    test('Un lien à échéance future est actif', () {
      final lien = _lien(dateExpiration: _demain);

      expect(lien.estActif, isTrue);
      expect(lien.estExpire, isFalse);
      expect(lien.estRevoque, isFalse);
    });

    test('Un lien dont l’échéance est passée n’est plus actif', () {
      expect(_lien(dateExpiration: _hier).estActif, isFalse);
    });

    test('Un lien révoqué n’est plus actif, même avant l’échéance', () {
      // C'est tout l'objet du chantier : la ligne survit, l'accès non.
      final lien = _lien(
        dateExpiration: _demain,
        revoqueLe: DateTime(2026, 8, 26),
      );

      expect(lien.estRevoque, isTrue);
      expect(lien.estActif, isFalse);
    });

    test('Un lien permanent n’expire jamais', () {
      final lien = _lien(permanent: true);

      expect(lien.estExpire, isFalse);
      expect(lien.estActif, isTrue);
    });

    test('Un lien permanent révoqué n’est plus actif', () {
      // Seule la révocation peut arrêter un lien sans date de fin.
      final lien = _lien(
        permanent: true,
        revoqueLe: DateTime(2026, 8, 26),
      );

      expect(lien.estActif, isFalse);
    });

    test('Sans date et sans être permanent, le lien n’expire pas seul', () {
      // La contrainte en base l'interdit. Le modèle ne doit pas planter
      // pour autant : `estExpire` répond faux, et c'est le serveur qui
      // refusera l'ouverture.
      final lien = _lien();

      expect(lien.estExpire, isFalse);
      expect(lien.estActif, isTrue);
    });
  });

  group('La ligne rendue par la base se relit', () {
    test('Les colonnes nouvelles arrivent', () {
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': '2026-09-20T10:00:00Z',
        'date_derniere_consultation': null,
        'nom_destinataire': 'Aurélie, animatrice piscine',
        'permanent': false,
        'revoque_le': '2026-08-26T09:00:00Z',
      });

      expect(lien.nomDestinataire, 'Aurélie, animatrice piscine');
      expect(lien.permanent, isFalse);
      expect(lien.revoqueLe, isNotNull);
      expect(lien.estRevoque, isTrue);
    });

    test('Un lien permanent se relit sans date d’expiration', () {
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': null,
        'date_derniere_consultation': null,
        'nom_destinataire': null,
        'permanent': true,
        'revoque_le': null,
      });

      expect(lien.dateExpiration, isNull);
      expect(lien.permanent, isTrue);
      expect(lien.estActif, isTrue);
    });

    test('Une ligne d’avant la refonte se relit encore', () {
      // Les colonnes ajoutées le 27/08/2026 peuvent manquer d'une
      // réponse construite ailleurs : rien ne doit planter.
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': '2026-09-20T10:00:00Z',
        'date_derniere_consultation': null,
      });

      expect(lien.nomDestinataire, isNull);
      expect(lien.permanent, isFalse);
      expect(lien.revoqueLe, isNull);
      expect(lien.estActif, isTrue);
    });
  });

  group('Le service ne supprime plus', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('revokeLink marque au lieu d’effacer', () {
      final code = source('lib/sharing/share_link_service.dart');
      final debut = code.indexOf('Future<void> revokeLink');
      final fin = code.indexOf('Future<String> createLink');
      final methode = code.substring(debut, fin);

      expect(methode, contains("update({'revoque_le'"));
      expect(
        methode,
        isNot(contains('.delete()')),
        reason:
            'Le delete emportait l’historique du parent et la preuve '
            'que la révocation avait eu lieu',
      );
    });

    test('L’écran sépare les actifs des terminés', () {
      final code = source('lib/children/child_profile_page.dart');

      expect(code, contains('link.estActif'));
      expect(code, contains('Partages terminés'));
      expect(code, contains('_partageTermineCard('));
    });

    test('Un partage terminé n’offre pas de bouton de révocation', () {
      // Proposer un geste sans effet ferait douter de ce que l'écran
      // dit par ailleurs.
      final code = source('lib/children/child_profile_page.dart');
      final debut = code.indexOf('Widget _partageTermineCard(');
      final fin = code.indexOf('Widget _partageCard(');
      final methode = code.substring(debut, fin);

      expect(methode, isNot(contains('onRevoke')));
    });
  });

  group('Le serveur refuse un lien révoqué', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('La révocation est vérifiée avant l’échéance', () {
      // L'ordre compte : un lien révoqué mais non expiré doit être
      // refusé, et un lien permanent n'a pas d'échéance à comparer.
      final code = source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(code, contains("statut: 'lienRevoque'"));
      expect(
        code.indexOf('partage.revoque_le'),
        lessThan(code.indexOf('lienEncoreValide(\n      partage')),
      );
    });

    test('Un lien révoqué répond comme un lien expiré', () {
      // Dire « révoqué » apprendrait à qui détient le lien que le
      // parent a coupé l'accès volontairement. Cela ne le regarde pas.
      final code = source(
        'supabase/functions/consulter-partage/index.ts',
      );

      expect(code, contains("case 'lienRevoque':"));
      expect(code, contains('return erreur(410);'));
    });
  });

  group('Le nom du destinataire', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('Le champ est proposé à la création, et obligatoire', () {
      // Obligatoire depuis le 27/08/2026 : sans nom, la liste devient
      // une suite de lignes indistinctes, et un parent qui ne sait
      // plus a quoi correspond un lien ne le revoquera jamais.
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('À qui donnez-vous ce lien ?'));
      expect(code, contains('_nomDestinataireController'));
      expect(code, contains('Aurélie, animatrice piscine'));
      expect(
        code,
        isNot(contains('Facultatif')),
        reason: 'Le champ n’est plus facultatif depuis le 27/08/2026',
      );
    });

    test('La génération est refusée si le champ est vide', () {
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('if (nomDestinataire == null)'));
      expect(
        code,
        contains('Indiquez à qui vous donnez ce lien.'),
      );

      // Le refus doit tomber AVANT l'ecriture, jamais apres.
      expect(
        code.indexOf('if (nomDestinataire == null)'),
        lessThan(code.indexOf('createLink(')),
      );
    });

    test('La base refuse aussi, elle ne fait pas confiance à l’écran',
        () {
      final sql =
          source('supabase/schema_partages_refonte.sql');

      expect(
        sql,
        contains('alter column nom_destinataire set not null'),
      );
      expect(
        sql,
        contains('check (length(trim(nom_destinataire)) > 0)'),
        reason:
            'Un nom fait uniquement d’espaces passe « not null » sans '
            'rien nommer',
      );
    });

    test('L’écran dit que ce nom ne sort pas de l’application', () {
      // Sans cette ligne, un parent peut croire que la personne qui
      // ouvre le lien voit le nom qu'il a saisi.
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('n’apparaît'));
      expect(code, contains('la fiche partagée'));
    });

    test('Une saisie vide part en `null`, jamais en chaîne vide', () {
      // Une colonne qui contient '' se lit comme « nommé, mais sans
      // nom » : l'écran afficherait un tiret suivi de rien.
      final code = source('lib/sharing/create_share_link_page.dart');
      final debut = code.indexOf('String? _nomDestinataireSaisi()');
      final fin = code.indexOf('Future<void> _copyLink()');

      expect(
        code.substring(debut, fin),
        contains('saisie.isEmpty ? null : saisie'),
      );
    });

    test('Le service l’écrit dans sa propre colonne', () {
      // Jamais dans `destinataire`, qui porte le choix particulier /
      // structure d'accueil et gouverne la mention accolée aux
      // traitements.
      final code = source('lib/sharing/share_link_service.dart');

      expect(code, contains("'nom_destinataire': nomDestinataire,"));
      expect(code, contains("'destinataire': destinataire,"));
    });

    test('Il passe en tête de carte, le type de fiche en second', () {
      expect(
        _lien(
          dateExpiration: _demain,
          nomDestinataire: 'Aurélie, animatrice piscine',
        ).nomDestinataire,
        'Aurélie, animatrice piscine',
      );

      final code = source('lib/children/child_profile_page.dart');
      final debut = code.indexOf('String _shareLinkTitle(');
      final fin = code.indexOf('String _shareLinkStatusLabel(');

      expect(
        code.substring(debut, fin),
        contains('link.ficheType.label'),
        reason: 'Un lien sans nom reste identifiable par sa fiche',
      );
    });
  });

  group('Les durées, libérées du plafond de 7 jours', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/sharing/create_share_link_page.dart');

    test('Les quatre raccourcis sont proposés', () {
      for (final libelle in [
        "'24 heures'",
        "'7 jours'",
        "'1 mois'",
        "'1 an'",
      ]) {
        expect(
          ecran,
          contains(libelle),
          reason: '$libelle manque dans les raccourcis',
        );
      }
    });

    test('Le plafond de 7 jours a sauté', () {
      // « 3 jours » était le seul intermédiaire d'une échelle qui
      // s'arrêtait à une semaine. L'échelle va maintenant à l'année.
      expect(ecran, isNot(contains("jours3('3 jours'")));
      expect(ecran, contains("mois1('1 mois'"));
      expect(ecran, contains("an1('1 an'"));
    });

    test('La date libre et le permanent sont proposés', () {
      expect(ecran, contains("dateChoisie('Choisir une date'"));
      expect(ecran, contains("permanent('Sans date de fin'"));
      expect(ecran, contains('showDatePicker('));
    });

    test('La phrase qui disait qu’on ne peut pas prolonger a disparu',
        () {
      // Elle est devenue fausse : le parent peut désormais modifier
      // l'échéance d'un partage en cours.
      final code = _codeSansCommentaires(
        'lib/sharing/create_share_link_page.dart',
      );

      expect(code, isNot(contains('ne peut pas être prolongé')));
      expect(code, contains('Vous pourrez '));
    });

    test('« Choisir une date » sans date choisie est refusé', () {
      // Le choix ne vaut rien tant qu'aucune date n'est retenue : sans
      // ce refus, la génération partirait sans échéance.
      expect(ecran, contains('Choisissez la date de fin du lien.'));
      expect(
        ecran.indexOf('Choisissez la date de fin du lien.'),
        lessThan(ecran.indexOf('createLink(')),
      );
    });

    test('Le lien permanent annonce le rappel semestriel', () {
      // Un lien qui n'expire jamais demande que le parent garde la
      // main dessus. Le lui dire à la création vaut mieux que de le
      // découvrir six mois plus tard.
      expect(ecran, contains('n’a pas de date de fin'));
      expect(ecran, contains('Tous les 6 mois'));
    });

    test('Le service accepte une échéance nulle et le drapeau', () {
      final service = source('lib/sharing/share_link_service.dart');

      expect(service, contains('required DateTime? dateExpiration'));
      expect(service, contains('bool permanent = false'));
      expect(service, contains("'permanent': permanent,"));
    });
  });
}
