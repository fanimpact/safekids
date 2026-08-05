import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
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
  late bool _requiresAdaptations;
  late bool _requiresActivityAdjustment;

  late final TextEditingController
      _activityAdjustmentController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .walkingEffort;

    _requiresAdaptations =
        data.requiresAdaptations;

    _requiresActivityAdjustment =
        data.requiresActivityAdjustment;

    _activityAdjustmentController =
        TextEditingController(
      text: data.activityAdjustmentDetails ?? '',
    );
  }

  @override
  void dispose() {
    _activityAdjustmentController.dispose();
    super.dispose();
  }

  void _updateRequiresAdaptations(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .walkingEffort;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _requiresActivityAdjustment = false;
        _activityAdjustmentController.clear();
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.requiresActivityAdjustment = false;
      data.activityAdjustmentDetails = null;
    }
  }

  void _updateRequiresActivityAdjustment(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .walkingEffort;

    setState(() {
      _requiresActivityAdjustment = value;

      if (!value) {
        _activityAdjustmentController.clear();
      }
    });

    data.requiresActivityAdjustment = value;

    if (!value) {
      data.activityAdjustmentDetails = null;
    }
  }

  void _updateActivityAdjustmentDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .walkingEffort
            .activityAdjustmentDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
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
                'Votre enfant nécessite-t-il des adaptations lors des activités comportant une marche prolongée ou un effort physique important, par rapport à un enfant de son âge ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),

          if (_requiresAdaptations) ...[
            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Les modalités de l’activité doivent-elles être adaptées ?',
              value:
                  _requiresActivityAdjustment,
              onChanged:
                  _updateRequiresActivityAdjustment,
            ),

            if (_requiresActivityAdjustment) ...[
              const SizedBox(height: 12),

              SkTextField(
                label:
                    'Précisez les adaptations nécessaires',
                controller:
                    _activityAdjustmentController,
                onChanged:
                    _updateActivityAdjustmentDetails,
              ),

              const SizedBox(height: 8),

              const Text(
                'Exemples : pauses régulières, distance à limiter, éviter certains efforts…',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ],

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