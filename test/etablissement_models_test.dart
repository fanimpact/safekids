import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/enfant_etablissement_data.dart';
import 'package:kidsrelay/models/etablissement_data.dart';
import 'package:kidsrelay/models/membre_etablissement_data.dart';

/// Vérifie le décodage des lignes Supabase pour l'espace professionnel
/// (établissements et rattachements enfant/établissement), et la
/// logique d'expiration côté parent — indépendamment de tout enfant
/// particulier, pour ne pas mélanger ce test avec ceux qui exercent
/// Théo/Noé sur le vrai rattachement bout-en-bout (couvert par des
/// tests manuels avec Supabase, voir le plan de l'espace professionnel).
void main() {
  group('EtablissementData', () {
    test('se construit depuis une ligne Supabase', () {
      final etablissement = EtablissementData.fromRow({
        'id': 'etab-1',
        'nom': 'École des Tilleuls',
        'type_etablissement': 'ecole',
      });

      expect(etablissement.id, equals('etab-1'));
      expect(etablissement.nom, equals('École des Tilleuls'));
      expect(etablissement.typeEtablissement, equals('ecole'));
    });
  });

  group('EnfantEtablissementData', () {
    test(
      'un rattachement en attente n’a pas encore de nom d’établissement',
      () {
        final rattachement = EnfantEtablissementData.fromRow({
          'id': 'rat-1',
          'token': 'abc123',
          'enfant_id': 'theo',
          'etablissement_id': null,
          'etablissements': null,
          'statut': 'en_attente',
          'date_creation': '2026-08-17T10:00:00.000Z',
          'date_expiration': '2026-09-17T10:00:00.000Z',
        });

        expect(rattachement.statut, equals(RattachementStatut.enAttente));
        expect(rattachement.etablissementNom, isNull);
        expect(rattachement.estExpire, isFalse);
      },
    );

    test(
      'un rattachement actif expose le nom de l’établissement rattaché',
      () {
        final rattachement = EnfantEtablissementData.fromRow({
          'id': 'rat-2',
          'token': 'def456',
          'enfant_id': 'noe',
          'etablissement_id': 'etab-1',
          'etablissements': {'nom': 'École des Tilleuls'},
          'statut': 'actif',
          'date_creation': '2026-08-17T10:00:00.000Z',
          'date_expiration': '2027-08-17T10:00:00.000Z',
        });

        expect(rattachement.statut, equals(RattachementStatut.actif));
        expect(
          rattachement.etablissementNom,
          equals('École des Tilleuls'),
        );
        expect(rattachement.estExpire, isFalse);
      },
    );

    test(
      'une date d’expiration passée est détectée, sauf si déjà révoqué',
      () {
        final expire = EnfantEtablissementData.fromRow({
          'id': 'rat-3',
          'token': 'ghi789',
          'enfant_id': 'theo',
          'etablissement_id': 'etab-1',
          'etablissements': {'nom': 'École des Tilleuls'},
          'statut': 'actif',
          'date_creation': '2025-01-01T10:00:00.000Z',
          'date_expiration': '2025-02-01T10:00:00.000Z',
        });

        expect(expire.estExpire, isTrue);

        final revoque = EnfantEtablissementData.fromRow({
          'id': 'rat-4',
          'token': 'jkl012',
          'enfant_id': 'theo',
          'etablissement_id': 'etab-1',
          'etablissements': {'nom': 'École des Tilleuls'},
          'statut': 'revoque',
          'date_creation': '2025-01-01T10:00:00.000Z',
          'date_expiration': '2025-02-01T10:00:00.000Z',
        });

        // Un rattachement déjà révoqué est signalé comme "révoqué",
        // pas comme "expiré" -- ce sont deux raisons différentes de ne
        // plus avoir accès, l'écran doit pouvoir les distinguer.
        expect(revoque.estExpire, isFalse);
        expect(revoque.statut, equals(RattachementStatut.revoque));
      },
    );
  });

  group('MembreEtablissementData', () {
    test(
      'une invitation en attente n’a pas encore de user_id',
      () {
        final membre = MembreEtablissementData.fromRow({
          'id': 'membre-1',
          'etablissement_id': 'etab-1',
          'email': 'collegue@ecole.fr',
          'user_id': null,
          'role': 'membre',
          'statut': 'invite',
          'invite_le': '2026-08-19T10:00:00.000Z',
          'accepte_le': null,
          'revoque_le': null,
        });

        expect(membre.statut, equals(StatutMembre.invite));
        expect(membre.role, equals(RoleEtablissement.membre));
        expect(membre.userId, isNull);
        expect(membre.accepteLe, isNull);
      },
    );

    test(
      'un membre actif expose son rôle et sa date d’acceptation',
      () {
        final membre = MembreEtablissementData.fromRow({
          'id': 'membre-2',
          'etablissement_id': 'etab-1',
          'email': 'adjointe@ecole.fr',
          'user_id': 'user-2',
          'role': 'adjoint',
          'statut': 'actif',
          'invite_le': '2026-08-17T10:00:00.000Z',
          'accepte_le': '2026-08-18T09:00:00.000Z',
          'revoque_le': null,
        });

        expect(membre.role, equals(RoleEtablissement.adjoint));
        expect(membre.statut, equals(StatutMembre.actif));
        expect(membre.userId, equals('user-2'));
        expect(
          membre.accepteLe,
          equals(DateTime.parse('2026-08-18T09:00:00.000Z')),
        );
      },
    );

    test('un membre révoqué garde sa date de révocation', () {
      final membre = MembreEtablissementData.fromRow({
        'id': 'membre-3',
        'etablissement_id': 'etab-1',
        'email': 'ancien@ecole.fr',
        'user_id': 'user-3',
        'role': 'membre',
        'statut': 'revoque',
        'invite_le': '2026-08-01T10:00:00.000Z',
        'accepte_le': '2026-08-02T10:00:00.000Z',
        'revoque_le': '2026-08-19T10:00:00.000Z',
      });

      expect(membre.statut, equals(StatutMembre.revoque));
      expect(
        membre.revoqueLe,
        equals(DateTime.parse('2026-08-19T10:00:00.000Z')),
      );
    });
  });
}
