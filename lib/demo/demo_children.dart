import '../models/activity_profile_data.dart';
import '../models/allergy_data.dart';
import '../models/aquatic_activity_data.dart';
import '../models/child_profile_data.dart';
import '../models/clothing_data.dart';
import '../models/communication_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/identity_data.dart';
import '../models/other_information_data.dart';
import '../models/overnight_stay_data.dart';
import '../models/pathology_data.dart';
import '../models/primary_care_doctor_data.dart';
import '../models/safety_data.dart';
import '../models/toilets_data.dart';
import '../models/transitions_data.dart';
import '../models/transport_data.dart';
import '../models/trigger_factor_data.dart';
import '../models/walking_effort_data.dart';
import '../repositories/child_repository.dart';

class DemoChildren {
  DemoChildren._();

  static const bool enabled = true;

  static void load() {
    if (!enabled) {
      return;
    }

    _loadTheo();
    _loadNoe();
  }

  static void _loadTheo() {
    const childId = 'demo-theo';

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
        lastName: 'Di Caro',
        firstName: 'Théo',
        dateOfBirth: null,
        heightCm: 148,
        weightKg: 44,
        hasDiagnosedPathologies: true,
      ),
      pathologies: [
        PathologyData(
          name: 'Épilepsie',
          approximateDiagnosisDate: null,
          hasReferringProfessional: false,
          referringProfessional: null,
        ),
      ],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: true,
        flashingLights: true,
        requiresGlassesOutdoors: true,
        heat: true,
        fatigueOrLackOfSleep: true,
        noise: false,
        crowd: false,
        confinedSpaces: false,
        physicalEffort: false,
        stressOrStrongEmotions: true,
        waterContact: true,
        waterVigilance:
            WaterVigilance.cannotSwim,
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
      emergencyTreatments: [
        EmergencyTreatmentData(
          medicationName: 'Buccolam',
          administrationCondition: null,
          dosage: null,
          administrationMethod: null,
        ),
      ],
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
          _createTheoActivityProfile(),
    );
  }

  static ActivityProfileData
      _createTheoActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(
        requiresAdaptations: true,
        mayJumpIntoWater: false,
        canSwim: true,
        requiresFlotationVestNearWater:
            false,
        requiresDedicatedAdultNearWater:
            true,
        requiresSpecialEquipment: false,
        specialEquipmentDetails: null,
        requiresAdaptedSupervision: true,
        notifyLifeguard: true,
        requiresDedicatedAdult: true,
        otherSupervisionDetails: null,
        requiresOtherAdaptation: false,
        otherAdaptationDetails: null,
      ),
      transport: TransportData(
        requiresAdaptations: true,
        motionSickness: true,
        motionSicknessTransports: {
          TransportMode.car,
        },
        takesMotionSicknessMedication: true,
        motionSicknessMedicationNames: {
          TransportMode.car:
              'Médicament test mal des transports',
        },
        requiresSpecialEquipment: false,
        specialEquipmentDetails: null,
        requiresSpecialAttention: false,
        specialAttentionDetails: null,
      ),
      walkingEffort:
          WalkingEffortData(
        prolongedWalkingRequiresVigilance:
            false,
        intensePhysicalEffortRequiresVigilance:
            true,
      ),
      overnightStay:
          OvernightStayData(
        requiresAdaptations: true,
        usesNightDevice: true,
        nightDeviceDetails:
            'Machine pour l’apnée du sommeil',
        requiresElectricity: true,
        powerFailureIsCritical: true,
        requiresNightSupervision: false,
        nightSupervisionDetails: null,
      ),
      clothing: ClothingData(
        requiresAssistance: false,
      ),
      toilets: ToiletsData(
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
      transitions: TransitionsData(
        requiresAdaptations: false,
        transitionsMayCauseStress: false,
        changesMustBeAnnounced: false,
      ),
      safety: SafetyData(
        requiresAdaptations: true,
        mayLeaveGroupSuddenly: false,
        requiresSafetyEquipment: false,
        safetyEquipmentDetails: null,
      ),
      otherInformation:
          OtherInformationData(
        hasOtherInformation: false,
        details: null,
      ),
    );
  }

  static void _loadNoe() {
    const childId = 'demo-noe';

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
        lastName: 'Di Caro',
        firstName: 'Noé',
        dateOfBirth: null,
        heightCm: null,
        weightKg: 26,
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
        waterContact: true,
        waterVigilance:
            WaterVigilance.cannotSwim,
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
      emergencyTreatments: [
        EmergencyTreatmentData(
          medicationName: 'Desloratadine',
          administrationCondition:
              'En cas de piqûre de guêpe',
          dosage: null,
          administrationMethod: null,
        ),
        EmergencyTreatmentData(
          medicationName: 'Solupred',
          administrationCondition:
              'En cas de piqûre de guêpe',
          dosage: null,
          administrationMethod: null,
        ),
      ],
      allergies: [
        AllergyData(
          allergen:
              'Piqûres de guêpe',
          observedReaction:
              'Gonflement important',
          hasDailyTreatment: false,
          dailyTreatmentName: null,
          dailyTreatmentDosage: null,
          hasEmergencyTreatment: false,
          emergencyTreatmentName: null,
          emergencyTreatmentDosage: null,
        ),
      ],
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
          _createNoeActivityProfile(),
    );
  }

  static ActivityProfileData
      _createNoeActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(
        requiresAdaptations: false,
        mayJumpIntoWater: false,
        canSwim: true,
        requiresFlotationVestNearWater:
            false,
        requiresDedicatedAdultNearWater:
            false,
        requiresSpecialEquipment: false,
        specialEquipmentDetails: null,
        requiresAdaptedSupervision: false,
        notifyLifeguard: false,
        requiresDedicatedAdult: false,
        otherSupervisionDetails: null,
        requiresOtherAdaptation: false,
        otherAdaptationDetails: null,
      ),
      transport: TransportData(
        requiresAdaptations: false,
        motionSickness: false,
        requiresSpecialEquipment: false,
        specialEquipmentDetails: null,
        requiresSpecialAttention: false,
        specialAttentionDetails: null,
      ),
      walkingEffort:
          WalkingEffortData(
        prolongedWalkingRequiresVigilance:
            false,
        intensePhysicalEffortRequiresVigilance:
            false,
      ),
      overnightStay:
          OvernightStayData(
        requiresAdaptations: true,
        usesNightDevice: true,
        nightDeviceDetails:
            'Machine pour l’apnée du sommeil',
        requiresElectricity: true,
        powerFailureIsCritical: false,
        requiresNightSupervision: false,
        nightSupervisionDetails: null,
      ),
      clothing: ClothingData(
        requiresAssistance: false,
      ),
      toilets: ToiletsData(
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
      transitions: TransitionsData(
        requiresAdaptations: false,
        transitionsMayCauseStress: false,
        changesMustBeAnnounced: false,
      ),
      safety: SafetyData(
        requiresAdaptations: true,
        mayLeaveGroupSuddenly: false,
        requiresSafetyEquipment: false,
        safetyEquipmentDetails: null,
      ),
      otherInformation:
          OtherInformationData(
        hasOtherInformation: false,
        details: null,
      ),
    );
  }
}