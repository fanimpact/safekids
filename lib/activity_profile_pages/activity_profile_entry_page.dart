import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import 'aquatic_activity_page.dart';

class ActivityProfileEntryPage extends StatefulWidget {
  final ActivityProfileController?
      activityProfileController;

  const ActivityProfileEntryPage({
    super.key,
    this.activityProfileController,
  });

  @override
  State<ActivityProfileEntryPage> createState() =>
      _ActivityProfileEntryPageState();
}

class _ActivityProfileEntryPageState
    extends State<ActivityProfileEntryPage> {
  late final ActivityProfileController
      _activityProfileController;

  @override
  void initState() {
    super.initState();

    _activityProfileController =
        widget.activityProfileController ??
            ActivityProfileController();
  }

  @override
  Widget build(BuildContext context) {
    return AquaticActivityPage(
      activityProfileController:
          _activityProfileController,
    );
  }
}