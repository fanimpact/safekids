import 'activity_profile_data.dart';
import 'child_profile_data.dart';

class CompleteChildProfileData {
  ChildProfileData essentialInformation;

  ActivityProfileData? activityProfile;

  bool essentialInformationCompleted;
  bool activityProfileCompleted;

  CompleteChildProfileData({
    required this.essentialInformation,
    this.activityProfile,
    this.essentialInformationCompleted = true,
    this.activityProfileCompleted = false,
  });

  String? get userId =>
      essentialInformation.userId;

  String? get childId =>
      essentialInformation.childId;
}