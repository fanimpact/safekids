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
}
