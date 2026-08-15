import '../models/activity_profile_data.dart';
import '../models/activity_profile_draft.dart';

class ActivityProfileController {
  ActivityProfileDraft _draft;

  ActivityProfileData? _validatedProfile;

  ActivityProfileController({
    ActivityProfileDraft? initialDraft,
  }) : _draft = initialDraft ?? ActivityProfileDraft();

  ActivityProfileDraft get draft => _draft;

  ActivityProfileData? get validatedProfile =>
      _validatedProfile;

  ActivityProfileData validateAndGetProfile() {
    final profile = _draft.toProfile();

    _validatedProfile = profile;

    return profile;
  }

  void validateDraft() {
    validateAndGetProfile();
  }

  void reset() {
    _draft = ActivityProfileDraft();
    _validatedProfile = null;
  }
}
