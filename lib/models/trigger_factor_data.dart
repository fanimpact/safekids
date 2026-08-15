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

  bool? waterContact;
  WaterVigilance? waterVigilance;
  String? otherWaterVigilance;

  bool? animals;
  AnimalVigilance? animalVigilance;
  String? otherAnimalVigilance;

  bool? height;
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
    this.waterContact,
    this.waterVigilance,
    this.otherWaterVigilance,
    this.animals,
    this.animalVigilance,
    this.otherAnimalVigilance,
    this.height,
    this.heightVigilance,
    this.otherHeightVigilance,
    this.other,
  });

  Map<String, dynamic> toJson() => {
        'hasTriggerFactors': hasTriggerFactors,
        'flashingLights': flashingLights,
        'requiresGlassesOutdoors':
            requiresGlassesOutdoors,
        'heat': heat,
        'fatigueOrLackOfSleep': fatigueOrLackOfSleep,
        'noise': noise,
        'crowd': crowd,
        'confinedSpaces': confinedSpaces,
        'physicalEffort': physicalEffort,
        'stressOrStrongEmotions':
            stressOrStrongEmotions,
        'waterContact': waterContact,
        'waterVigilance': waterVigilance?.name,
        'otherWaterVigilance': otherWaterVigilance,
        'animals': animals,
        'animalVigilance': animalVigilance?.name,
        'otherAnimalVigilance': otherAnimalVigilance,
        'height': height,
        'heightVigilance': heightVigilance?.name,
        'otherHeightVigilance': otherHeightVigilance,
        'other': other,
      };

  factory TriggerFactorData.fromJson(
    Map<String, dynamic> json,
  ) {
    return TriggerFactorData(
      hasTriggerFactors:
          json['hasTriggerFactors'] as bool? ?? false,
      flashingLights: json['flashingLights'] as bool?,
      requiresGlassesOutdoors:
          json['requiresGlassesOutdoors'] as bool? ??
              false,
      heat: json['heat'] as bool?,
      fatigueOrLackOfSleep:
          json['fatigueOrLackOfSleep'] as bool?,
      noise: json['noise'] as bool?,
      crowd: json['crowd'] as bool?,
      confinedSpaces: json['confinedSpaces'] as bool?,
      physicalEffort: json['physicalEffort'] as bool?,
      stressOrStrongEmotions:
          json['stressOrStrongEmotions'] as bool?,
      waterContact: json['waterContact'] as bool?,
      waterVigilance: _enumFromName(
        WaterVigilance.values,
        json['waterVigilance'] as String?,
      ),
      otherWaterVigilance:
          json['otherWaterVigilance'] as String?,
      animals: json['animals'] as bool?,
      animalVigilance: _enumFromName(
        AnimalVigilance.values,
        json['animalVigilance'] as String?,
      ),
      otherAnimalVigilance:
          json['otherAnimalVigilance'] as String?,
      height: json['height'] as bool?,
      heightVigilance: _enumFromName(
        HeightVigilance.values,
        json['heightVigilance'] as String?,
      ),
      otherHeightVigilance:
          json['otherHeightVigilance'] as String?,
      other: json['other'] as String?,
    );
  }
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