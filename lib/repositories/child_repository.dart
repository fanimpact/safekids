import '../models/activity_profile_data.dart';
import '../models/child_profile_data.dart';
import '../models/complete_child_profile_data.dart';

class ChildRepository {
  ChildRepository._();

  static final ChildRepository instance =
      ChildRepository._();

  final List<CompleteChildProfileData>
      _children = [];

  List<CompleteChildProfileData> get children =>
      List.unmodifiable(_children);

  void addChild(
    ChildProfileData child,
  ) {
    final existing = findByChildId(
      child.childId ?? '',
    );

    if (existing != null) {
      return;
    }

    _children.add(
      CompleteChildProfileData(
        essentialInformation: child,
      ),
    );
  }

  CompleteChildProfileData? findByChildId(
    String childId,
  ) {
    for (final child in _children) {
      if (child.childId == childId) {
        return child;
      }
    }

    return null;
  }

  void saveActivityProfile({
    required String childId,
    required ActivityProfileData activityProfile,
  }) {
    final child = findByChildId(childId);

    if (child == null) {
      return;
    }

    child.activityProfile = activityProfile;
    child.activityProfileCompleted = true;
  }

  void replaceChild(
    ChildProfileData child,
  ) {
    final existing = findByChildId(
      child.childId ?? '',
    );

    if (existing == null) {
      addChild(child);
      return;
    }

    existing.essentialInformation = child;
  }
}