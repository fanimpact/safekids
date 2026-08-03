import '../models/child_profile_data.dart';
import '../models/child_profile_draft.dart';

class TransmissionController {
  ChildProfileDraft _draft = ChildProfileDraft();
  ChildProfileData? _validatedProfile;

  ChildProfileDraft get formData => _draft;

  ChildProfileData? get validatedProfile => _validatedProfile;

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

  void validateDraft() {
    _validatedProfile = ChildProfileData.fromDraft(_draft);
  }

  void resetForm() {
    _draft = ChildProfileDraft();
    _validatedProfile = null;
  }
}