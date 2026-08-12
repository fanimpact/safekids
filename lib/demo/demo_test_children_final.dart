import '../models/activity_profile_data.dart';
import '../models/aquatic_activity_data.dart';
import '../models/child_profile_data.dart';
import '../models/clothing_data.dart';
import '../models/communication_data.dart';
import '../models/identity_data.dart';
import '../models/other_information_data.dart';
import '../models/overnight_stay_data.dart';
import '../models/primary_care_doctor_data.dart';
import '../models/safety_data.dart';
import '../models/toilets_data.dart';
import '../models/transitions_data.dart';
import '../models/transport_data.dart';
import '../models/trigger_factor_data.dart';
import '../models/walking_effort_data.dart';
import '../repositories/child_repository.dart';

class DemoTestChildrenFinal {
  DemoTestChildrenFinal._();

  static const bool enabled = true;

  static void load() {
    if (!enabled) {
      return;
    }

    _loadMilo();
    _loadZoe();
  }

  static void _loadMilo() {
    const childId = 'test-milo';

    final existingChild =
        ChildRepository.instance.findByChildId(
      childId,
    );

    if (existingChild != null) {
      return;
    }

    final essentialInformation = ChildProfileData(
      userId: 'demo-family',
      childId: childId,
      identity: IdentityData(
        lastName: 'Test',
        firstName: 'Milo',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: true,

        flashingLights: false,
        requiresGlassesOutdoors: false,

        heat: false,

        fatigueOrLackOfSleep: true,

        noise: false,
        crowd: false,
        confinedSpaces: false,

        physicalEffort: true,

        stressOrStrongEmotions: false,

        waterContact: true,
        waterVigilance:
            WaterVigilance.other,
        otherWaterVigilance:
            'Éviter les éclaboussures au visage',

        animals: true,
        animalVigilance:
            AnimalVigilance.importantFear,
        otherAnimalVigilance: null,

        height: true,
        heightVigilance:
            HeightVigilance.vertigoOrImportantFear,
        otherHeightVigilance: null,

        other:
            'Les changements brusques de température',
      ),
      dailyTreatments: [],
      emergencyTreatments: [],
      allergies: [],
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor:
          PrimaryCareDoctorData(
        name: null,
        workplace: null,
        phoneNumber: null,
      ),
    );

    ChildRepository.instance.addChild(
      essentialInformation,
    );

    ChildRepository.instance.saveActivityProfile(
      childId: childId,
      activityProfile:
          _createEmptyActivityProfile(),
    );
  }

  static void _loadZoe() {
    const childId = 'test-zoe';

    final existingChild =
        ChildRepository.instance.findByChildId(
      childId,
    );

    if (existingChild != null) {
      return;
    }

    final essentialInformation = ChildProfileData(
      userId: 'demo-family',
      childId: childId,
      identity: IdentityData(
        lastName: 'Test',
        firstName: 'Zoé',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: true,

        flashingLights: false,
        requiresGlassesOutdoors: false,

        heat: false,
        fatigueOrLackOfSleep: false,

        noise: false,
        crowd: false,
        confinedSpaces: false,

        physicalEffort: false,

        stressOrStrongEmotions: false,

        waterContact: false,
        waterVigilance: null,
        otherWaterVigilance: null,

        animals: true,
        animalVigilance:
            AnimalVigilance.other,
        otherAnimalVigilance:
            'Ne pas approcher les chevaux',

        height: true,
        heightVigilance:
            HeightVigilance.other,
        otherHeightVigilance:
            'Besoin d’être accompagnée dans les escaliers ouverts',

        other: null,
      ),
      dailyTreatments: [],
      emergencyTreatments: [],
      allergies: [],
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor:
          PrimaryCareDoctorData(
        name: null,
        workplace: null,
        phoneNumber: null,
      ),
    );

    ChildRepository.instance.addChild(
      essentialInformation,
    );

    ChildRepository.instance.saveActivityProfile(
      childId: childId,
      activityProfile:
          _createEmptyActivityProfile(),
    );
  }

  static ActivityProfileData
      _createEmptyActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(),
      transport:
          TransportData(),
      walkingEffort:
          WalkingEffortData(),
      overnightStay:
          OvernightStayData(),
      clothing:
          ClothingData(),
      toilets:
          ToiletsData(),
      communication:
          CommunicationData(),
      transitions:
          TransitionsData(),
      safety:
          SafetyData(),
      otherInformation:
          OtherInformationData(),
    );
  }
}