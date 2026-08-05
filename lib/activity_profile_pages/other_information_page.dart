import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../particulier_home_page.dart';
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
  bool _hasOtherInformation = false;

  late final TextEditingController
      _otherInformationController;

  @override
  void initState() {
    super.initState();

    _otherInformationController =
        TextEditingController();
  }

  @override
  void dispose() {
    _otherInformationController.dispose();
    super.dispose();
  }

  void _updateHasOtherInformation(bool value) {
    setState(() {
      _hasOtherInformation = value;

      if (!value) {
        _otherInformationController.clear();
      }
    });
  }

  void _finish() {
    widget.activityProfileController.validateDraft();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ParticulierHomePage(),
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