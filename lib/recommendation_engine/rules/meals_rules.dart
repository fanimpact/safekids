import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../../models/meals_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

/// Recommandations liées aux repas, déclenchées par la question
/// "Cette activité comprend-elle un repas, un goûter ou une
/// collation ?" — même principe que la baignade, qui ne remonte que si
/// l'activité approche de l'eau.
///
/// Cette règle est aussi le seul endroit qui rapproche le profil santé
/// du moment du repas : les allergies alimentaires y sont reprises
/// automatiquement, jamais ressaisies dans le questionnaire Repas.
class MealsRules {
  const MealsRules();

  static const Map<MealPreparation, String> _preparationLabels = {
    MealPreparation.smallPieces: 'couper en petits morceaux',
    MealPreparation.minced: 'alimentation hachée',
    MealPreparation.blended: 'alimentation mixée',
    MealPreparation.thickenedDrinks: 'boissons épaissies',
  };

  static const Map<MealAssistanceLevel, String> _assistanceLabels = {
    MealAssistanceLevel.adultNearby:
        'Il mange seul, mais un adulte doit rester à côté de lui '
            'pendant le repas.',
    MealAssistanceLevel.helpWithSomeGestures:
        'Aide nécessaire sur certains gestes du repas (couper, '
            'ouvrir, porter à la bouche).',
    MealAssistanceLevel.fullyFedByAdult:
        'Doit être nourri entièrement par un adulte.',
  };

  static const Map<MealDietaryRestriction, String> _restrictionLabels = {
    MealDietaryRestriction.glutenFree: 'sans gluten',
    MealDietaryRestriction.lactoseFree: 'sans lactose',
    MealDietaryRestriction.porkFree: 'sans porc',
    MealDietaryRestriction.vegetarian: 'végétarien',
  };

  static const Map<MealRefusalStance, String> _refusalStanceLabels = {
    MealRefusalStance.insist: 'insister',
    MealRefusalStance.doNotInsist: 'ne pas insister',
  };

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final meals = child.activityProfile?.meals;

    if (childId == null || meals == null) {
      return recommendations;
    }

    if (activity.hasMeal != true) {
      return recommendations;
    }

    _addChokingRisk(recommendations, meals, childId);
    _addFoodAllergies(recommendations, child, childId);

    if (meals.hasWarningSigns == true) {
      final details = meals.warningSignsDetails?.trim();

      if (details != null && details.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'meals_warning_signs',
            category: RecommendationCategory.informationVigilance,
            childId: childId,
            text: 'Repas — signes à surveiller : $details',
          ),
        );
      }
    }

    if (meals.requiresSpecificSeating == true) {
      final details = meals.seatingDetails?.trim();

      if (details != null && details.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'meals_seating',
            category: RecommendationCategory.adaptation,
            childId: childId,
            text: 'Installation pendant le repas : $details',
          ),
        );
      }
    }

    if (meals.requiresAssistance == true) {
      final level = meals.assistanceLevel;

      if (level != null) {
        recommendations.add(
          Recommendation(
            id: 'meals_assistance',
            category: RecommendationCategory.adaptation,
            childId: childId,
            text: _assistanceLabels[level]!,
          ),
        );
      }
    }

    if (meals.requiresSpecialEquipment == true) {
      final details = meals.specialEquipmentDetails?.trim();

      if (details != null && details.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'meals_equipment',
            category: RecommendationCategory.equipment,
            childId: childId,
            text: 'Matériel pour le repas : $details',
          ),
        );
      }
    }

    if (meals.requiresIncreasedHydration == true) {
      recommendations.add(
        Recommendation(
          id: 'meals_hydration',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text:
              'Hydratation renforcée nécessaire pour raison médicale : '
              'proposer à boire régulièrement.',
        ),
      );
    }

    _addDietaryRestrictions(recommendations, meals, childId);
    _addFoodRefusals(recommendations, meals, childId);

    if (meals.hasOtherInformation == true) {
      final details = meals.otherInformationDetails?.trim();

      if (details != null && details.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'meals_other_information',
            category:
                RecommendationCategory.additionalInformation,
            childId: childId,
            text: 'Repas : $details',
          ),
        );
      }
    }

    return recommendations;
  }

  /// Le risque de fausse route et la façon de préparer les repas
  /// forment une seule recommandation, et non deux. Séparées, la
  /// préparation serait masquable alors que l'alerte ne l'est pas :
  /// l'accompagnant pourrait se retrouver avec "risque de fausse
  /// route" sans le comment-faire qui la rend actionnable.
  void _addChokingRisk(
    List<Recommendation> recommendations,
    MealsData meals,
    String childId,
  ) {
    if (meals.hasChokingRisk != true) {
      return;
    }

    final preparations = <String>[];

    for (final preparation in MealPreparation.values) {
      if (!meals.preparations.contains(preparation)) {
        continue;
      }

      if (preparation == MealPreparation.other) {
        final details = meals.otherPreparationDetails?.trim();

        if (details != null && details.isNotEmpty) {
          preparations.add(details);
        }

        continue;
      }

      preparations.add(_preparationLabels[preparation]!);
    }

    final base =
        'Risque de fausse route ou d’étouffement pendant le repas.';

    recommendations.add(
      Recommendation(
        id: 'meals_choking_risk',
        category: RecommendationCategory.informationVigilance,
        childId: childId,
        text: preparations.isEmpty
            ? base
            : '$base Préparation : ${preparations.join(', ')}.',
        isCritical: true,
      ),
    );
  }

  /// Reprises du profil santé, jamais ressaisies dans le
  /// questionnaire Repas. Une allergie sans type enregistré est
  /// incluse volontairement (voir `AllergyData.concernsMeals`) :
  /// mieux vaut la signaler à tort que la taire.
  void _addFoodAllergies(
    List<Recommendation> recommendations,
    CompleteChildProfileData child,
    String childId,
  ) {
    for (final allergy in child.essentialInformation.allergies) {
      if (!allergy.concernsMeals) {
        continue;
      }

      final label = allergy.label?.trim();

      if (label == null || label.isEmpty) {
        continue;
      }

      final reaction = allergy.observedReaction?.trim();

      final base = 'Allergie alimentaire : $label';

      recommendations.add(
        Recommendation(
          id: 'meals_food_allergy_${allergy.allergyId}',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text: reaction != null && reaction.isNotEmpty
              ? '$base — réaction : $reaction.'
              : '$base.',
          isCritical: true,
        ),
      );
    }
  }

  void _addDietaryRestrictions(
    List<Recommendation> recommendations,
    MealsData meals,
    String childId,
  ) {
    if (meals.hasDietaryRestrictions != true) {
      return;
    }

    final restrictions = <String>[];

    for (final restriction in MealDietaryRestriction.values) {
      if (!meals.dietaryRestrictions.contains(restriction)) {
        continue;
      }

      if (restriction == MealDietaryRestriction.other) {
        final details =
            meals.otherDietaryRestrictionDetails?.trim();

        if (details != null && details.isNotEmpty) {
          restrictions.add(details);
        }

        continue;
      }

      restrictions.add(_restrictionLabels[restriction]!);
    }

    if (restrictions.isEmpty) {
      return;
    }

    recommendations.add(
      Recommendation(
        id: 'meals_dietary_restrictions',
        category: RecommendationCategory.adaptation,
        childId: childId,
        text:
            'Aliments à ne pas donner : ${restrictions.join(', ')}.',
      ),
    );
  }

  void _addFoodRefusals(
    List<Recommendation> recommendations,
    MealsData meals,
    String childId,
  ) {
    if (meals.hasFoodRefusals != true) {
      return;
    }

    final details = meals.foodRefusalDetails?.trim();

    if (details == null || details.isEmpty) {
      return;
    }

    final stance = meals.refusalStance;

    final text = stance == null
        ? 'Aliments refusés ou mal tolérés : $details.'
        : 'Aliments refusés ou mal tolérés : $details — '
            '${_refusalStanceLabels[stance]!}.';

    recommendations.add(
      Recommendation(
        id: 'meals_food_refusal',
        category: RecommendationCategory.adaptation,
        childId: childId,
        text: text,
      ),
    );
  }
}
