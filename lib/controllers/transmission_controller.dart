import '../models/allergy_data.dart';
import '../models/child_profile_data.dart';
import '../models/child_profile_draft.dart';
import '../models/daily_treatment_data.dart';
import '../models/discontinued_treatment_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/medical_device_data.dart';
import '../models/medical_event_data.dart';
import '../models/medical_observation_data.dart';
import '../models/medical_professional_data.dart';
import '../models/pathology_data.dart';
import '../models/trigger_factor_data.dart';

class TransmissionController {
  ChildProfileDraft _draft;
  ChildProfileData? _validatedProfile;
  final bool isEditing;

  TransmissionController({
    ChildProfileDraft? initialDraft,
    this.isEditing = false,
  }) : _draft = initialDraft ?? ChildProfileDraft();

  ChildProfileDraft get formData => _draft;

  ChildProfileData? get validatedProfile =>
      _validatedProfile;

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

  void updateMeasurementsUpdatedAt(DateTime value) {
    _draft.identity.measurementsUpdatedAt = value;
  }

  void updateHeightCm(String value) {
    _draft.identity.heightCm = double.tryParse(
      value.replaceAll(',', '.'),
    );
  }

  void updateWeightKg(String value) {
    _draft.identity.weightKg = double.tryParse(
      value.replaceAll(',', '.'),
    );
  }

  void updateHasDiagnosedPathologies(
    bool value,
  ) {
    _draft.identity.hasDiagnosedPathologies =
        value;
  }

  // PATHOLOGIES

  void updateHasPathologies(bool value) {
    _draft.hasPathologies = value;
  }

  void ensureFirstPathology() {
    if (_draft.pathologies.isEmpty) {
      _draft.pathologies.add(
        PathologyData(),
      );
    }
  }

  void addPathology() {
    _draft.pathologies.add(
      PathologyData(),
    );
  }

  void removePathology(int index) {
    if (_draft.pathologies.length > 1 &&
        index >= 0 &&
        index < _draft.pathologies.length) {
      final pathologyId =
          _draft.pathologies[index].pathologyId;

      _draft.pathologies.removeAt(index);

      for (final treatment
          in _draft.dailyTreatments) {
        treatment.relatedPathologyIds.remove(
          pathologyId,
        );
      }

      for (final treatment
          in _draft.emergencyTreatments) {
        treatment.relatedPathologyIds.remove(
          pathologyId,
        );
        treatment.administrationStepByPathologyId
            .remove(pathologyId);
      }
    }
  }

  void clearPathologies() {
    for (final pathology in _draft.pathologies) {
      final pathologyId = pathology.pathologyId;

      for (final treatment in _draft.dailyTreatments) {
        treatment.relatedPathologyIds.remove(pathologyId);
      }

      for (final treatment in _draft.emergencyTreatments) {
        treatment.relatedPathologyIds.remove(pathologyId);
      }
    }

    _draft.pathologies.clear();
  }

  void updatePathologyName(
    int index,
    String value,
  ) {
    _draft.pathologies[index].name =
        value.trim();
  }

  void updatePathologyDiagnosisDate(
    int index,
    String value,
  ) {
    _draft.pathologies[index]
            .approximateDiagnosisDate =
        value.trim();
  }

  void updateHasReferringProfessional(
    int index,
    bool value,
  ) {
    final pathology =
        _draft.pathologies[index];

    pathology.hasReferringProfessional =
        value;

    if (value) {
      pathology.referringProfessional ??=
          MedicalProfessionalData();
    } else {
      pathology.referringProfessional =
          null;
    }
  }


  void updateProfessionalName(
    int index,
    String value,
  ) {
    _draft
        .pathologies[index]
        .referringProfessional
        ?.name = value.trim();
  }

  void updateProfessionalSpecialty(
    int index,
    String value,
  ) {
    _draft
        .pathologies[index]
        .referringProfessional
        ?.specialty = value.trim();
  }

  void updateProfessionalWorkplace(
    int index,
    String value,
  ) {
    _draft
        .pathologies[index]
        .referringProfessional
        ?.workplace = value.trim();
  }

  void updateProfessionalPhone(
    int index,
    String value,
  ) {
    _draft
        .pathologies[index]
        .referringProfessional
        ?.phoneNumber = value.trim();
  }

  void addPathologyEmergencyStep(
    int pathologyIndex,
  ) {
    _draft
        .pathologies[pathologyIndex]
        .emergencyInstructionSteps
        .add('');
  }

  void removePathologyEmergencyStep(
    int pathologyIndex,
    int stepIndex,
  ) {
    final pathology =
        _draft.pathologies[pathologyIndex];

    final steps = pathology.emergencyInstructionSteps;

    if (stepIndex >= 0 && stepIndex < steps.length) {
      steps.removeAt(stepIndex);

      // Sans ce réindexage, un traitement lié à l'étape 6 pointerait
      // vers l'étape 5 (un tout autre texte) après suppression d'une
      // étape antérieure — silencieusement faux, sur une fonctionnalité
      // de sécurité.
      _reindexAdministrationSteps(
        pathologyId: pathology.pathologyId,
        removedStepIndex: stepIndex,
      );
    }
  }

  void _reindexAdministrationSteps({
    String? pathologyId,
    String? allergyId,
    required int removedStepIndex,
  }) {
    for (final treatment in _draft.emergencyTreatments) {
      final map = pathologyId != null
          ? treatment.administrationStepByPathologyId
          : treatment.administrationStepByAllergyId;

      final id = pathologyId ?? allergyId!;
      final current = map[id];

      if (current == null) {
        continue;
      }

      if (current == removedStepIndex) {
        map.remove(id);
      } else if (current > removedStepIndex) {
        map[id] = current - 1;
      }
    }
  }

  void updatePathologyEmergencyStep(
    int pathologyIndex,
    int stepIndex,
    String value,
  ) {
    _draft
        .pathologies[pathologyIndex]
        .emergencyInstructionSteps[stepIndex] =
        value.trim();
  }

  // ÉVÉNEMENTS MÉDICAUX

  void addMedicalEvent() {
    _draft.medicalEvents.add(
      MedicalEventData(),
    );
  }

  void removeMedicalEvent(int index) {
    if (index >= 0 &&
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
    _draft.medicalEvents[index]
            .approximateDate =
        value.trim();
  }

  void updateEmergencyServicesCalled(
    int index,
    bool value,
  ) {
    _draft.medicalEvents[index]
            .emergencyServicesCalled =
        value;
  }

  void updateEmergencyTreatmentGiven(
    int index,
    bool value,
  ) {
    _draft.medicalEvents[index]
            .emergencyTreatmentGiven =
        value;
  }

  void updateHospitalized(
    int index,
    bool value,
  ) {
    final event =
        _draft.medicalEvents[index];

    event.hospitalized = value;

    if (!value) {
      event.hospitalName = null;
      event.hospitalizationDuration =
          null;
    }
  }

  void updateHospitalName(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index].hospitalName =
        value.trim();
  }

  void updateHospitalizationDuration(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index]
            .hospitalizationDuration =
        value.trim();
  }

  void updateImportantExaminationsPerformed(
    int index,
    bool value,
  ) {
    final event =
        _draft.medicalEvents[index];

    event.importantExaminationsPerformed =
        value;

    if (!value) {
      event.importantExaminations = null;
    }
  }

  void updateImportantExaminations(
    int index,
    String value,
  ) {
    _draft.medicalEvents[index]
            .importantExaminations =
        value.trim();
  }

  // OBSERVATIONS MÉDICALES

  void addMedicalObservation() {
    _draft.medicalObservations.add(
      MedicalObservationData(),
    );
  }

  void removeMedicalObservation(int index) {
    if (index >= 0 &&
        index < _draft.medicalObservations.length) {
      _draft.medicalObservations.removeAt(index);
    }
  }

  void updateMedicalObservationDescription(
    int index,
    String value,
  ) {
    _draft.medicalObservations[index]
            .description =
        value.trim();
  }

  void updateMedicalObservationDate(
    int index,
    String value,
  ) {
    _draft.medicalObservations[index]
            .approximateDate =
        value.trim();
  }

  void updateMedicalObservationConclusion(
    int index,
    String value,
  ) {
    _draft.medicalObservations[index]
            .conclusion =
        value.trim();
  }

  // FACTEURS DÉCLENCHANTS ET SENSIBILITÉS

  void updateHasTriggerFactors(
    bool value,
  ) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.hasTriggerFactors =
        value;

    if (!value) {
      triggerFactors.flashingLights =
          null;
      triggerFactors.requiresGlassesOutdoors =
          null;
      triggerFactors.heat = null;
      triggerFactors.fatigueOrLackOfSleep =
          null;
      triggerFactors.noise = null;
      triggerFactors.crowd = null;
      triggerFactors.confinedSpaces =
          null;
      triggerFactors.physicalEffort =
          null;
      triggerFactors
              .stressOrStrongEmotions =
          null;

      triggerFactors.waterContact = null;
      triggerFactors.waterVigilance =
          null;
      triggerFactors.otherWaterVigilance =
          null;

      triggerFactors.animals = null;
      triggerFactors.animalVigilance =
          null;
      triggerFactors
              .otherAnimalVigilance =
          null;

      triggerFactors.height = null;
      triggerFactors.heightVigilance =
          null;
      triggerFactors.otherHeightVigilance =
          null;

      triggerFactors.other = null;
    }
  }

  void updateFlashingLights(bool value) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.flashingLights = value;

    if (!value) {
      triggerFactors
              .requiresGlassesOutdoors =
          null;
    }
  }

  void updateRequiresGlassesOutdoors(
    bool value,
  ) {
    _draft
        .triggerFactors
        .requiresGlassesOutdoors = value;
  }

  void updateHeat(bool value) {
    _draft.triggerFactors.heat = value;
  }

  void updateFatigueOrLackOfSleep(
    bool value,
  ) {
    _draft
            .triggerFactors
            .fatigueOrLackOfSleep =
        value;
  }

  void updateNoise(bool value) {
    _draft.triggerFactors.noise = value;
  }

  void updateCrowd(bool value) {
    _draft.triggerFactors.crowd = value;
  }

  void updateConfinedSpaces(bool value) {
    _draft.triggerFactors.confinedSpaces =
        value;
  }

  void updatePhysicalEffort(bool value) {
    _draft.triggerFactors.physicalEffort =
        value;
  }

  void updateStressOrStrongEmotions(
    bool value,
  ) {
    _draft
            .triggerFactors
            .stressOrStrongEmotions =
        value;
  }

  // EAU

  void updateWaterContact(bool value) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.waterContact = value;

    if (!value) {
      triggerFactors.waterVigilance =
          null;
      triggerFactors.otherWaterVigilance =
          null;
    }
  }

  void updateWaterVigilance(
    WaterVigilance? value,
  ) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.waterVigilance = value;

    if (value != WaterVigilance.other) {
      triggerFactors.otherWaterVigilance =
          null;
    }
  }

  void updateOtherWaterVigilance(
    String value,
  ) {
    final trimmedValue = value.trim();

    _draft
            .triggerFactors
            .otherWaterVigilance =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  // ANIMAUX

  void updateAnimals(bool value) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.animals = value;

    if (!value) {
      triggerFactors.animalVigilance =
          null;
      triggerFactors
              .otherAnimalVigilance =
          null;
    }
  }

  void updateAnimalVigilance(
    AnimalVigilance? value,
  ) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.animalVigilance =
        value;

    if (value != AnimalVigilance.other) {
      triggerFactors
              .otherAnimalVigilance =
          null;
    }
  }

  void updateOtherAnimalVigilance(
    String value,
  ) {
    final trimmedValue = value.trim();

    _draft
            .triggerFactors
            .otherAnimalVigilance =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  // HAUTEUR

  void updateHeight(bool value) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.height = value;

    if (!value) {
      triggerFactors.heightVigilance =
          null;
      triggerFactors.otherHeightVigilance =
          null;
    }
  }

  void updateHeightVigilance(
    HeightVigilance? value,
  ) {
    final triggerFactors =
        _draft.triggerFactors;

    triggerFactors.heightVigilance =
        value;

    if (value != HeightVigilance.other) {
      triggerFactors
              .otherHeightVigilance =
          null;
    }
  }

  void updateOtherHeightVigilance(
    String value,
  ) {
    final trimmedValue = value.trim();

    _draft
            .triggerFactors
            .otherHeightVigilance =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void updateOtherTriggerFactor(
    String value,
  ) {
    final trimmedValue = value.trim();

    _draft.triggerFactors.other =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  // MÉDECIN TRAITANT

  void updatePrimaryCareDoctorName(
    String value,
  ) {
    _draft.primaryCareDoctor.name =
        value.trim();
  }

  void updatePrimaryCareDoctorWorkplace(
    String value,
  ) {
    _draft.primaryCareDoctor.workplace =
        value.trim();
  }

  void updatePrimaryCareDoctorPhone(
    String value,
  ) {
    _draft.primaryCareDoctor.phoneNumber =
        value.trim();
  }

  // TRAITEMENTS QUOTIDIENS

  void updateHasDailyTreatments(bool value) {
    _draft.hasDailyTreatments = value;
  }

  void ensureFirstDailyTreatment() {
    if (_draft.dailyTreatments.isEmpty) {
      _draft.dailyTreatments.add(
        DailyTreatmentData(),
      );
    }
  }

  void addDailyTreatment() {
    _draft.dailyTreatments.add(
      DailyTreatmentData(),
    );
  }

  void removeDailyTreatment(int index) {
    if (_draft.dailyTreatments.length >
            1 &&
        index >= 0 &&
        index <
            _draft.dailyTreatments.length) {
      _draft.dailyTreatments
          .removeAt(index);
    }
  }

  void updateDailyTreatmentName(
    int index,
    String value,
  ) {
    _draft.dailyTreatments[index]
            .medicationName =
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
            .administrationTimes =
        value.trim();
  }

  void updateDailyTreatmentPathology(
    int treatmentIndex,
    String pathologyId,
    bool selected,
  ) {
    final treatment =
        _draft.dailyTreatments[treatmentIndex];

    if (selected) {
      if (!treatment.relatedPathologyIds.contains(
        pathologyId,
      )) {
        treatment.relatedPathologyIds.add(
          pathologyId,
        );
      }
    } else {
      treatment.relatedPathologyIds.remove(
        pathologyId,
      );
    }
  }

  void updateDailyTreatmentAllergy(
    int treatmentIndex,
    String allergyId,
    bool selected,
  ) {
    final treatment =
        _draft.dailyTreatments[treatmentIndex];

    if (selected) {
      if (!treatment.relatedAllergyIds.contains(
        allergyId,
      )) {
        treatment.relatedAllergyIds.add(
          allergyId,
        );
      }
    } else {
      treatment.relatedAllergyIds.remove(
        allergyId,
      );
    }
  }

  // TRAITEMENTS ARRÊTÉS

  void updateHasDiscontinuedTreatments(bool value) {
    _draft.hasDiscontinuedTreatments = value;
  }

  void ensureFirstDiscontinuedTreatment() {
    if (_draft.discontinuedTreatments.isEmpty) {
      _draft.discontinuedTreatments.add(
        DiscontinuedTreatmentData(),
      );
    }
  }

  void addDiscontinuedTreatment() {
    _draft.discontinuedTreatments.add(
      DiscontinuedTreatmentData(),
    );
  }

  void removeDiscontinuedTreatment(int index) {
    if (_draft.discontinuedTreatments.length > 1 &&
        index >= 0 &&
        index <
            _draft.discontinuedTreatments.length) {
      _draft.discontinuedTreatments.removeAt(index);
    }
  }

  void updateDiscontinuedTreatmentName(
    int index,
    String value,
  ) {
    _draft.discontinuedTreatments[index]
            .medicationName =
        value.trim();
  }

  void updateDiscontinuedTreatmentStopDate(
    int index,
    String value,
  ) {
    _draft.discontinuedTreatments[index]
            .approximateStopDate =
        value.trim();
  }

  // TRAITEMENTS D’URGENCE

  void updateHasEmergencyTreatments(bool value) {
    _draft.hasEmergencyTreatments = value;
  }

  void ensureFirstEmergencyTreatment() {
    if (_draft.emergencyTreatments
        .isEmpty) {
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

  void removeEmergencyTreatment(
    int index,
  ) {
    if (_draft.emergencyTreatments.length >
            1 &&
        index >= 0 &&
        index <
            _draft
                .emergencyTreatments
                .length) {
      _draft.emergencyTreatments
          .removeAt(index);
    }
  }

  void updateEmergencyTreatmentName(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
            .medicationName =
        value.trim();
  }

  void updateEmergencyTreatmentCondition(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
            .administrationCondition =
        value.trim();
  }

  void updateEmergencyTreatmentDosage(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
            .dosage =
        value.trim();
  }

  void updateEmergencyTreatmentMethod(
    int index,
    String value,
  ) {
    _draft.emergencyTreatments[index]
            .administrationMethod =
        value.trim();
  }


  void updateEmergencyTreatmentPathology(
    int treatmentIndex,
    String pathologyId,
    bool selected,
  ) {
    final treatment =
        _draft.emergencyTreatments[
          treatmentIndex
        ];

    if (selected) {
      if (!treatment.relatedPathologyIds.contains(
        pathologyId,
      )) {
        treatment.relatedPathologyIds.add(
          pathologyId,
        );
      }
    } else {
      treatment.relatedPathologyIds.remove(
        pathologyId,
      );
      // Un lien vers une étape n'a plus de sens si le traitement n'est
      // plus rattaché à cette pathologie.
      treatment.administrationStepByPathologyId
          .remove(pathologyId);
    }
  }

  /// Étape (index) du protocole d'urgence de [pathologyId] à laquelle
  /// ce traitement est administré — choix explicite du parent. `null`
  /// efface le choix (retour au repli automatique, voir
  /// `resolveAdministrationStepIndex`).
  void updateEmergencyTreatmentPathologyStep(
    int treatmentIndex,
    String pathologyId,
    int? stepIndex,
  ) {
    final treatment =
        _draft.emergencyTreatments[
          treatmentIndex
        ];

    if (stepIndex == null) {
      treatment.administrationStepByPathologyId
          .remove(pathologyId);
    } else {
      treatment.administrationStepByPathologyId[
          pathologyId] = stepIndex;
    }
  }

  void updateEmergencyTreatmentAllergy(
    int treatmentIndex,
    String allergyId,
    bool selected,
  ) {
    final treatment =
        _draft.emergencyTreatments[
          treatmentIndex
        ];

    if (selected) {
      if (!treatment.relatedAllergyIds.contains(
        allergyId,
      )) {
        treatment.relatedAllergyIds.add(
          allergyId,
        );
      }
    } else {
      treatment.relatedAllergyIds.remove(
        allergyId,
      );
      treatment.administrationStepByAllergyId
          .remove(allergyId);
    }
  }

  /// Équivalent de [updateEmergencyTreatmentPathologyStep] pour une
  /// allergie.
  void updateEmergencyTreatmentAllergyStep(
    int treatmentIndex,
    String allergyId,
    int? stepIndex,
  ) {
    final treatment =
        _draft.emergencyTreatments[
          treatmentIndex
        ];

    if (stepIndex == null) {
      treatment.administrationStepByAllergyId
          .remove(allergyId);
    } else {
      treatment.administrationStepByAllergyId[
          allergyId] = stepIndex;
    }
  }

  // ALLERGIES

  void updateHasAllergies(bool value) {
    _draft.hasAllergies = value;
  }

  void ensureFirstAllergy() {
    if (_draft.allergies.isEmpty) {
      _draft.allergies.add(
        AllergyData(),
      );
    }
  }

  void addAllergy() {
    _draft.allergies.add(
      AllergyData(),
    );
  }

  void removeAllergy(int index) {
    if (_draft.allergies.length > 1 &&
        index >= 0 &&
        index < _draft.allergies.length) {
      final allergyId =
          _draft.allergies[index].allergyId;

      _draft.allergies.removeAt(index);

      for (final treatment
          in _draft.dailyTreatments) {
        treatment.relatedAllergyIds.remove(
          allergyId,
        );
      }

      for (final treatment
          in _draft.emergencyTreatments) {
        treatment.relatedAllergyIds.remove(
          allergyId,
        );
        treatment.administrationStepByAllergyId
            .remove(allergyId);
      }
    }
  }

  void clearAllergies() {
    for (final allergy in _draft.allergies) {
      final allergyId = allergy.allergyId;

      for (final treatment in _draft.dailyTreatments) {
        treatment.relatedAllergyIds.remove(allergyId);
      }

      for (final treatment in _draft.emergencyTreatments) {
        treatment.relatedAllergyIds.remove(allergyId);
      }
    }

    _draft.allergies.clear();
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
    _draft.allergies[index]
            .observedReaction =
        value.trim();
  }

  void addAllergyEmergencyStep(
    int allergyIndex,
  ) {
    _draft
        .allergies[allergyIndex]
        .emergencyInstructionSteps
        .add('');
  }

  void removeAllergyEmergencyStep(
    int allergyIndex,
    int stepIndex,
  ) {
    final allergy = _draft.allergies[allergyIndex];

    final steps = allergy.emergencyInstructionSteps;

    if (stepIndex >= 0 && stepIndex < steps.length) {
      steps.removeAt(stepIndex);

      _reindexAdministrationSteps(
        allergyId: allergy.allergyId,
        removedStepIndex: stepIndex,
      );
    }
  }

  void updateAllergyEmergencyStep(
    int allergyIndex,
    int stepIndex,
    String value,
  ) {
    _draft
        .allergies[allergyIndex]
        .emergencyInstructionSteps[stepIndex] =
        value.trim();
  }

  // DISPOSITIFS MÉDICAUX

  void updateHasMedicalDevices(bool value) {
    _draft.hasMedicalDevices = value;
  }

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
    if (_draft.medicalDevices.length >
            1 &&
        index >= 0 &&
        index <
            _draft.medicalDevices.length) {
      _draft.medicalDevices
          .removeAt(index);
    }
  }

  void updateMedicalDeviceName(
    int index,
    String value,
  ) {
    _draft.medicalDevices[index]
            .deviceName =
        value.trim();
  }

  void updateMedicalDeviceUse(
    int index,
    String value,
  ) {
    _draft.medicalDevices[index].mainUse =
        value.trim();
  }

  void updateMedicalDeviceWornPermanently(
    int index,
    bool value,
  ) {
    _draft.medicalDevices[index]
        .isWornOrImplantedPermanently = value;
  }

  // VALIDATION

  ChildProfileData validateAndGetProfile() {
    final profile =
        ChildProfileData.fromDraft(
      _draft,
    );

    _validatedProfile = profile;

    return profile;
  }

  void validateDraft() {
    validateAndGetProfile();
  }

  void resetForm() {
    _draft = ChildProfileDraft();
    _validatedProfile = null;
  }
}