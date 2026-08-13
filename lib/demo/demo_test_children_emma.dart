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

class DemoTestChildrenEmma {
  DemoTestChildrenEmma._();

  static const bool enabled = true;

  static void load() {
    if (!enabled) {
      return;
    }

    _loadEmma();
  }

  static void _loadEmma() {
    const childId = 'test-emma';

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
        firstName: 'Emma',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      medicalObservations: [],
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
      discontinuedTreatments: [],
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
          _createEmmaActivityProfile(),
    );
  }

  static ActivityProfileData
      _createEmmaActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(
        requiresAdaptations: true,

        // Proximité d'un point d'eau.
        mayJumpIntoWater: true,
        canSwim: false,
        requiresFlotationVestNearWater:
            true,
        requiresDedicatedAdultNearWater:
            true,

        // Baignade.
        requiresSpecialEquipment: true,
        specialEquipmentDetails:
            'Chaussures aquatiques adaptées',

        requiresAdaptedSupervision: true,
        notifyLifeguard: true,
        requiresDedicatedAdult: true,
        otherSupervisionDetails:
            'Rester à portée de bras pendant la baignade',

        requiresOtherAdaptation: true,
        otherAdaptationDetails:
            'Entrer progressivement dans l’eau',
      ),

      transport:
          TransportData(
        requiresAdaptations: true,

        // Emma est malade en bus ET en bateau,
        // mais pas en voiture.
        motionSickness: true,
        motionSicknessTransports: {
          TransportMode.bus,
          TransportMode.boatOrFerry,
        },

        // Elle prend un médicament uniquement
        // pour le bateau / ferry.
        takesMotionSicknessMedication: true,
        motionSicknessMedicationNames: {
          TransportMode.boatOrFerry:
              'Nautamine',
        },

        requiresSpecialEquipment: true,
        specialEquipmentDetails:
            'Coussin de positionnement',

        requiresSpecialAttention: true,
        specialAttentionDetails:
            'Installer Emma près d’une fenêtre si possible',
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
            'Appareil respiratoire de nuit',

        requiresElectricity: true,

        // Piège volontaire :
        // l'appareil nécessite l'électricité,
        // mais une coupure n'est PAS critique.
        powerFailureIsCritical: false,

        requiresNightSupervision: true,
        nightSupervisionDetails:
            'Vérifier une fois dans la nuit que l’appareil est correctement positionné',
      ),

      clothing:
          ClothingData(
        requiresAssistance: false,
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
        requiresAdaptations: false,
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