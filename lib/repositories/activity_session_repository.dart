import '../models/activity_session/activity_session_data.dart';
import '../models/activity_session/complete_activity_session_data.dart';

class ActivitySessionRepository {
  ActivitySessionRepository._();

  static final ActivitySessionRepository instance =
      ActivitySessionRepository._();

  final List<CompleteActivitySessionData> _activities = [];

  List<CompleteActivitySessionData> get activities =>
      List.unmodifiable(_activities);

  void addActivity(
    ActivitySessionData activity,
  ) {
    _activities.add(
      CompleteActivitySessionData(
        activity: activity,
      ),
    );
  }

  void clearActivities() {
    _activities.clear();
  }

  void ensureDemoActivityExists() {
    final demoAlreadyExists = _activities.any(
      (activity) =>
          activity.activityName ==
          'Activité test SafeKids',
    );

    if (demoAlreadyExists) {
      return;
    }

    _activities.add(
      CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Activité test SafeKids',
          date: DateTime.now(),
          location: 'Lieu de démonstration',

          hasWaterNearby: true,
          childrenWillEnterWater: true,
          swimmingSupervisedByLifeguard: true,

          hasProlongedWalking: true,
          hasSignificantPhysicalEffort: false,

          hasTransport: true,
          transportTypes: {},

          hasOvernightStay: false,
          collectiveAccommodation: false,
          electricityMayBeUnavailable: null,
          phoneNetworkMayBeUnavailable: null,

          hasFallRisk: false,
          hasAnimalContact: true,

          hasLoudEnvironment: true,
          hasLargeCrowd: false,
          hasConfinedSpace: false,

          hasClothingChange: true,
        ),
      ),
    );
  }
}