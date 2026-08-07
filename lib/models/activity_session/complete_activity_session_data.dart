import 'activity_session_data.dart';

class CompleteActivitySessionData {
  ActivitySessionData activity;

  final List<String> childIds;

  bool questionnaireCompleted;

  bool recommendationsGenerated;

  CompleteActivitySessionData({
    required this.activity,
    this.childIds = const [],
    this.questionnaireCompleted = true,
    this.recommendationsGenerated = false,
  });

  String? get activityName =>
      activity.activityName;

  DateTime? get date =>
      activity.date;

  String? get location =>
      activity.location;
}