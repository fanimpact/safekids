import 'package:flutter/material.dart';

import '../children/children_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../repositories/child_repository.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';

class OtherInformationPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const OtherInformationPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<OtherInformationPage> createState() =>
      _OtherInformationPageState();
}

class _OtherInformationPageState
    extends State<OtherInformationPage> {
  late bool _hasOtherInformation;

  late final TextEditingController
      _otherInformationController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    _hasOtherInformation =
        data.hasOtherInformation;

    _otherInformationController =
        TextEditingController(
      text: data.details ?? '',
    );
  }

  @override
  void dispose() {
    _otherInformationController.dispose();
    super.dispose();
  }

  void _updateHasOtherInformation(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    setState(() {
      _hasOtherInformation = value;

      if (!value) {
        _otherInformationController.clear();
      }
    });

    data.hasOtherInformation = value;

    if (!value) {
      data.details = null;
    }
  }

  void _updateOtherInformation(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .otherInformation
            .details =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _finish() {
    final activityProfileController =
        widget.activityProfileController;

    final childId =
        activityProfileController.draft.childId;

    final activityProfile =
        activityProfileController
            .validateAndGetProfile();

    if (childId == null || childId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de retrouver le profil de l’enfant.',
          ),
        ),
      );

      return;
    }

    ChildRepository.instance.saveActivityProfile(
      childId: childId,
      activityProfile: activityProfile,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ChildrenPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Autres informations',
      subtitle:
          'Dernière étape du questionnaire.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                "Y a-t-il une autre information importante concernant l'accompagnement de votre enfant que nous n'avons pas abordée ?",
            value: _hasOtherInformation,
            onChanged:
                _updateHasOtherInformation,
          ),

          if (_hasOtherInformation) ...[
            const SizedBox(height: 24),

            SkTextField(
              label:
                  'Précisez cette information',
              controller:
                  _otherInformationController,
              onChanged:
                  _updateOtherInformation,
            ),

            const SizedBox(height: 12),

            const Text(
              'Cette information sera ajoutée au profil de votre enfant et pourra être transmise aux personnes que vous autoriserez.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 32),

          FilledButton(
            onPressed: _finish,
            child: const Text(
              'Terminer',
            ),
          ),
        ],
      ),
    );
  }
}