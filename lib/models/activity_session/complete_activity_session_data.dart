import 'activity_session_data.dart';

class CompleteActivitySessionData {
  /// Identifiant de la ligne `activites_preparees` côté Supabase — null
  /// tant que l'activité n'a pas encore été sauvegardée.
  String? id;

  ActivitySessionData activity;

  final List<String> childIds;

  bool questionnaireCompleted;

  bool recommendationsGenerated;

  CompleteActivitySessionData({
    this.id,
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