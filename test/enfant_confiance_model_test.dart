import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/enfant_confiance_data.dart';

/// Vérifie le décodage des lignes Supabase pour le partage de la
/// fiche d'un enfant avec un co-parent ou un tuteur — corrections de
/// l'inventaire du 19/08/2026, point 9.
void main() {
  group('EnfantConfianceData', () {
    test(
      'une invitation en attente n’a pas encore de user_id ni de '
      'date d’acceptation',
      () {
        final confiance = EnfantConfianceData.fromRow({
          'id': 'confiance-1',
          'enfant_id': 'theo',
          'email': 'coparent@example.com',
          'user_id': null,
          'niveau_acces': 'lecture',
          'statut': 'invite',
          'invite_le': '2026-08-19T10:00:00.000Z',
          'accepte_le': null,
          'revoque_le': null,
        });

        expect(
          confiance.niveauAcces,
          equals(NiveauAccesConfiance.lecture),
        );
        expect(confiance.statut, equals(StatutConfiance.invite));
        expect(confiance.userId, isNull);
        expect(confiance.accepteLe, isNull);
      },
    );

    test(
      'un accès actif en lecture/écriture expose son niveau et sa '
      'date d’acceptation',
      () {
        final confiance = EnfantConfianceData.fromRow({
          'id': 'confiance-2',
          'enfant_id': 'noe',
          'email': 'tuteur@example.com',
          'user_id': 'user-2',
          'niveau_acces': 'lecture_ecriture',
          'statut': 'actif',
          'invite_le': '2026-08-17T10:00:00.000Z',
          'accepte_le': '2026-08-18T09:00:00.000Z',
          'revoque_le': null,
        });

        expect(
          confiance.niveauAcces,
          equals(NiveauAccesConfiance.lectureEcriture),
        );
        expect(confiance.statut, equals(StatutConfiance.actif));
        expect(confiance.userId, equals('user-2'));
        expect(
          confiance.accepteLe,
          equals(DateTime.parse('2026-08-18T09:00:00.000Z')),
        );
      },
    );

    test('un accès révoqué garde sa date de révocation', () {
      final confiance = EnfantConfianceData.fromRow({
        'id': 'confiance-3',
        'enfant_id': 'theo',
        'email': 'ancien@example.com',
        'user_id': 'user-3',
        'niveau_acces': 'lecture',
        'statut': 'revoque',
        'invite_le': '2026-08-01T10:00:00.000Z',
        'accepte_le': '2026-08-02T10:00:00.000Z',
        'revoque_le': '2026-08-19T10:00:00.000Z',
      });

      expect(confiance.statut, equals(StatutConfiance.revoque));
      expect(
        confiance.revoqueLe,
        equals(DateTime.parse('2026-08-19T10:00:00.000Z')),
      );
    });
  });

  group('niveauAccesToValue', () {
    test('reconvertit chaque niveau vers sa valeur SQL', () {
      expect(
        niveauAccesToValue(NiveauAccesConfiance.lecture),
        equals('lecture'),
      );
      expect(
        niveauAccesToValue(NiveauAccesConfiance.lectureEcriture),
        equals('lecture_ecriture'),
      );
    });
  });
}
