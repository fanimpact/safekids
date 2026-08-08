import 'allergy_data.dart';
import 'child_profile_draft.dart';
import 'contact_data.dart';
import 'daily_treatment_data.dart';
import 'emergency_treatment_data.dart';
import 'identity_data.dart';
import 'medical_device_data.dart';
import 'medical_event_data.dart';
import 'medical_professional_data.dart';
import 'pathology_data.dart';
import 'primary_care_doctor_data.dart';
import 'trigger_factor_data.dart';

class ChildProfileData {
  final String? userId;
  final String? childId;

  final IdentityData identity;

  final List<PathologyData> pathologies;
  final List<MedicalEventData> medicalEvents;

  final TriggerFactorData triggerFactors;

  final List<DailyTreatmentData>
      dailyTreatments;
  final List<EmergencyTreatmentData>
      emergencyTreatments;

  final List<AllergyData> allergies;
  final List<MedicalDeviceData>
      medicalDevices;
  final List<ContactData> contacts;

  final PrimaryCareDoctorData
      primaryCareDoctor;

  ChildProfileData({
    this.userId,
    this.childId,
    required this.identity,
    required this.pathologies,
    required this.medicalEvents,
    required this.triggerFactors,
    required this.dailyTreatments,
    required this.emergencyTreatments,
    required this.allergies,
    required this.medicalDevices,
    required this.contacts,
    required this.primaryCareDoctor,
  });

  factory ChildProfileData.fromDraft(
    ChildProfileDraft draft,
  ) {
    return ChildProfileData(
      userId: draft.userId,
      childId: draft.childId,

      identity: IdentityData(
        lastName:
            draft.identity.lastName,
        firstName:
            draft.identity.firstName,
        dateOfBirth:
            draft.identity.dateOfBirth,
        heightCm:
            draft.identity.heightCm,
        weightKg:
            draft.identity.weightKg,
        hasDiagnosedPathologies:
            draft
                .identity
                .hasDiagnosedPathologies,
      ),

      pathologies:
          draft.pathologies.map(
        (pathology) {
          final professional =
              pathology
                  .referringProfessional;

          return PathologyData(
            name: pathology.name,
            approximateDiagnosisDate:
                pathology
                    .approximateDiagnosisDate,
            hasReferringProfessional:
                pathology
                    .hasReferringProfessional,
            referringProfessional:
                professional == null
                    ? null
                    : MedicalProfessionalData(
                        name:
                            professional
                                .name,
                        specialty:
                            professional
                                .specialty,
                        workplace:
                            professional
                                .workplace,
                        phoneNumber:
                            professional
                                .phoneNumber,
                      ),
          );
        },
      ).toList(),

      medicalEvents:
          draft.medicalEvents.map(
        (event) {
          return MedicalEventData(
            description:
                event.description,
            approximateDate:
                event.approximateDate,
            emergencyServicesCalled:
                event
                    .emergencyServicesCalled,
            hospitalized:
                event.hospitalized,
            hospitalizationDuration:
                event
                    .hospitalizationDuration,
            importantExaminationsPerformed:
                event
                    .importantExaminationsPerformed,
            importantExaminations:
                event
                    .importantExaminations,
            hasOngoingConsequences:
                event
                    .hasOngoingConsequences,
            ongoingConsequences:
                event
                    .ongoingConsequences,
          );
        },
      ).toList(),

      triggerFactors:
          TriggerFactorData(
        hasTriggerFactors:
            draft
                .triggerFactors
                .hasTriggerFactors,

        flashingLights:
            draft
                .triggerFactors
                .flashingLights,

        requiresGlassesOutdoors:
            draft
                .triggerFactors
                .requiresGlassesOutdoors,

        heat:
            draft.triggerFactors.heat,

        fatigueOrLackOfSleep:
            draft
                .triggerFactors
                .fatigueOrLackOfSleep,

        noise:
            draft.triggerFactors.noise,

        crowd:
            draft.triggerFactors.crowd,

        confinedSpaces:
            draft
                .triggerFactors
                .confinedSpaces,

        physicalEffort:
            draft
                .triggerFactors
                .physicalEffort,

        stressOrStrongEmotions:
            draft
                .triggerFactors
                .stressOrStrongEmotions,

        waterContact:
            draft
                .triggerFactors
                .waterContact,

        waterVigilance:
            draft
                .triggerFactors
                .waterVigilance,

        otherWaterVigilance:
            draft
                .triggerFactors
                .otherWaterVigilance,

        animals:
            draft
                .triggerFactors
                .animals,

        animalVigilance:
            draft
                .triggerFactors
                .animalVigilance,

        otherAnimalVigilance:
            draft
                .triggerFactors
                .otherAnimalVigilance,

        height:
            draft
                .triggerFactors
                .height,

        heightVigilance:
            draft
                .triggerFactors
                .heightVigilance,

        otherHeightVigilance:
            draft
                .triggerFactors
                .otherHeightVigilance,

        other:
            draft.triggerFactors.other,
      ),

      dailyTreatments:
          draft.dailyTreatments.map(
        (treatment) {
          return DailyTreatmentData(
            medicationName:
                treatment
                    .medicationName,
            dosage:
                treatment.dosage,
            administrationTimes:
                treatment
                    .administrationTimes,
          );
        },
      ).toList(),

      emergencyTreatments:
          draft.emergencyTreatments.map(
        (treatment) {
          return EmergencyTreatmentData(
            medicationName:
                treatment
                    .medicationName,
            administrationCondition:
                treatment
                    .administrationCondition,
            dosage:
                treatment.dosage,
            administrationMethod:
                treatment
                    .administrationMethod,
          );
        },
      ).toList(),

      allergies:
          draft.allergies.map(
        (allergy) {
          return AllergyData(
            allergen:
                allergy.allergen,
            observedReaction:
                allergy
                    .observedReaction,
            hasDailyTreatment:
                allergy
                    .hasDailyTreatment,
            dailyTreatmentName:
                allergy
                    .dailyTreatmentName,
            dailyTreatmentDosage:
                allergy
                    .dailyTreatmentDosage,
            hasEmergencyTreatment:
                allergy
                    .hasEmergencyTreatment,
            emergencyTreatmentName:
                allergy
                    .emergencyTreatmentName,
            emergencyTreatmentDosage:
                allergy
                    .emergencyTreatmentDosage,
          );
        },
      ).toList(),

      medicalDevices:
          draft.medicalDevices.map(
        (device) {
          return MedicalDeviceData(
            deviceName:
                device.deviceName,
            mainUse:
                device.mainUse,
          );
        },
      ).toList(),

      contacts:
          draft.contacts.map(
        (contact) {
          return ContactData(
            fullName:
                contact.fullName,
            relationship:
                contact.relationship,
            phoneNumber:
                contact.phoneNumber,
            isPrimaryContact:
                contact
                    .isPrimaryContact,
          );
        },
      ).toList(),

      primaryCareDoctor:
          PrimaryCareDoctorData(
        name:
            draft
                .primaryCareDoctor
                .name,
        workplace:
            draft
                .primaryCareDoctor
                .workplace,
        phoneNumber:
            draft
                .primaryCareDoctor
                .phoneNumber,
      ),
    );
  }
}