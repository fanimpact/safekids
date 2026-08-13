import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/utils/age_utils.dart';

void main() {
  final referenceDate = DateTime(2026, 8, 13);

  test(
    'Âge - date de naissance absente renvoie null',
    () {
      expect(
        formatAge(null, now: referenceDate),
        isNull,
      );
    },
  );

  test(
    'Âge - anniversaire déjà passé cette année',
    () {
      final dateOfBirth = DateTime(2016, 3, 10);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '10 ans',
      );
    },
  );

  test(
    'Âge - anniversaire pas encore passé cette année',
    () {
      final dateOfBirth = DateTime(2016, 12, 1);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '9 ans',
      );
    },
  );

  test(
    'Âge - anniversaire exactement aujourd’hui',
    () {
      final dateOfBirth = DateTime(2020, 8, 13);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '6 ans',
      );
    },
  );

  test(
    'Âge - moins d’un an s’affiche au singulier',
    () {
      final dateOfBirth = DateTime(2026, 1, 1);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '0 an',
      );
    },
  );

  test(
    'Âge - un an s’affiche au singulier',
    () {
      final dateOfBirth = DateTime(2025, 3, 1);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '1 an',
      );
    },
  );

  test(
    'Âge - date de naissance dans le futur ne renvoie pas de nombre négatif',
    () {
      final dateOfBirth = DateTime(2027, 1, 1);

      expect(
        formatAge(dateOfBirth, now: referenceDate),
        '0 an',
      );
    },
  );
}
