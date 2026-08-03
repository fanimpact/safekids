import 'identity_data.dart';
import 'pathology_data.dart';
import 'medical_event_data.dart';
import 'treatment_data.dart';
import 'allergy_data.dart';
import 'medical_device_data.dart';
import 'contact_data.dart';
import 'child_profile_draft.dart';

class ChildProfileData {
  final String? userId;
  final String? childId;

  final IdentityData identity;
  final List<PathologyData> pathologies;
  final List<MedicalEventData> medicalEvents;
  final List<TreatmentData> treatments;
  final List<AllergyData> allergies;
  final List<MedicalDeviceData> medicalDevices;
  final List<ContactData> contacts;

  ChildProfileData({
    this.userId,
    this.childId,
    required this.identity,
    required this.pathologies,
    required this.medicalEvents,
    required this.treatments,
    required this.allergies,
    required this.medicalDevices,
    required this.contacts,
  });

  factory ChildProfileData.fromDraft(ChildProfileDraft draft) {
    return ChildProfileData(
      userId: draft.userId,
      childId: draft.childId,

      identity: IdentityData(
        lastName: draft.identity.lastName,
        firstName: draft.identity.firstName,
        dateOfBirth: draft.identity.dateOfBirth,
        heightCm: draft.identity.heightCm,
        weightKg: draft.identity.weightKg,
        hasDiagnosedPathologies:
            draft.identity.hasDiagnosedPathologies,
      ),

      pathologies: draft.pathologies
          .map(
            (pathology) => PathologyData(
              name: pathology.name,
              approximateDiagnosisDate:
                  pathology.approximateDiagnosisDate,
              healthcareProfessional:
                  pathology.healthcareProfessional,
            ),
          )
          .toList(),

      medicalEvents: draft.medicalEvents
          .map(
            (event) => MedicalEventData(
              approximateDate: event.approximateDate,
              description: event.description,
              emergencyServicesCalled:
                  event.emergencyServicesCalled,
              hospitalized: event.hospitalized,
              hospitalizationDuration:
                  event.hospitalizationDuration,
              importantExaminations:
                  event.importantExaminations,
            ),
          )
          .toList(),

      treatments: draft.treatments
          .map(
            (treatment) => TreatmentData(
              type: treatment.type,
              medicationName: treatment.medicationName,
              dosage: treatment.dosage,
              usualIntakeTime: treatment.usualIntakeTime,
            ),
          )
          .toList(),

      allergies: draft.allergies
          .map(
            (allergy) => AllergyData(
              allergen: allergy.allergen,
              type: allergy.type,
              observedReaction: allergy.observedReaction,
              prescribedMedication:
                  allergy.prescribedMedication,
              prescribedDosage: allergy.prescribedDosage,
            ),
          )
          .toList(),

      medicalDevices: draft.medicalDevices
          .map(
            (device) => MedicalDeviceData(
              deviceName: device.deviceName,
              mainUse: device.mainUse,
            ),
          )
          .toList(),

      contacts: draft.contacts
          .map(
            (contact) => ContactData(
              fullName: contact.fullName,
              relationship: contact.relationship,
              phoneNumber: contact.phoneNumber,
              isPrimaryContact: contact.isPrimaryContact,
            ),
          )
          .toList(),
    );
  }
}