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

class DemoTestChildren {
  DemoTestChildren._();

  static const bool enabled = true;

  static void load() {
    if (!enabled) {
      return;
    }

    _loadLina();
  }

  static void _loadLina() {
    const childId = 'test-lina';

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
        firstName: 'Lina',
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

        noise: true,
        crowd: true,
        confinedSpaces: true,

        physicalEffort: false,
        stressOrStrongEmotions: false,

        waterContact: false,
        waterVigilance: null,
        otherWaterVigilance: null,

        animals: true,
        animalVigilance:
            AnimalVigilance
                .approachesWithoutPerceivingDanger,
        otherAnimalVigilance: null,

        height: true,
        heightVigilance:
            HeightVigilance
                .doesNotPerceiveDanger,
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
          _createLinaActivityProfile(),
    );
  }

  static ActivityProfileData
      _createLinaActivityProfile() {
    return ActivityProfileData(
      aquaticActivity:
          AquaticActivityData(),

      transport:
          TransportData(),

      walkingEffort:
          WalkingEffortData(
        prolongedWalkingRequiresVigilance:
            false,
        intensePhysicalEffortRequiresVigilance:
            false,
      ),

      overnightStay:
          OvernightStayData(),

      clothing:
          ClothingData(
        requiresAssistance: false,
      ),

      toilets:
          ToiletsData(
        requiresAssistance: true,
      ),

      communication:
          CommunicationData(
        requiresAdaptations: true,
        useSimpleInstructions: true,

        // Les deux sont volontairement vrais :
        // le moteur doit quand même générer
        // "Vérifier sa compréhension"
        // une seule fois.
        mayAppearToUnderstand: true,
        verifyUnderstandingIndividually:
            true,

        usesCommunicationSupport: true,
        communicationSupportDetails:
            'Tablette avec pictogrammes',
      ),

      transitions:
          TransitionsData(
        requiresAdaptations: true,
        transitionsMayCauseStress: true,
        changesMustBeAnnounced: true,
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
        hasOtherInformation: true,
        details:
            'Peut avoir besoin d’un temps calme pour se recentrer.',
      ),
    );
  }
}