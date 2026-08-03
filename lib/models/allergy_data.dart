enum AllergyType {
  medication,
  food,
  insect,
  other,
}

class AllergyData {
  String? allergen;
  AllergyType? type;
  String? observedReaction;
  String? prescribedMedication;
  String? prescribedDosage;

  AllergyData({
    this.allergen,
    this.type,
    this.observedReaction,
    this.prescribedMedication,
    this.prescribedDosage,
  });
}