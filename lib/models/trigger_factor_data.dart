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

  bool? flashingLights;
  bool requiresGlassesOutdoors;

  bool? heat;
  bool? fatigueOrLackOfSleep;
  bool? noise;
  bool? crowd;
  bool? confinedSpaces;
  bool? physicalEffort;
  bool? stressOrStrongEmotions;

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
    this.flashingLights,
    this.requiresGlassesOutdoors = false,
    this.heat,
    this.fatigueOrLackOfSleep,
    this.noise,
    this.crowd,
    this.confinedSpaces,
    this.physicalEffort,
    this.stressOrStrongEmotions,
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