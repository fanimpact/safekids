import 'allergy_data.dart';
import 'contact_data.dart';
import 'daily_treatment_data.dart';
import 'emergency_treatment_data.dart';
import 'identity_data.dart';
import 'medical_device_data.dart';
import 'medical_event_data.dart';
import 'pathology_data.dart';
import 'primary_care_doctor_data.dart';

class ChildProfileDraft {
  String? userId;
  String? childId;

  final IdentityData identity;

  final List<PathologyData> pathologies;
  final List<MedicalEventData> medicalEvents;

  final List<DailyTreatmentData> dailyTreatments;
  final List<EmergencyTreatmentData> emergencyTreatments;

  final List<AllergyData> allergies;
  final List<MedicalDeviceData> medicalDevices;
  final List<ContactData> contacts;

  final PrimaryCareDoctorData primaryCareDoctor;

  ChildProfileDraft({
    this.userId,
    this.childId,
    IdentityData? identity,
    List<PathologyData>? pathologies,
    List<MedicalEventData>? medicalEvents,
    List<DailyTreatmentData>? dailyTreatments,
    List<EmergencyTreatmentData>? emergencyTreatments,
    List<AllergyData>? allergies,
    List<MedicalDeviceData>? medicalDevices,
    List<ContactData>? contacts,
    PrimaryCareDoctorData? primaryCareDoctor,
  })  : identity = identity ?? IdentityData(),
        pathologies = pathologies ?? [],
        medicalEvents = medicalEvents ?? [],
        dailyTreatments = dailyTreatments ?? [],
        emergencyTreatments = emergencyTreatments ?? [],
        allergies = allergies ?? [],
        medicalDevices = medicalDevices ?? [],
        contacts = contacts ?? [],
        primaryCareDoctor =
            primaryCareDoctor ?? PrimaryCareDoctorData();
}