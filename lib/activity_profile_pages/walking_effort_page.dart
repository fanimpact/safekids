import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_yes_no_field.dart';
import 'overnight_stay_page.dart';

class WalkingEffortPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const WalkingEffortPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<WalkingEffortPage> createState() =>
      _WalkingEffortPageState();
}

class _WalkingEffortPageState
    extends State<WalkingEffortPage> {
  late bool _prolongedWalkingRequiresVigilance;
  late bool _intensePhysicalEffortRequiresVigilance;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .walkingEffort;

    _prolongedWalkingRequiresVigilance =
        data.prolongedWalkingRequiresVigilance;

    _intensePhysicalEffortRequiresVigilance =
        data.intensePhysicalEffortRequiresVigilance;
  }

  void _updateProlongedWalkingRequiresVigilance(
    bool value,
  ) {
    setState(() {
      _prolongedWalkingRequiresVigilance = value;
    });

    widget
        .activityProfileController
        .draft
        .walkingEffort
        .prolongedWalkingRequiresVigilance = value;
  }

  void _updateIntensePhysicalEffortRequiresVigilance(
    bool value,
  ) {
    setState(() {
      _intensePhysicalEffortRequiresVigilance = value;
    });

    widget
        .activityProfileController
        .draft
        .walkingEffort
        .intensePhysicalEffortRequiresVigilance = value;
  }

  void _continue() {
    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OvernightStayPage(
          activityProfileController:
              widget.activityProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Marche prolongée / effort physique',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'La marche prolongée nécessite-t-elle une vigilance particulière pour votre enfant ?',
            value:
                _prolongedWalkingRequiresVigilance,
            onChanged:
                _updateProlongedWalkingRequiresVigilance,
          ),

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Un effort physique intense nécessite-t-il une vigilance particulière pour votre enfant ?',
            value:
                _intensePhysicalEffortRequiresVigilance,
            onChanged:
                _updateIntensePhysicalEffortRequiresVigilance,
          ),

          const SizedBox(height: 30),

          FilledButton(
            onPressed: _continue,
            child: const Text(
              'Continuer',
            ),
          ),
        ],
      ),
    );
  }
}