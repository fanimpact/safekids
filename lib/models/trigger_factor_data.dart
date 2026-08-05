enum WaterVigilance {
  mayJumpIntoWater,
  cannotSwim,
  other,
}

enum AnimalVigilance {
  importantFear,
  approachesWithoutPerceivingDanger,
  other,
}

enum HeightVigilance {
  doesNotPerceiveDanger,
  vertigoOrImportantFear,
  other,
}

class TriggerFactorData {
  bool hasTriggerFactors;

  bool flashingLights;
  bool heat;
  bool fatigueOrLackOfSleep;
  bool noise;
  bool crowd;
  bool confinedSpaces;
  bool physicalEffort;
  bool stressOrStrongEmotions;

  bool waterContact;
  WaterVigilance? waterVigilance;
  String? otherWaterVigilance;

  bool animals;
  AnimalVigilance? animalVigilance;
  String? otherAnimalVigilance;

  bool height;
  HeightVigilance? heightVigilance;
  String? otherHeightVigilance;

  String? other;

  TriggerFactorData({
    this.hasTriggerFactors = false,
    this.flashingLights = false,
    this.heat = false,
    this.fatigueOrLackOfSleep = false,
    this.noise = false,
    this.crowd = false,
    this.confinedSpaces = false,
    this.physicalEffort = false,
    this.stressOrStrongEmotions = false,
    this.waterContact = false,
    this.waterVigilance,
    this.otherWaterVigilance,
    this.animals = false,
    this.animalVigilance,
    this.otherAnimalVigilance,
    this.height = false,
    this.heightVigilance,
    this.otherHeightVigilance,
    this.other,
  });
}