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

class DemoTestChildrenLucas {
  DemoTestChildrenLucas._();

  static const bool enabled = true;

  static void load() {
    if (!enabled) {
      return;
    }

    _loadLucas();
  }

  static void _loadLucas() {
    const childId = 'test-lucas';

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
        firstName: 'Lucas',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: false,
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
        animals: false,
        animalVigilance: null,
        otherAnimalVigilance: null,
        height: false,
        heightVigilance: null,
        otherHeightVigilance: null,
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
          _createLucasActivityProfile(),
    );
  }

  static ActivityProfileData
      _createLucasActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(),

      transport:
          TransportData(),

      walkingEffort:
          WalkingEffortData(
        prolongedWalkingRequiresVigilance:
            true,
        intensePhysicalEffortRequiresVigilance:
            true,
      ),

      overnightStay:
          OvernightStayData(),

      clothing:
          ClothingData(
        requiresAssistance: true,
      ),

      toilets:
          ToiletsData(
        requiresAssistance: false,
      ),

      communication:
          CommunicationData(
        requiresAdaptations: false,
        useSimpleInstructions: false,
        mayAppearToUnderstand: false,
        verifyUnderstandingIndividually:
            false,
        usesCommunicationSupport: false,
        communicationSupportDetails: null,
      ),

      transitions:
          TransitionsData(
        requiresAdaptations: false,
        transitionsMayCauseStress: false,
        changesMustBeAnnounced: false,
      ),

      safety:
          SafetyData(
        requiresAdaptations: true,
        mayLeaveGroupSuddenly: true,
        requiresSafetyEquipment: true,
        safetyEquipmentDetails:
            'Casque de protection',
      ),

      otherInformation:
          OtherInformationData(
        hasOtherInformation: false,
        details: null,
      ),
    );
  }
}