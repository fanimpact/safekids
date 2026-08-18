import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import '../recommendation_engine/recommendation_engine.dart';
import '../repositories/activity_session_repository.dart';
import '../repositories/child_repository.dart';
import 'activity_recommendations_page.dart';

class ActivityChildSelectionPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  /// Source des enfants proposés à la sélection — par défaut le
  /// répertoire parent (`ChildRepository`), fourni explicitement côté
  /// professionnel pour pointer vers le trombinoscope de
  /// l'établissement (`ProfessionalChildRepository`) sans dépendance en
  /// dur entre les deux.
  final Listenable childrenListenable;
  final List<CompleteChildProfileData> Function()
      childrenProvider;
  final CompleteChildProfileData? Function(String childId)
      findChild;

  /// Sauvegarde l'activité (Supabase, parent ou établissement selon
  /// l'appelant) et retourne l'activité complète prête pour le calcul
  /// des recommandations.
  final Future<CompleteActivitySessionData> Function(
    ActivitySessionData sessionData,
    List<String> childIds,
  ) saveActivity;

  /// Écran affiché une fois les recommandations calculées — par défaut
  /// `ActivityRecommendationsPage` directement (parcours parent
  /// existant). Le parcours professionnel fournit un écran
  /// intermédiaire (note d'activité) avant d'y arriver.
  final Widget Function(
    CompleteActivitySessionData activity,
    ActivityRecommendationResult result,
  )? buildNextPage;

  ActivityChildSelectionPage({
    super.key,
    required this.sessionData,
    Listenable? childrenListenable,
    List<CompleteChildProfileData> Function()?
        childrenProvider,
    CompleteChildProfileData? Function(String childId)?
        findChild,
    Future<CompleteActivitySessionData> Function(
      ActivitySessionData sessionData,
      List<String> childIds,
    )? saveActivity,
    this.buildNextPage,
  })  : childrenListenable =
            childrenListenable ?? ChildRepository.instance,
        childrenProvider = childrenProvider ??
            (() => ChildRepository.instance.children),
        findChild =
            findChild ?? ChildRepository.instance.findByChildId,
        saveActivity = saveActivity ??
            ((sessionData, childIds) =>
                ActivitySessionRepository.instance.saveActivity(
                  sessionData,
                  childIds: childIds,
                ));

  @override
  State<ActivityChildSelectionPage> createState() =>
      _ActivityChildSelectionPageState();
}

class _ActivityChildSelectionPageState
    extends State<ActivityChildSelectionPage> {
  final Set<String> _selectedChildIds = {};

  void _toggleChild({
    required String childId,
    required bool selected,
  }) {
    setState(() {
      if (selected) {
        _selectedChildIds.add(childId);
      } else {
        _selectedChildIds.remove(childId);
      }
    });
  }

  Future<void> _saveActivity() async {
    final completeActivity = await widget.saveActivity(
      widget.sessionData,
      _selectedChildIds.toList(),
    );

    final recommendationResult =
        RecommendationEngine(findChild: widget.findChild)
            .generateRecommendations(
      completeActivity,
    );

    completeActivity.recommendationsGenerated = true;

    if (!mounted) {
      return;
    }

    final buildNextPage = widget.buildNextPage;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => buildNextPage != null
            ? buildNextPage(
                completeActivity,
                recommendationResult,
              )
            : ActivityRecommendationsPage(
                activitySession: completeActivity,
                recommendationResult: recommendationResult,
                findChild: widget.findChild,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sans ça, cette page pourrait continuer d'afficher un enfant
    // supprimé/ajouté ailleurs entre-temps si elle reste en mémoire
    // sous une autre page au lieu d'être rouverte à neuf.
    return ListenableBuilder(
      listenable: widget.childrenListenable,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final children = widget.childrenProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enfants concernés',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quels enfants participeront à cette activité ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Sélectionnez un ou plusieurs enfants.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: children.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun enfant enregistré.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: children.length,
                        separatorBuilder:
                            (context, index) =>
                                const Divider(),
                        itemBuilder:
                            (context, index) {
                          final child =
                              children[index];

                          final childId =
                              child.childId;

                          final firstName =
                              child
                                  .essentialInformation
                                  .identity
                                  .firstName;

                          final lastName =
                              child
                                  .essentialInformation
                                  .identity
                                  .lastName;

                          if (childId == null ||
                              childId.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final isSelected =
                              _selectedChildIds
                                  .contains(
                            childId,
                          );

                          final displayName = [
                            firstName,
                            lastName,
                          ].where(
                            (value) =>
                                value != null &&
                                value.isNotEmpty,
                          ).join(' ');

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              _toggleChild(
                                childId: childId,
                                selected:
                                    value ?? false,
                              );
                            },
                            title: Text(
                              displayName.isEmpty
                                  ? 'Enfant'
                                  : displayName,
                            ),
                            controlAffinity:
                                ListTileControlAffinity
                                    .leading,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed:
                    _selectedChildIds.isEmpty
                        ? null
                        : _saveActivity,
                child: const Text(
                  'Générer les recommandations',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}