import 'package:uuid/uuid.dart';

import 'allergy_data.dart';
import 'child_profile_data.dart';
import 'contact_data.dart';
import 'daily_treatment_data.dart';
import 'discontinued_treatment_data.dart';
import 'emergency_treatment_data.dart';
import 'identity_data.dart';
import 'medical_device_data.dart';
import 'medical_event_data.dart';
import 'medical_observation_data.dart';
import 'medical_professional_data.dart';
import 'pathology_data.dart';
import 'primary_care_doctor_data.dart';
import 'trigger_factor_data.dart';

class ChildProfileDraft {
  String? userId;

  /// Renseignee par l'ecran de consentement, avant le questionnaire.
  /// Voir `ChildProfileData.consentementSanteLe`.
  DateTime? consentementSanteLe;

  /// Voir `ChildProfileData.accesSecoursAutorise`.
  bool accesSecoursAutorise;
  String childId;

  final IdentityData identity;

  /// Réponse explicite à "Votre enfant présente-t-il une ou plusieurs
  /// pathologies diagnostiquées par un professionnel de santé ?" /
  /// "...une ou plusieurs allergies... ?" — stockée séparément de la
  /// liste (plutôt que déduite de `pathologies.isNotEmpty`), pour que
  /// "Non" reste affiché en revenant modifier le profil, exactement
  /// comme "Oui" (une liste vide ne permet pas de distinguer "Non" de
  /// "jamais répondu").
  bool? hasPathologies;
  bool? hasAllergies;
  bool? hasDailyTreatments;
  bool? hasDiscontinuedTreatments;
  bool? hasEmergencyTreatments;
  bool? hasMedicalDevices;

  final List<PathologyData> pathologies;
  final List<MedicalEventData> medicalEvents;
  final List<MedicalObservationData> medicalObservations;

  final TriggerFactorData triggerFactors;

  final List<DailyTreatmentData> dailyTreatments;
  final List<DiscontinuedTreatmentData>
      discontinuedTreatments;
  final List<EmergencyTreatmentData> emergencyTreatments;

  final List<AllergyData> allergies;
  final List<MedicalDeviceData> medicalDevices;
  final List<ContactData> contacts;

  final PrimaryCareDoctorData primaryCareDoctor;

  ChildProfileDraft({
    this.userId,
    this.consentementSanteLe,
    this.accesSecoursAutorise = false,
    String? childId,
    IdentityData? identity,
    this.hasPathologies,
    this.hasAllergies,
    this.hasDailyTreatments,
    this.hasDiscontinuedTreatments,
    this.hasEmergencyTreatments,
    this.hasMedicalDevices,
    List<PathologyData>? pathologies,
    List<MedicalEventData>? medicalEvents,
    List<MedicalObservationData>? medicalObservations,
    TriggerFactorData? triggerFactors,
    List<DailyTreatmentData>? dailyTreatments,
    List<DiscontinuedTreatmentData>?
        discontinuedTreatments,
    List<EmergencyTreatmentData>? emergencyTreatments,
    List<AllergyData>? allergies,
    List<MedicalDeviceData>? medicalDevices,
    List<ContactData>? contacts,
    PrimaryCareDoctorData? primaryCareDoctor,
  })  : childId = childId ?? _createChildId(),
        identity = identity ?? IdentityData(),
        pathologies = pathologies ?? [],
        medicalEvents = medicalEvents ?? [],
        medicalObservations =
            medicalObservations ?? [],
        triggerFactors =
            triggerFactors ?? TriggerFactorData(),
        dailyTreatments = dailyTreatments ?? [],
        discontinuedTreatments =
            discontinuedTreatments ?? [],
        emergencyTreatments =
            emergencyTreatments ?? [],
        allergies = allergies ?? [],
        medicalDevices = medicalDevices ?? [],
        contacts = contacts ?? [],
        primaryCareDoctor =
            primaryCareDoctor ??
                PrimaryCareDoctorData();

  static String _createChildId() {
    return const Uuid().v4();
  }

  factory ChildProfileDraft.fromChildProfileData(
    ChildProfileData data,
  ) {
    return ChildProfileDraft(
      userId: data.userId,
      childId: data.childId,
      consentementSanteLe: data.consentementSanteLe,
      accesSecoursAutorise: data.accesSecoursAutorise,
      hasPathologies: data.hasPathologies,
      hasAllergies: data.hasAllergies,
      hasDailyTreatments: data.hasDailyTreatments,
      hasDiscontinuedTreatments:
          data.hasDiscontinuedTreatments,
      hasEmergencyTreatments: data.hasEmergencyTreatments,
      hasMedicalDevices: data.hasMedicalDevices,

      identity: IdentityData(
        lastName: data.identity.lastName,
        firstName: data.identity.firstName,
        dateOfBirth: data.identity.dateOfBirth,
        heightCm: data.identity.heightCm,
        weightKg: data.identity.weightKg,
        measurementsUpdatedAt:
            data.identity.measurementsUpdatedAt,
        hasDiagnosedPathologies:
            data.identity.hasDiagnosedPathologies,
      ),

      pathologies: data.pathologies.map(
        (pathology) {
          final professional =
              pathology.referringProfessional;

          return PathologyData(
            pathologyId: pathology.pathologyId,
            name: pathology.name,
            approximateDiagnosisDate:
                pathology.approximateDiagnosisDate,
            hasReferringProfessional:
                pathology.hasReferringProfessional,
            referringProfessional:
                professional == null
                    ? null
                    : MedicalProfessionalData(
                        name: professional.name,
                        specialty:
                            professional.specialty,
                        workplace:
                            professional.workplace,
                        phoneNumber:
                            professional.phoneNumber,
                      ),
            emergencyInstructionSteps:
                List<String>.from(
              pathology.emergencyInstructionSteps,
            ),
          );
        },
      ).toList(),

      medicalEvents: data.medicalEvents.map(
        (event) {
          return MedicalEventData(
            description: event.description,
            approximateDate: event.approximateDate,
            emergencyServicesCalled:
                event.emergencyServicesCalled,
            emergencyTreatmentGiven:
                event.emergencyTreatmentGiven,
            hospitalized: event.hospitalized,
            hospitalName: event.hospitalName,
            hospitalizationDuration:
                event.hospitalizationDuration,
            importantExaminationsPerformed:
                event.importantExaminationsPerformed,
            importantExaminations:
                event.importantExaminations,
          );
        },
      ).toList(),

      medicalObservations:
          data.medicalObservations.map(
        (observation) {
          return MedicalObservationData(
            description: observation.description,
            approximateDate:
                observation.approximateDate,
            conclusion: observation.conclusion,
          );
        },
      ).toList(),

      triggerFactors: TriggerFactorData(
        hasTriggerFactors:
            data.triggerFactors.hasTriggerFactors,
        flashingLights:
            data.triggerFactors.flashingLights,
        requiresGlassesOutdoors: data
            .triggerFactors
            .requiresGlassesOutdoors,
        heat: data.triggerFactors.heat,
        fatigueOrLackOfSleep: data
            .triggerFactors
            .fatigueOrLackOfSleep,
        noise: data.triggerFactors.noise,
        crowd: data.triggerFactors.crowd,
        confinedSpaces:
            data.triggerFactors.confinedSpaces,
        physicalEffort:
            data.triggerFactors.physicalEffort,
        stressOrStrongEmotions: data
            .triggerFactors
            .stressOrStrongEmotions,
        waterContact:
            data.triggerFactors.waterContact,
        waterVigilance:
            data.triggerFactors.waterVigilance,
        otherWaterVigilance: data
            .triggerFactors
            .otherWaterVigilance,
        animals: data.triggerFactors.animals,
        animalVigilance:
            data.triggerFactors.animalVigilance,
        otherAnimalVigilance: data
            .triggerFactors
            .otherAnimalVigilance,
        height: data.triggerFactors.height,
        heightVigilance:
            data.triggerFactors.heightVigilance,
        otherHeightVigilance: data
            .triggerFactors
            .otherHeightVigilance,
        other: data.triggerFactors.other,
      ),

      dailyTreatments: data.dailyTreatments.map(
        (treatment) {
          return DailyTreatmentData(
            medicationName:
                treatment.medicationName,
            dosage: treatment.dosage,
            administrationTimes:
                treatment.administrationTimes,
            relatedPathologyIds:
                List<String>.from(
              treatment.relatedPathologyIds,
            ),
            relatedAllergyIds:
                List<String>.from(
              treatment.relatedAllergyIds,
            ),
          );
        },
      ).toList(),

      discontinuedTreatments:
          data.discontinuedTreatments.map(
        (treatment) {
          return DiscontinuedTreatmentData(
            medicationName:
                treatment.medicationName,
            approximateStopDate:
                treatment.approximateStopDate,
          );
        },
      ).toList(),

      emergencyTreatments:
          data.emergencyTreatments.map(
        (treatment) {
          return EmergencyTreatmentData(
            medicationName:
                treatment.medicationName,
            administrationCondition:
                treatment.administrationCondition,
            dosage: treatment.dosage,
            administrationMethod:
                treatment.administrationMethod,
            relatedPathologyIds:
                List<String>.from(
              treatment.relatedPathologyIds,
            ),
            relatedAllergyIds:
                List<String>.from(
              treatment.relatedAllergyIds,
            ),
            administrationStepByPathologyId:
                Map<String, int>.from(
              treatment.administrationStepByPathologyId,
            ),
            administrationStepByAllergyId:
                Map<String, int>.from(
              treatment.administrationStepByAllergyId,
            ),
          );
        },
      ).toList(),

      allergies: data.allergies.map(
        (allergy) {
          return AllergyData(
            allergyId: allergy.allergyId,
            categories: Set<AllergyCategory>.from(
              allergy.categories,
            ),
            details: Map<AllergyCategory, String>.from(
              allergy.details,
            ),
            legacyAllergen: allergy.legacyAllergen,
            observedReaction:
                allergy.observedReaction,
            emergencyInstructionSteps:
                List<String>.from(
              allergy.emergencyInstructionSteps,
            ),
          );
        },
      ).toList(),

      medicalDevices: data.medicalDevices.map(
        (device) {
          return MedicalDeviceData(
            deviceId: device.deviceId,
            deviceName: device.deviceName,
            mainUse: device.mainUse,
            isWornOrImplantedPermanently:
                device
                    .isWornOrImplantedPermanently,
          );
        },
      ).toList(),

      contacts: data.contacts.map(
        (contact) {
          return ContactData(
            fullName: contact.fullName,
            relationship: contact.relationship,
            phoneNumber: contact.phoneNumber,
            isPrimaryContact:
                contact.isPrimaryContact,
          );
        },
      ).toList(),

      primaryCareDoctor: PrimaryCareDoctorData(
        name: data.primaryCareDoctor.name,
        workplace:
            data.primaryCareDoctor.workplace,
        phoneNumber:
            data.primaryCareDoctor.phoneNumber,
      ),
    );
  }
}