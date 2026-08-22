import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/allergy_data.dart';

/// Catégorisation des allergies (22/08/2026) : l'ancien champ libre
/// unique "À quoi votre enfant est-il allergique ?" est remplacé par
/// des types cochés, chacun portant sa propre précision. Ce qui rend
/// possible de faire ressortir la seule allergie alimentaire au moment
/// du repas, au lieu d'afficher toutes les allergies en haut de fiche.
void main() {
  group('Libellé affiché', () {
    test(
      'Reprend les précisions des types cochés, dans l’ordre de '
      'l’énumération',
      () {
        final allergy = AllergyData(
          categories: {
            AllergyCategory.medication,
            AllergyCategory.food,
          },
          details: {
            AllergyCategory.medication: 'Pénicilline',
            AllergyCategory.food: 'Arachide',
          },
        );

        expect(
          allergy.label,
          equals('Arachide / Pénicilline'),
          reason:
              'L’ordre d’affichage suit l’énumération, pas l’ordre de '
              'saisie — la même allergie doit se lire pareil partout.',
        );
      },
    );

    test(
      'Ignore un type coché dont la précision est vide',
      () {
        final allergy = AllergyData(
          categories: {
            AllergyCategory.food,
            AllergyCategory.other,
          },
          details: {
            AllergyCategory.food: 'Arachide',
            AllergyCategory.other: '   ',
          },
        );

        expect(allergy.label, equals('Arachide'));
      },
    );

    test(
      'Vaut null quand il n’y a rien à afficher',
      () {
        expect(AllergyData().label, isNull);
      },
    );
  });

  group('Allergie enregistrée avant la catégorisation', () {
    test(
      'Retombe sur l’ancien champ pour l’affichage',
      () {
        final allergy = AllergyData(legacyAllergen: 'Arachides');

        expect(allergy.label, equals('Arachides'));
      },
    );

    test(
      'Remonte au repas, faute de savoir si elle est alimentaire',
      () {
        final allergy = AllergyData(legacyAllergen: 'Arachides');

        expect(allergy.isFood, isFalse);
        expect(
          allergy.concernsMeals,
          isTrue,
          reason:
              'Le repli demandé est de continuer à l’afficher partout '
              'plutôt que de la faire disparaître d’une fiche parce '
              'qu’on ignore son type.',
        );
      },
    );
  });

  group('Ce qui remonte au moment du repas', () {
    test('Une allergie alimentaire, oui', () {
      final allergy = AllergyData(
        categories: {AllergyCategory.food},
        details: {AllergyCategory.food: 'Arachide'},
      );

      expect(allergy.isFood, isTrue);
      expect(allergy.concernsMeals, isTrue);
    });

    test('Une allergie non alimentaire, non', () {
      final allergy = AllergyData(
        categories: {AllergyCategory.insectSting},
        details: {AllergyCategory.insectSting: 'Guêpe'},
      );

      expect(allergy.isFood, isFalse);
      expect(
        allergy.concernsMeals,
        isFalse,
        reason:
            'Une allergie aux piqûres n’a rien à faire dans la '
            'section repas.',
      );
    });

    test(
      'Une allergie à la fois alimentaire et médicamenteuse, oui',
      () {
        final allergy = AllergyData(
          categories: {
            AllergyCategory.food,
            AllergyCategory.medication,
          },
          details: {
            AllergyCategory.food: 'Lait',
            AllergyCategory.medication: 'Sirop lacté',
          },
        );

        expect(allergy.concernsMeals, isTrue);
      },
    );
  });

  group('Sérialisation', () {
    test(
      'Aller-retour JSON : types, précisions et réaction conservés',
      () {
        final allergy = AllergyData(
          allergyId: 'allergie-1',
          categories: {
            AllergyCategory.food,
            AllergyCategory.contactOrEnvironment,
          },
          details: {
            AllergyCategory.food: 'Arachide',
            AllergyCategory.contactOrEnvironment: 'Latex',
          },
          observedReaction: 'Œdème',
          emergencyInstructionSteps: ['Appeler le 15'],
        );

        final restored = AllergyData.fromJson(allergy.toJson());

        expect(restored.allergyId, equals('allergie-1'));
        expect(
          restored.categories,
          equals({
            AllergyCategory.food,
            AllergyCategory.contactOrEnvironment,
          }),
        );
        expect(restored.details[AllergyCategory.food], equals('Arachide'));
        expect(
          restored.details[AllergyCategory.contactOrEnvironment],
          equals('Latex'),
        );
        expect(restored.observedReaction, equals('Œdème'));
        expect(
          restored.emergencyInstructionSteps,
          equals(['Appeler le 15']),
        );
        expect(restored.label, equals('Arachide / Latex'));
      },
    );

    test(
      'Un enregistrement antérieur, qui n’a que la clé "allergen", '
      'reste lisible',
      () {
        final restored = AllergyData.fromJson({
          'allergyId': 'allergie-ancienne',
          'allergen': 'Arachides',
          'observedReaction': 'Œdème',
        });

        expect(restored.categories, isEmpty);
        expect(restored.label, equals('Arachides'));
        expect(restored.concernsMeals, isTrue);
      },
    );

    test(
      'Un type inconnu dans le JSON est ignoré, sans faire échouer la '
      'lecture du reste',
      () {
        final restored = AllergyData.fromJson({
          'categories': ['food', 'type_invente_par_une_version_future'],
          'details': {'food': 'Arachide'},
        });

        expect(restored.categories, equals({AllergyCategory.food}));
        expect(restored.label, equals('Arachide'));
      },
    );
  });
}
