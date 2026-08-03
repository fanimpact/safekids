import '../models/allergy_data.dart';
import '../models/child_profile_data.dart';
import '../models/child_profile_draft.dart';
import '../models/daily_treatment_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/medical_device_data.dart';
import '../models/medical_event_data.dart';
import '../models/medical_professional_data.dart';
import '../models/pathology_data.dart';

class TransmissionController {
  ChildProfileDraft _draft = ChildProfileDraft();
  ChildProfileData? _validatedProfile;

  ChildProfileDraft get formData => _draft;

  ChildProfileData? get validatedProfile => _validatedProfile;

  // IDENTITÉ

  void updateLastName(String value) {
    _draft.identity.lastName = value.trim();
  }

  void updateFirstName(String value) {
    _draft.identity.firstName = value.trim();
  }

  void updateDateOfBirth(DateTime value) {
    _draft.identity.dateOfBirth = value;
  }

  void updateHeightCm(String value) {
    _draft.identity.heightCm =
        double.tryParse(value.replaceAll(',', '.'));
  }

  void updateWeightKg(String value) {
    _draft.identity.weightKg =
        double.tryParse(value.replaceAll(',', '.'));
  }

  void updateHasDiagnosedPathologies(bool value) {
    _draft.identity.hasDiagnosedPathologies = value;
  }

  // PATHOLOGIES

  void ensureFirstPathology() {
    if (_draft.pathologies.isEmpty) {
      _draft.pathologies.add(PathologyData());
    }
  }

  void addPathology() {
    _draft.pathologies.add(PathologyData());
  }

  void removePathology(int index) {
    if (_draft.pathologies.length > 1 &&
        index >= 0 &&
        index < _draft.pathologies.length) {
      _draft.pathologies.removeAt(index);
    }
  }

  void updatePathologyName(int index, String value) {
    _draft.pathologies[index].name = value.trim();
  }

  void updatePathologyDiagnosisDate(int index, String value) {
    _draft.pathologies[index].approximateDiagnosisDate =
        value.trim();
  }

  void updateHasReferringProfessional(
    int index,
    bool value,
  ) {
    final pathology = _draft.pathologies[index];

    pathology.hasReferringProfessional = value;

    if (value) {
      pathology.referringProfessional ??=
          MedicalProfessionalData();
    } else {
      pathology.referringProfessional = null;
    }
  }

  void updateProfessionalName(int index, String value) {
    _draft.pathologies[index].referringProfessional?.name =
        value.trim();
  }

  void updateProfessionalSpecialty(
    int index,
    String value,
  ) {
    _draft.pathologies[index]
        .referringProfessional
        ?.specialty = value.trim();
  }

  void updateProfessionalWorkplace(
    int index,
    String value,
  ) {
    _draft.pathologies[index]
        .referringProfessional
        ?.workplace = value.trim();
  }

  void updateProfessionalPhone(int index, String value) {
    _draft.pathologies[index]
        .referringProfessional
        ?.phoneNumber = value.trim();
  }

  // ÉVÉNEMENTS MÉDICAUX

  void ensureFirstMedicalEvent() {
    if (_draft.medicalEvents.isEmpty) {
      _draft.medicalEvents.add(MedicalEventData());
    }
  }

  void addMedicalEvent() {
    _draft.medicalEvents.add(MedicalEventData());
  }

  void removeMedicalEvent(int index) {
    if (_draft.medicalEvents.length > 1 &&
        index >= 0 &&
        index < _draft.medicalEvents.length) {
      _draft.medicalEvents.removeAt(index);
    }
  }

  void updateMedicalEventDescription(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index].description =
        value.trim();
  }

  void updateMedicalEventDate(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index].approximateDate =
        value.trim();
  }

  void updateEmergencyServicesCalled(
    int index,
    bool value,
  ) {
    _draft.medicalEvents[index]
        .emergencyServicesCalled = value;
  }

  void updateHospitalized(int index, bool value) {
    final event = _draft.medicalEvents[index];

    event.hospitalized = value;

    if (!value) {
      event.hospitalizationDuration = null;
    }
  }

  void updateHospitalizationDuration(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index]
        .hospitalizationDuration = value.trim();
  }

  void updateImportantExaminationsPerformed(
    int index,
    bool value,
  ) {
    final event = _draft.medicalEvents[index];

    event.importantExaminationsPerformed = value;

    if (!value) {
      event.importantExaminations = null;
    }
  }

  void updateImportantExaminations(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index]
        .importantExaminations = value.trim();
  }

  void updateHasOngoingConsequences(
    int index,
    bool value,
  ) {
    final event = _draft.medicalEvents[index];

    event.hasOngoingConsequences = value;

    if (!value) {
      event.ongoingConsequences = null;
    }
  }

  void updateOngoingConsequences(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index]
        .ongoingConsequences = value.trim();
  }

  // MÉDECIN TRAITANT

  void updatePrimaryCareDoctorName(String value) {
    _draft.primaryCareDoctor.name = value.trim();
  }

  void updatePrimaryCareDoctorWorkplace(String value) {
    _draft.primaryCareDoctor.workplace = value.trim();
  }

  void updatePrimaryCareDoctorPhone(String value) {
    _draft.primaryCareDoctor.phoneNumber = value.trim();
  }

  // TRAITEMENTS QUOTIDIENS

  void ensureFirstDailyTreatment() {
    if (_draft.dailyTreatments.isEmpty) {
      _draft.dailyTreatments.add(DailyTreatmentData());
    }
  }

  void addDailyTreatment() {
    _draft.dailyTreatments.add(DailyTreatmentData());
  }

  void removeDailyTreatment(int index) {
    if (_draft.dailyTreatments.length > 1 &&
        index >= 0 &&
        index < _draft.dailyTreatments.length) {
      _draft.dailyTreatments.removeAt(index);
    }
  }

  void updateDailyTreatmentName(
    int index,
    String value,
  ) {
    _draft.dailyTreatments[index].medicationName =
        value.trim();
  }

  void updateDailyTreatmentDosage(
    int index,
    String value,
  ) {
    _draft.dailyTreatments[index].dosage =
        value.trim();
  }

  void updateDailyTreatmentTimes(
    int index,
    String value,
  ) {
    _draft.dailyTreatments[index]
        .administrationTimes = value.trim();
  }

  // TRAITEMENTS D’URGENCE

  void ensureFirstEmergencyTreatment() {
    if (_draft.emergencyTreatments.isEmpty) {
      _draft.emergencyTreatments.add(
        EmergencyTreatmentData(),
      );
    }
  }

  void addEmergencyTreatment() {
    _draft.emergencyTreatments.add(
      EmergencyTreatmentData(),
    );
  }

  void removeEmergencyTreatment(int index) {
    if (_draft.emergencyTreatments.length > 1 &&
        index >= 0 &&
        index < _draft.emergencyTreatments.length) {
      _draft.emergencyTreatments.removeAt(index);
    }
  }

  void updateEmergencyTreatmentName(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
        .medicationName = value.trim();
  }

  void updateEmergencyTreatmentCondition(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
        .administrationCondition = value.trim();
  }

  void updateEmergencyTreatmentDosage(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index].dosage =
        value.trim();
  }

  void updateEmergencyTreatmentMethod(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
        .administrationMethod = value.trim();
  }
    // ALLERGIES

  void ensureFirstAllergy() {
    if (_draft.allergies.isEmpty) {
      _draft.allergies.add(AllergyData());
    }
  }

  void addAllergy() {
    _draft.allergies.add(AllergyData());
  }

  void removeAllergy(int index) {
    if (_draft.allergies.length > 1 &&
        index >= 0 &&
        index < _draft.allergies.length) {
      _draft.allergies.removeAt(index);
    }
  }

  void updateAllergen(
    int index,
    String value,
  ) {
    _draft.allergies[index].allergen =
        value.trim();
  }

  void updateAllergyObservedReaction(
    int index,
    String value,
  ) {
    _draft.allergies[index].observedReaction =
        value.trim();
  }

  void updateAllergyHasDailyTreatment(
    int index,
    bool value,
  ) {
    final allergy = _draft.allergies[index];

    allergy.hasDailyTreatment = value;

    if (!value) {
      allergy.dailyTreatmentName = null;
      allergy.dailyTreatmentDosage = null;
    }
  }

  void updateAllergyDailyTreatmentName(
    int index,
    String value,
  ) {
    _draft.allergies[index]
        .dailyTreatmentName = value.trim();
  }

  void updateAllergyDailyTreatmentDosage(
    int index,
    String value,
  ) {
    _draft.allergies[index]
        .dailyTreatmentDosage = value.trim();
  }

  void updateAllergyHasEmergencyTreatment(
    int index,
    bool value,
  ) {
    final allergy = _draft.allergies[index];

    allergy.hasEmergencyTreatment = value;

    if (!value) {
      allergy.emergencyTreatmentName = null;
      allergy.emergencyTreatmentDosage = null;
    }
  }

  void updateAllergyEmergencyTreatmentName(
    int index,
    String value,
  ) {
    _draft.allergies[index]
        .emergencyTreatmentName = value.trim();
  }

  void updateAllergyEmergencyTreatmentDosage(
    int index,
    String value,
  ) {
    _draft.allergies[index]
        .emergencyTreatmentDosage = value.trim();
  }

  // DISPOSITIFS MÉDICAUX

  void ensureFirstMedicalDevice() {
    if (_draft.medicalDevices.isEmpty) {
      _draft.medicalDevices.add(
        MedicalDeviceData(),
      );
    }
  }

  void addMedicalDevice() {
    _draft.medicalDevices.add(
      MedicalDeviceData(),
    );
  }

  void removeMedicalDevice(int index) {
    if (_draft.medicalDevices.length > 1 &&
        index >= 0 &&
        index < _draft.medicalDevices.length) {
      _draft.medicalDevices.removeAt(index);
    }
  }

  void updateMedicalDeviceName(
    int index,
    String value,
  ) {
    _draft.medicalDevices[index].deviceName =
        value.trim();
  }

  void updateMedicalDeviceUse(
    int index,
    String value,
  ) {
    _draft.medicalDevices[index].mainUse =
        value.trim();
  }

  // VALIDATION

  void validateDraft() {
    _validatedProfile =
        ChildProfileData.fromDraft(_draft);
  }

  void resetForm() {
    _draft = ChildProfileDraft();
    _validatedProfile = null;
  }
}