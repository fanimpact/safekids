import '../models/activity_profile_data.dart';
import '../models/allergy_data.dart';
import '../models/aquatic_activity_data.dart';
import '../models/child_profile_data.dart';
import '../models/clothing_data.dart';
import '../models/communication_data.dart';
import '../models/contact_data.dart';
import '../models/daily_treatment_data.dart';
import '../models/discontinued_treatment_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/identity_data.dart';
import '../models/medical_device_data.dart';
import '../models/medical_event_data.dart';
import '../models/medical_observation_data.dart';
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
    const epilepsyId = 'demo-theo-epilepsy';

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
        dateOfBirth: DateTime(2016, 10, 20),
        heightCm: 148,
        weightKg: 44,
        hasDiagnosedPathologies: true,
      ),
      pathologies: [
        PathologyData(
          pathologyId: epilepsyId,
          name: 'Épilepsie',
          approximateDiagnosisDate: null,
          hasReferringProfessional: false,
          referringProfessional: null,
          emergencyInstructionSteps: [
            'Mettre en position latérale de sécurité',
            'Déclencher un chronomètre',
            'Si la crise dure plus de 5 minutes, donner le Buccolam',
          ],
        ),
      ],
      medicalEvents: [
        MedicalEventData(
          description:
              'Trois crises sur trois jours consécutifs : les deux premières généralisées, la troisième focale avec paralysie de Todd',
          approximateDate: '24-26 décembre',
          emergencyServicesCalled: true,
          hospitalized: true,
          hospitalizationDuration: 'Une nuit',
          importantExaminationsPerformed: true,
          importantExaminations: 'EEG et IRM',
          hasOngoingConsequences: false,
          ongoingConsequences: null,
        ),
        MedicalEventData(
          description: 'Une crise généralisée',
          approximateDate: '7 juillet 2026',
          emergencyServicesCalled: true,
          hospitalized: true,
          hospitalizationDuration: 'Trois jours',
          importantExaminationsPerformed: true,
          importantExaminations: 'EEG et IRM',
          hasOngoingConsequences: false,
          ongoingConsequences: null,
        ),
      ],
      medicalObservations: [
        MedicalObservationData(
          description: 'Souffle au cœur détecté',
          approximateDate: 'Petite enfance',
          conclusion:
              'Bilan cardiologique réalisé, sans conséquence identifiée',
        ),
      ],
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
      dailyTreatments: [
        DailyTreatmentData(
          medicationName: 'Dépakine',
          dosage: '500 mg',
          administrationTimes: '8h30',
        ),
        DailyTreatmentData(
          medicationName: 'Dépakine',
          dosage: '750 mg',
          administrationTimes: '20h30',
        ),
      ],
      discontinuedTreatments: [],
      emergencyTreatments: [
        EmergencyTreatmentData(
          medicationName: 'Buccolam',
          administrationCondition: null,
          dosage: null,
          administrationMethod: null,
          relatedPathologyIds: const [
            epilepsyId,
          ],
        ),
      ],
      allergies: [],
      medicalDevices: [
        MedicalDeviceData(
          deviceName: 'Diabolos',
          mainUse: null,
        ),
        MedicalDeviceData(
          deviceName:
              'Machine pour l’apnée du sommeil',
          mainUse: null,
        ),
      ],
      contacts: [
        ContactData(
          fullName: 'Fanny',
          relationship: 'Parent',
          phoneNumber: null,
          isPrimaryContact: true,
        ),
      ],
      primaryCareDoctor:
          PrimaryCareDoctorData(
        name: 'Julien',
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

        requiresSpecialEquipment: true,
        specialEquipmentDetails:
            'Bouchons d’oreilles et bonnet de bain',

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
        takesMotionSicknessMedication: false,
        motionSicknessMedicationNames: {},
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
    const waspAllergyId =
        'demo-noe-wasp-allergy';
    const sleepEpilepsyId =
        'demo-noe-sleep-epilepsy';

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
        dateOfBirth: DateTime(2018, 11, 16),
        heightCm: 130,
        weightKg: 26,
        hasDiagnosedPathologies: true,
      ),
      pathologies: [
        PathologyData(
          pathologyId: sleepEpilepsyId,
          name: 'Épilepsie du sommeil',
          approximateDiagnosisDate: '2022',
          hasReferringProfessional: false,
          referringProfessional: null,
        ),
      ],
      medicalEvents: [
        MedicalEventData(
          description:
              'Deux crises pendant l’année 2022',
          approximateDate: '2022',
          emergencyServicesCalled: true,
          hospitalized: true,
          hospitalizationDuration: 'Une nuit',
        ),
      ],
      medicalObservations: [],
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
      discontinuedTreatments: [
        DiscontinuedTreatmentData(
          medicationName: 'Urbanyl',
          approximateStopDate: 'Février 2026',
        ),
      ],
      emergencyTreatments: [
        EmergencyTreatmentData(
          medicationName: 'Desloratadine',
          administrationCondition:
              'En cas de piqûre de guêpe',
          dosage: null,
          administrationMethod: null,
          relatedAllergyIds: const [
            waspAllergyId,
          ],
        ),
        EmergencyTreatmentData(
          medicationName: 'Solupred',
          administrationCondition:
              'En cas de piqûre de guêpe',
          dosage: null,
          administrationMethod: null,
          relatedAllergyIds: const [
            waspAllergyId,
          ],
        ),
      ],
      allergies: [
        AllergyData(
          allergyId: waspAllergyId,
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
      medicalDevices: [
        MedicalDeviceData(
          deviceName:
              'Machine pour l’apnée du sommeil',
          mainUse: null,
        ),
      ],
      contacts: [
        ContactData(
          fullName: 'Fanny',
          relationship: 'Parent',
          phoneNumber: null,
          isPrimaryContact: true,
        ),
      ],
      primaryCareDoctor:
          PrimaryCareDoctorData(
        name: 'Julien',
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