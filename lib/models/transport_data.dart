enum TransportMode {
  car,
  bus,
  train,
  tram,
  metro,
  plane,
  boatOrFerry,
  other,
}

class TransportData {
  bool requiresAdaptations;

  bool? motionSickness;

  Set<TransportMode> motionSicknessTransports;

  bool? takesMotionSicknessMedication;

  Map<TransportMode, String> motionSicknessMedicationNames;

  bool? requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool? requiresSpecialAttention;
  String? specialAttentionDetails;

  TransportData({
    this.requiresAdaptations = false,
    this.motionSickness,
    Set<TransportMode>? motionSicknessTransports,
    this.takesMotionSicknessMedication,
    Map<TransportMode, String>? motionSicknessMedicationNames,
    this.requiresSpecialEquipment,
    this.specialEquipmentDetails,
    this.requiresSpecialAttention,
    this.specialAttentionDetails,
  })  : motionSicknessTransports =
            motionSicknessTransports ?? <TransportMode>{},
        motionSicknessMedicationNames =
            motionSicknessMedicationNames ?? <TransportMode, String>{};

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'motionSickness': motionSickness,
        'motionSicknessTransports': motionSicknessTransports
            .map((mode) => mode.name)
            .toList(),
        'takesMotionSicknessMedication':
            takesMotionSicknessMedication,
        'motionSicknessMedicationNames':
            motionSicknessMedicationNames.map(
          (mode, name) => MapEntry(mode.name, name),
        ),
        'requiresSpecialEquipment':
            requiresSpecialEquipment,
        'specialEquipmentDetails':
            specialEquipmentDetails,
        'requiresSpecialAttention':
            requiresSpecialAttention,
        'specialAttentionDetails':
            specialAttentionDetails,
      };

  factory TransportData.fromJson(
    Map<String, dynamic> json,
  ) {
    final medicationNames =
        json['motionSicknessMedicationNames']
            as Map<String, dynamic>?;

    return TransportData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool? ??
              false,
      motionSickness:
          json['motionSickness'] as bool?,
      motionSicknessTransports:
          (json['motionSicknessTransports']
                      as List<dynamic>?)
                  ?.map(
                    (name) => _enumFromName(
                      TransportMode.values,
                      name as String,
                    ),
                  )
                  .whereType<TransportMode>()
                  .toSet() ??
              {},
      takesMotionSicknessMedication:
          json['takesMotionSicknessMedication']
              as bool?,
      motionSicknessMedicationNames:
          medicationNames == null
              ? null
              : _parseMotionSicknessMedicationNames(
                  medicationNames,
                ),
      requiresSpecialEquipment:
          json['requiresSpecialEquipment'] as bool?,
      specialEquipmentDetails:
          json['specialEquipmentDetails'] as String?,
      requiresSpecialAttention:
          json['requiresSpecialAttention'] as bool?,
      specialAttentionDetails:
          json['specialAttentionDetails'] as String?,
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

Map<TransportMode, String>
    _parseMotionSicknessMedicationNames(
  Map<String, dynamic> json,
) {
  final result = <TransportMode, String>{};

  for (final entry in json.entries) {
    final mode = _enumFromName(
      TransportMode.values,
      entry.key,
    );

    if (mode != null) {
      result[mode] = entry.value as String;
    }
  }

  return result;
}