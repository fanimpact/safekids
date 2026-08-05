import '../models/child_profile_data.dart';

class ChildRepository {
  ChildRepository._();

  static final ChildRepository instance = ChildRepository._();

  final List<ChildProfileData> _children = [];

  List<ChildProfileData> get children =>
      List.unmodifiable(_children);

  void addChild(ChildProfileData child) {
    _children.add(child);
  }
}