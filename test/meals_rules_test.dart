import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/meals_data.dart';
import 'package:kidsrelay/models/other_information_data.dart';
import 'package:kidsrelay/models/overnight_stay_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/safety_data.dart';
import 'package:kidsrelay/models/toilets_data.dart';
import 'package:kidsrelay/models/transitions_data.dart';
import 'package:kidsrelay/models/transport_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/models/walking_effort_data.dart';
import 'package:kidsrelay/recommendation_engine/models/recommendation.dart';
import 'package:kidsrelay/recommendation_engine/models/recommendation_category.dart';
import 'package:kidsrelay/recommendation_engine/rules/meals_rules.dart';

/// Section Repas (22/08/2026). Tout est conditionné à la question
/// "Cette activité comprend-elle un repas, un goûter ou une
/// collation ?", comme la baignade l'est à la présence d'eau.
void main() {
  const rules = MealsRules();

  CompleteChildProfileData buildChild({
    required MealsData meals,
    List<AllergyData> allergies = const [],
  }) {
    return CompleteChildProfileData(
      essentialInformation: ChildProfileData(
        childId: 'enfant-repas',
        userId: 'test-family',
        identity: IdentityData(firstName: 'Camille'),
        pathologies: const [],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: allergies,
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      ),
      activityProfile: ActivityProfileData(
        aquaticActivity: AquaticActivityData(),
        transport: TransportData(),
        walkingEffort: WalkingEffortData(),
        overnightStay: OvernightStayData(),
        clothing: ClothingData(),
        toilets: ToiletsData(),
        communication: CommunicationData(),
        transitions: TransitionsData(),
        safety: SafetyData(),
        otherInformation: OtherInformationData(),
        meals: meals,
      ),
    );
  }

  ActivitySessionData session({required bool? hasMeal}) {
    return ActivitySessionData(hasMeal: hasMeal);
  }

  Recommendation? findById(
    List<Recommendation> recommendations,
    String id,
  ) {
    for (final recommendation in recommendations) {
      if (recommendation.id == id) {
        return recommendation;
      }
    }

    return null;
  }

  group('Déclenchement par l’activité', () {
    test(
      'Sans repas prévu, la section Repas ne remonte pas',
      () {
        final child = buildChild(
          meals: MealsData(
            hasChokingRisk: true,
            requiresIncreasedHydration: true,
          ),
          allergies: [
            AllergyData(
              categories: {AllergyCategory.food},
              details: {AllergyCategory.food: 'Arachide'},
            ),
          ],
        );

        expect(
          rules.evaluate(child, session(hasMeal: false)),
          isEmpty,
        );
      },
    );

    test(
      'Question sans réponse : rien non plus, on ne suppose pas qu’il '
      'y a un repas',
      () {
        final child = buildChild(
          meals: MealsData(hasChokingRisk: true),
        );

        expect(
          rules.evaluate(child, session(hasMeal: null)),
          isEmpty,
        );
      },
    );

    test(
      'Avec un repas prévu, la section remonte',
      () {
        final child = buildChild(
          meals: MealsData(hasChokingRisk: true),
        );

        expect(
          rules.evaluate(child, session(hasMeal: true)),
          isNotEmpty,
        );
      },
    );
  });

  group('Risque de fausse route', () {
    test(
      'Critique, donc jamais masquable',
      () {
        final child = buildChild(
          meals: MealsData(hasChokingRisk: true),
        );

        final recommendation = findById(
          rules.evaluate(child, session(hasMeal: true)),
          'meals_choking_risk',
        );

        expect(recommendation, isNotNull);
        expect(recommendation!.isCritical, isTrue);
        expect(
          recommendation.category,
          equals(RecommendationCategory.informationVigilance),
        );
      },
    );

    test(
      'La préparation figure dans la même recommandation, pas dans '
      'une ligne séparée qui pourrait être masquée',
      () {
        final child = buildChild(
          meals: MealsData(
            hasChokingRisk: true,
            preparations: {
              MealPreparation.smallPieces,
              MealPreparation.thickenedDrinks,
            },
          ),
        );

        final recommendations =
            rules.evaluate(child, session(hasMeal: true));

        final recommendation = findById(
          recommendations,
          'meals_choking_risk',
        );

        expect(
          recommendation!.text,
          contains('couper en petits morceaux'),
        );
        expect(recommendation.text, contains('boissons épaissies'));

        expect(
          recommendations.where(
            (item) =>
                item.id != 'meals_choking_risk' &&
                item.text.contains('couper en petits morceaux'),
          ),
          isEmpty,
          reason:
              'Séparée, la préparation serait masquable alors que '
              'l’alerte ne l’est pas.',
        );
      },
    );

    test(
      'La préparation "Autre" reprend le texte du parent',
      () {
        final child = buildChild(
          meals: MealsData(
            hasChokingRisk: true,
            preparations: {MealPreparation.other},
            otherPreparationDetails: 'Éviter les aliments filandreux',
          ),
        );

        expect(
          findById(
            rules.evaluate(child, session(hasMeal: true)),
            'meals_choking_risk',
          )!
              .text,
          contains('Éviter les aliments filandreux'),
        );
      },
    );

    test(
      'Répondu "Non" : aucune recommandation',
      () {
        final child = buildChild(
          meals: MealsData(hasChokingRisk: false),
        );

        expect(
          findById(
            rules.evaluate(child, session(hasMeal: true)),
            'meals_choking_risk',
          ),
          isNull,
        );
      },
    );
  });

  group('Allergie alimentaire reprise du profil santé', () {
    test(
      'Une allergie alimentaire remonte, critique',
      () {
        final child = buildChild(
          meals: MealsData(),
          allergies: [
            AllergyData(
              allergyId: 'a1',
              categories: {AllergyCategory.food},
              details: {AllergyCategory.food: 'Arachide'},
              observedReaction: 'Œdème',
            ),
          ],
        );

        final recommendation = findById(
          rules.evaluate(child, session(hasMeal: true)),
          'meals_food_allergy_a1',
        );

        expect(recommendation, isNotNull);
        expect(recommendation!.isCritical, isTrue);
        expect(recommendation.text, contains('Arachide'));
        expect(recommendation.text, contains('Œdème'));
      },
    );

    test(
      'Une allergie non alimentaire ne remonte pas au repas',
      () {
        final child = buildChild(
          meals: MealsData(),
          allergies: [
            AllergyData(
              allergyId: 'a2',
              categories: {AllergyCategory.insectSting},
              details: {AllergyCategory.insectSting: 'Guêpe'},
            ),
          ],
        );

        expect(
          findById(
            rules.evaluate(child, session(hasMeal: true)),
            'meals_food_allergy_a2',
          ),
          isNull,
        );
      },
    );

    test(
      'Une allergie sans type enregistré remonte quand même',
      () {
        final child = buildChild(
          meals: MealsData(),
          allergies: [
            AllergyData(
              allergyId: 'a3',
              legacyAllergen: 'Arachides',
            ),
          ],
        );

        expect(
          findById(
            rules.evaluate(child, session(hasMeal: true)),
            'meals_food_allergy_a3',
          ),
          isNotNull,
          reason:
              'Mieux vaut la signaler à tort que la taire faute de '
              'savoir si elle est alimentaire.',
        );
      },
    );
  });

  group('Autonomie et alimentation', () {
    test('Le niveau d’aide produit sa consigne', () {
      final child = buildChild(
        meals: MealsData(
          requiresAssistance: true,
          assistanceLevel: MealAssistanceLevel.fullyFedByAdult,
        ),
      );

      expect(
        findById(
          rules.evaluate(child, session(hasMeal: true)),
          'meals_assistance',
        )!
            .text,
        contains('nourri entièrement par un adulte'),
      );
    });

    test(
      'Une aide déclarée sans niveau choisi ne produit pas de '
      'consigne vague',
      () {
        final child = buildChild(
          meals: MealsData(requiresAssistance: true),
        );

        expect(
          findById(
            rules.evaluate(child, session(hasMeal: true)),
            'meals_assistance',
          ),
          isNull,
        );
      },
    );

    test('Le matériel est classé comme équipement', () {
      final child = buildChild(
        meals: MealsData(
          requiresSpecialEquipment: true,
          specialEquipmentDetails: 'Verre à bec',
        ),
      );

      final recommendation = findById(
        rules.evaluate(child, session(hasMeal: true)),
        'meals_equipment',
      );

      expect(
        recommendation!.category,
        equals(RecommendationCategory.equipment),
      );
      expect(recommendation.text, contains('Verre à bec'));
      expect(recommendation.isCritical, isFalse);
    });

    test('L’hydratation renforcée produit une adaptation', () {
      final child = buildChild(
        meals: MealsData(requiresIncreasedHydration: true),
      );

      expect(
        findById(
          rules.evaluate(child, session(hasMeal: true)),
          'meals_hydration',
        ),
        isNotNull,
      );
    });

    test('Les régimes sont listés ensemble', () {
      final child = buildChild(
        meals: MealsData(
          hasDietaryRestrictions: true,
          dietaryRestrictions: {
            MealDietaryRestriction.glutenFree,
            MealDietaryRestriction.other,
          },
          otherDietaryRestrictionDetails: 'sans fruits à coque',
        ),
      );

      final recommendation = findById(
        rules.evaluate(child, session(hasMeal: true)),
        'meals_dietary_restrictions',
      );

      expect(recommendation!.text, contains('sans gluten'));
      expect(recommendation.text, contains('sans fruits à coque'));
    });

    test(
      'Le refus alimentaire précise la conduite à tenir',
      () {
        final child = buildChild(
          meals: MealsData(
            hasFoodRefusals: true,
            foodRefusalDetails: 'Légumes verts',
            refusalStance: MealRefusalStance.offerWithoutInsisting,
          ),
        );

        final recommendation = findById(
          rules.evaluate(child, session(hasMeal: true)),
          'meals_food_refusal',
        );

        expect(recommendation!.text, contains('Légumes verts'));
        expect(
          recommendation.text,
          contains('proposer sans insister'),
        );
      },
    );
  });

  group('Masquabilité', () {
    test(
      'Seuls le risque de fausse route et l’allergie alimentaire sont '
      'critiques ; tout le reste est masquable',
      () {
        final child = buildChild(
          meals: MealsData(
            hasChokingRisk: true,
            requiresSpecificSeating: true,
            seatingDetails: 'Chaise à accoudoirs',
            hasWarningSigns: true,
            warningSignsDetails: 'Toux répétée : arrêter le repas',
            requiresAssistance: true,
            assistanceLevel: MealAssistanceLevel.adultNearby,
            requiresSpecialEquipment: true,
            specialEquipmentDetails: 'Verre à bec',
            requiresIncreasedHydration: true,
            hasDietaryRestrictions: true,
            dietaryRestrictions: {MealDietaryRestriction.lactoseFree},
            hasFoodRefusals: true,
            foodRefusalDetails: 'Légumes verts',
            refusalStance: MealRefusalStance.doNotInsist,
            hasOtherInformation: true,
            otherInformationDetails: 'Mange lentement',
          ),
          allergies: [
            AllergyData(
              allergyId: 'a1',
              categories: {AllergyCategory.food},
              details: {AllergyCategory.food: 'Arachide'},
            ),
          ],
        );

        final recommendations =
            rules.evaluate(child, session(hasMeal: true));

        final criticalIds = recommendations
            .where((recommendation) => recommendation.isCritical)
            .map((recommendation) => recommendation.id)
            .toSet();

        expect(
          criticalIds,
          equals({'meals_choking_risk', 'meals_food_allergy_a1'}),
        );
      },
    );

    test(
      'Toutes les recommandations portent le préfixe meals_, qui les '
      'range dans la situation "Repas" de la fiche',
      () {
        final child = buildChild(
          meals: MealsData(
            hasChokingRisk: true,
            requiresIncreasedHydration: true,
            hasOtherInformation: true,
            otherInformationDetails: 'Mange lentement',
          ),
        );

        final recommendations =
            rules.evaluate(child, session(hasMeal: true));

        expect(recommendations, isNotEmpty);
        expect(
          recommendations.every(
            (recommendation) =>
                recommendation.id.startsWith('meals_'),
          ),
          isTrue,
        );
      },
    );
  });
}
