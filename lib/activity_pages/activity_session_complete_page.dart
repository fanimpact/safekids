import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import '../professional/activity_note_page.dart';
import '../professional/establishment_activity_service.dart';
import '../professional/professional_child_repository.dart';
import '../recommendation_engine/recommendation_engine.dart';
import 'activity_child_selection_page.dart';
import 'activity_recommendations_page.dart';

class ActivitySessionCompletePage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivitySessionCompletePage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivitySessionCompletePage> createState() =>
      _ActivitySessionCompletePageState();
}

class _ActivitySessionCompletePageState
    extends State<ActivitySessionCompletePage> {
  bool _isSaving = false;

  bool get _isEditingExistingActivity =>
      widget.sessionData.activiteId != null;

  void _continueNewActivity(
    BuildContext context,
  ) {
    final sessionData = widget.sessionData;
    final etablissementId = sessionData.etablissementId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => etablissementId == null
            ? ActivityChildSelectionPage(
                sessionData: sessionData,
              )
            : ActivityChildSelectionPage(
                sessionData: sessionData,
                childrenListenable:
                    ProfessionalChildRepository.instance,
                childrenProvider: () =>
                    ProfessionalChildRepository
                        .instance.children,
                findChild: ProfessionalChildRepository
                    .instance.findByChildId,
                saveActivity: (data, childIds) =>
                    EstablishmentActivityService.instance
                        .saveActivity(
                  data,
                  childIds: childIds,
                  etablissementId: etablissementId,
                ),
                buildNextPage: (activity, result) =>
                    ActivityNotePage(
                  activity: activity,
                  recommendationResult: result,
                  etablissementId: etablissementId,
                ),
              ),
      ),
    );
  }

  /// Enregistre les caractéristiques modifiées d'une activité déjà
  /// générée (voir bouton "Modifier les caractéristiques" sur
  /// `ActivityRecommendationsPage`) — ne repasse pas par la sélection
  /// des enfants, recalcule directement les recommandations avec les
  /// mêmes enfants qu'avant.
  Future<void> _saveEdit(BuildContext context) async {
    final sessionData = widget.sessionData;
    final activiteId = sessionData.activiteId;

    if (activiteId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedActivity = await EstablishmentActivityService
          .instance
          .updateDescription(
        activiteId: activiteId,
        activity: sessionData,
      );

      final recommendationResult = RecommendationEngine(
        findChild: ProfessionalChildRepository
            .instance.findByChildId,
      ).generateRecommendations(updatedActivity);

      updatedActivity.recommendationsGenerated = true;

      if (!context.mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityRecommendationsPage(
            activitySession: updatedActivity,
            recommendationResult: recommendationResult,
            findChild: ProfessionalChildRepository
                .instance.findByChildId,
            etablissementId: sessionData.etablissementId,
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d’enregistrer les modifications : $error',
            ),
            duration: const Duration(seconds: 10),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = widget.sessionData;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditingExistingActivity
              ? 'Modifications terminées'
              : 'Activité complétée',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Icon(
                Icons.check_circle_outline,
                size: 72,
              ),

              const SizedBox(height: 24),

              Text(
                _isEditingExistingActivity
                    ? 'Les caractéristiques modifiées sont prêtes à être enregistrées.'
                    : 'Le questionnaire de l’activité est terminé.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              if (sessionData.activityName !=
                      null &&
                  sessionData.activityName!
                      .isNotEmpty)
                Text(
                  sessionData.activityName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),

              const SizedBox(height: 12),

              Text(
                _isEditingExistingActivity
                    ? 'Les recommandations seront recalculées avec les mêmes enfants qu’avant.'
                    : 'Vous allez maintenant sélectionner les enfants concernés par cette activité.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: _isSaving
                    ? null
                    : () => _isEditingExistingActivity
                        ? _saveEdit(context)
                        : _continueNewActivity(context),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditingExistingActivity
                            ? 'Enregistrer les modifications'
                            : 'Choisir les enfants',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
