import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_pages/activity_recommendations_page.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/activity_session/complete_activity_session_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
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
import 'package:kidsrelay/recommendation_engine/recommendation_engine.dart';
import 'package:kidsrelay/repositories/child_repository.dart';

/// Le repas DÉPLACE l'allergie alimentaire, il ne la duplique pas et
/// ne la fait jamais disparaître (22/08/2026) :
///
/// - activité avec repas → l'allergie alimentaire est rattachée à la
///   situation "Repas" (`meals_food_allergy_*`), et n'apparaît plus en
///   vigilance générale ;
/// - activité sans repas → elle reste exactement où elle était
///   (`allergy_condition_*`), comme avant la section Repas ;
/// - une allergie non alimentaire ne bouge jamais.
void main() {
  ChildProfileData buildChild({
    required String childId,
    required List<AllergyData> allergies,
  }) {
    return ChildProfileData(
      childId: childId,
      userId: 'test-user',
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
    );
  }

  ActivityProfileData buildActivityProfile() {
    return ActivityProfileData(
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
      meals: MealsData(),
    );
  }

  List<Recommendation> recommendationsFor({
    required String childId,
    required List<AllergyData> allergies,
    required bool hasMeal,
  }) {
    ChildRepository.instance.clearForTesting();

    ChildRepository.instance.seedForTesting(
      buildChild(childId: childId, allergies: allergies),
    );
    ChildRepository.instance.seedActivityProfileForTesting(
      childId: childId,
      activityProfile: buildActivityProfile(),
    );

    final session = CompleteActivitySessionData(
      id: 'activite-1',
      activity: ActivitySessionData(
        activityName: 'Sortie',
        hasMeal: hasMeal,
      ),
      childIds: [childId],
    );

    return RecommendationEngine()
        .generateRecommendations(session)
        .childResults
        .expand((result) => result.recommendations)
        .toList();
  }

  AllergyData foodAllergy() {
    return AllergyData(
      allergyId: 'a-food',
      categories: {AllergyCategory.food},
      details: {AllergyCategory.food: 'Arachide'},
      observedReaction: 'Œdème',
    );
  }

  AllergyData insectAllergy() {
    return AllergyData(
      allergyId: 'a-insect',
      categories: {AllergyCategory.insectSting},
      details: {AllergyCategory.insectSting: 'Guêpe'},
    );
  }

  setUp(() {
    ChildRepository.instance.clearForTesting();
  });

  test(
    'Activité avec repas : l’allergie alimentaire passe côté Repas, '
    'et une seule fois',
    () {
      final recommendations = recommendationsFor(
        childId: 'enfant-avec-repas',
        allergies: [foodAllergy()],
        hasMeal: true,
      );

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toList();

      expect(ids, contains('meals_food_allergy_a-food'));
      expect(
        ids,
        isNot(contains('allergy_condition_a-food')),
        reason:
            'Sinon l’allergie serait affichée deux fois : une fois en '
            'haut de fiche, une fois dans le bloc Repas.',
      );

      expect(
        recommendations
            .where(
              (recommendation) =>
                  recommendation.text.contains('Arachide'),
            )
            .length,
        equals(1),
      );
    },
  );

  test(
    'Activité sans repas : l’allergie alimentaire reste où elle était',
    () {
      final ids = recommendationsFor(
        childId: 'enfant-sans-repas',
        allergies: [foodAllergy()],
        hasMeal: false,
      ).map((recommendation) => recommendation.id).toList();

      expect(
        ids,
        contains('allergy_condition_a-food'),
        reason:
            'Le repas déplace l’information ; sans repas prévu, rien '
            'ne change par rapport à avant la section Repas.',
      );
      expect(ids, isNot(contains('meals_food_allergy_a-food')));
    },
  );

  test(
    'Une allergie non alimentaire ne bouge jamais, repas ou pas',
    () {
      for (final hasMeal in [true, false]) {
        final ids = recommendationsFor(
          childId: 'enfant-guepe-$hasMeal',
          allergies: [insectAllergy()],
          hasMeal: hasMeal,
        ).map((recommendation) => recommendation.id).toList();

        expect(
          ids,
          contains('allergy_condition_a-insect'),
          reason: 'Repas prévu : $hasMeal.',
        );
        expect(
          ids,
          isNot(contains('meals_food_allergy_a-insect')),
        );
      }
    },
  );

  test(
    'Deux allergies de types différents : seule l’alimentaire passe '
    'côté Repas',
    () {
      final ids = recommendationsFor(
        childId: 'enfant-deux-allergies',
        allergies: [foodAllergy(), insectAllergy()],
        hasMeal: true,
      ).map((recommendation) => recommendation.id).toList();

      expect(ids, contains('meals_food_allergy_a-food'));
      expect(ids, contains('allergy_condition_a-insect'));
      expect(ids, isNot(contains('allergy_condition_a-food')));
      expect(ids, isNot(contains('meals_food_allergy_a-insect')));
    },
  );

  test(
    'Une allergie sans type enregistré passe côté Repas plutôt que de '
    'disparaître',
    () {
      final ids = recommendationsFor(
        childId: 'enfant-allergie-ancienne',
        allergies: [
          AllergyData(
            allergyId: 'a-legacy',
            legacyAllergen: 'Arachides',
          ),
        ],
        hasMeal: true,
      ).map((recommendation) => recommendation.id).toList();

      expect(ids, contains('meals_food_allergy_a-legacy'));
      expect(ids, isNot(contains('allergy_condition_a-legacy')));
    },
  );

  testWidgets(
    'Sur la fiche d’activité, les recommandations repas sont '
    'regroupées sous "Repas" — et seulement si un repas est prévu',
    (tester) async {
      Future<void> pumpSheet({required bool hasMeal}) async {
        ChildRepository.instance.clearForTesting();

        ChildRepository.instance.seedForTesting(
          buildChild(childId: 'enfant-bloc', allergies: const []),
        );
        ChildRepository.instance.seedActivityProfileForTesting(
          childId: 'enfant-bloc',
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
            // Une adaptation, et non un équipement : le matériel est
            // aussi repris dans le récapitulatif "Matériel à prévoir",
            // ce qui rendrait le comptage ambigu.
            meals: MealsData(
              requiresIncreasedHydration: true,
            ),
          ),
        );

        final session = CompleteActivitySessionData(
          id: 'activite-1',
          activity: ActivitySessionData(
            activityName: 'Sortie',
            hasMeal: hasMeal,
          ),
          childIds: const ['enfant-bloc'],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityRecommendationsPage(
              activitySession: session,
              recommendationResult: RecommendationEngine()
                  .generateRecommendations(session),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpSheet(hasMeal: true);

      expect(find.text('Repas'), findsOneWidget);
      expect(
        find.textContaining('Hydratation renforcée'),
        findsOneWidget,
      );

      await pumpSheet(hasMeal: false);

      expect(find.text('Repas'), findsNothing);
      expect(
        find.textContaining('Hydratation renforcée'),
        findsNothing,
        reason:
            'Sans repas prévu, la section Repas du profil ne remonte '
            'pas sur la fiche — comme la baignade sans point d’eau.',
      );
    },
  );

  test(
    'Quel que soit le cas, l’allergie reste critique donc non '
    'masquable',
    () {
      for (final hasMeal in [true, false]) {
        final recommendation = recommendationsFor(
          childId: 'enfant-criticite-$hasMeal',
          allergies: [foodAllergy()],
          hasMeal: hasMeal,
        ).firstWhere(
          (item) => item.text.contains('Arachide'),
        );

        expect(
          recommendation.isCritical,
          isTrue,
          reason:
              'Une allergie ne doit jamais pouvoir disparaître d’une '
              'fiche (repas prévu : $hasMeal).',
        );
      }
    },
  );
}
