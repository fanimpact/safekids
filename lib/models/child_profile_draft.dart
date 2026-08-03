import 'identity_data.dart';
import 'pathology_data.dart';
import 'medical_event_data.dart';
import 'treatment_data.dart';
import 'allergy_data.dart';
import 'medical_device_data.dart';
import 'contact_data.dart';

class ChildProfileDraft {
  String? userId;
  String? childId;

  final IdentityData identity;
  final List<PathologyData> pathologies;
  final List<MedicalEventData> medicalEvents;
  final List<TreatmentData> treatments;
  final List<AllergyData> allergies;
  final List<MedicalDeviceData> medicalDevices;
  final List<ContactData> contacts;

  ChildProfileDraft({
    this.userId,
    this.childId,
    IdentityData? identity,
    List<PathologyData>? pathologies,
    List<MedicalEventData>? medicalEvents,
    List<TreatmentData>? treatments,
    List<AllergyData>? allergies,
    List<MedicalDeviceData>? medicalDevices,
    List<ContactData>? contacts,
  })  : identity = identity ?? IdentityData(),
        pathologies = pathologies ?? [],
        medicalEvents = medicalEvents ?? [],
        treatments = treatments ?? [],
        allergies = allergies ?? [],
        medicalDevices = medicalDevices ?? [],
        contacts = contacts ?? [];
}