/// Comment préparer repas et boissons quand l'enfant risque la fausse
/// route. Choix multiples : une même préparation combine souvent
/// plusieurs consignes (couper petit ET épaissir les boissons).
enum MealPreparation {
  smallPieces,
  minced,
  blended,
  thickenedDrinks,
  other,
}

/// Degré d'aide nécessaire pendant la prise du repas. Choix unique :
/// les trois niveaux sont exclusifs, du plus autonome au moins
/// autonome.
enum MealAssistanceLevel {
  adultNearby,
  helpWithSomeGestures,
  fullyFedByAdult,
}

/// Aliments que l'enfant ne doit pas manger. Ce sont des régimes, pas
/// des allergies : les allergies alimentaires viennent du profil santé
/// et ne sont jamais ressaisies ici (voir `AllergyData.concernsMeals`).
enum MealDietaryRestriction {
  glutenFree,
  lactoseFree,
  porkFree,
  vegetarian,
  other,
}

/// Conduite à tenir face à un aliment refusé.
enum MealRefusalStance {
  insist,
  doNotInsist,
  offerWithoutInsisting,
}

/// Section "Repas" du profil Activités. Aucune question filtre : les
/// neuf questions sont posées à tous les parents, comme les sections
/// eau/transport/nuitée/sécurité depuis la correction du 19/08/2026.
///
/// Rien ici ne double le profil santé : ni allergie alimentaire, ni
/// traitement. Ces informations sont récupérées par le moteur
/// (`MealsRules`) au moment où l'activité comprend un repas.
class MealsData {
  // Sous-partie 1 : sécurité pendant le repas.

  bool? hasChokingRisk;
  final Set<MealPreparation> preparations;
  String? otherPreparationDetails;

  bool? requiresSpecificSeating;
  String? seatingDetails;

  bool? hasWarningSigns;
  String? warningSignsDetails;

  // Sous-partie 2 : autonomie au repas.

  bool? requiresAssistance;
  MealAssistanceLevel? assistanceLevel;

  bool? requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool? requiresIncreasedHydration;

  // Sous-partie 3 : alimentation.

  bool? hasDietaryRestrictions;
  final Set<MealDietaryRestriction> dietaryRestrictions;
  String? otherDietaryRestrictionDetails;

  bool? hasFoodRefusals;
  String? foodRefusalDetails;
  MealRefusalStance? refusalStance;

  // Fin de section.

  bool? hasOtherInformation;
  String? otherInformationDetails;

  MealsData({
    this.hasChokingRisk,
    Set<MealPreparation>? preparations,
    this.otherPreparationDetails,
    this.requiresSpecificSeating,
    this.seatingDetails,
    this.hasWarningSigns,
    this.warningSignsDetails,
    this.requiresAssistance,
    this.assistanceLevel,
    this.requiresSpecialEquipment,
    this.specialEquipmentDetails,
    this.requiresIncreasedHydration,
    this.hasDietaryRestrictions,
    Set<MealDietaryRestriction>? dietaryRestrictions,
    this.otherDietaryRestrictionDetails,
    this.hasFoodRefusals,
    this.foodRefusalDetails,
    this.refusalStance,
    this.hasOtherInformation,
    this.otherInformationDetails,
  })  : preparations = preparations ?? <MealPreparation>{},
        dietaryRestrictions =
            dietaryRestrictions ?? <MealDietaryRestriction>{};

  Map<String, dynamic> toJson() => {
        'hasChokingRisk': hasChokingRisk,
        'preparations':
            preparations.map((value) => value.name).toList(),
        'otherPreparationDetails': otherPreparationDetails,
        'requiresSpecificSeating': requiresSpecificSeating,
        'seatingDetails': seatingDetails,
        'hasWarningSigns': hasWarningSigns,
        'warningSignsDetails': warningSignsDetails,
        'requiresAssistance': requiresAssistance,
        'assistanceLevel': assistanceLevel?.name,
        'requiresSpecialEquipment': requiresSpecialEquipment,
        'specialEquipmentDetails': specialEquipmentDetails,
        'requiresIncreasedHydration': requiresIncreasedHydration,
        'hasDietaryRestrictions': hasDietaryRestrictions,
        'dietaryRestrictions':
            dietaryRestrictions.map((value) => value.name).toList(),
        'otherDietaryRestrictionDetails':
            otherDietaryRestrictionDetails,
        'hasFoodRefusals': hasFoodRefusals,
        'foodRefusalDetails': foodRefusalDetails,
        'refusalStance': refusalStance?.name,
        'hasOtherInformation': hasOtherInformation,
        'otherInformationDetails': otherInformationDetails,
      };

  factory MealsData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MealsData(
      hasChokingRisk: json['hasChokingRisk'] as bool?,
      preparations: _enumSetFromJson(
        json['preparations'],
        MealPreparation.values,
      ),
      otherPreparationDetails:
          json['otherPreparationDetails'] as String?,
      requiresSpecificSeating:
          json['requiresSpecificSeating'] as bool?,
      seatingDetails: json['seatingDetails'] as String?,
      hasWarningSigns: json['hasWarningSigns'] as bool?,
      warningSignsDetails: json['warningSignsDetails'] as String?,
      requiresAssistance: json['requiresAssistance'] as bool?,
      assistanceLevel: _enumFromName(
        MealAssistanceLevel.values,
        json['assistanceLevel'] as String?,
      ),
      requiresSpecialEquipment:
          json['requiresSpecialEquipment'] as bool?,
      specialEquipmentDetails:
          json['specialEquipmentDetails'] as String?,
      requiresIncreasedHydration:
          json['requiresIncreasedHydration'] as bool?,
      hasDietaryRestrictions:
          json['hasDietaryRestrictions'] as bool?,
      dietaryRestrictions: _enumSetFromJson(
        json['dietaryRestrictions'],
        MealDietaryRestriction.values,
      ),
      otherDietaryRestrictionDetails:
          json['otherDietaryRestrictionDetails'] as String?,
      hasFoodRefusals: json['hasFoodRefusals'] as bool?,
      foodRefusalDetails: json['foodRefusalDetails'] as String?,
      refusalStance: _enumFromName(
        MealRefusalStance.values,
        json['refusalStance'] as String?,
      ),
      hasOtherInformation: json['hasOtherInformation'] as bool?,
      otherInformationDetails:
          json['otherInformationDetails'] as String?,
    );
  }
}

Set<T> _enumSetFromJson<T extends Enum>(
  dynamic raw,
  List<T> values,
) {
  final result = <T>{};

  if (raw is! List) {
    return result;
  }

  for (final name in raw) {
    final value = _enumFromName(values, name as String?);

    if (value != null) {
      result.add(value);
    }
  }

  return result;
}

T? _enumFromName<T extends Enum>(
  List<T> values,
  String? name,
) {
  if (name == null) {
    return null;
  }

  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }

  return null;
}
