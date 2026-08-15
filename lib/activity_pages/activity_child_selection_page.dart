import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import '../recommendation_engine/recommendation_engine.dart';
import '../repositories/activity_session_repository.dart';
import '../repositories/child_repository.dart';
import 'activity_recommendations_page.dart';

class ActivityChildSelectionPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityChildSelectionPage({
    super.key,
    required this.sessionData,
  });

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

  void _saveActivity() {
    final completeActivity =
        ActivitySessionRepository.instance.addActivity(
      widget.sessionData,
      childIds: _selectedChildIds.toList(),
    );

    final recommendationResult =
        RecommendationEngine().generateRecommendations(
      completeActivity,
    );

    completeActivity.recommendationsGenerated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityRecommendationsPage(
          activitySession: completeActivity,
          recommendationResult: recommendationResult,
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
      listenable: ChildRepository.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final children =
        ChildRepository.instance.children;

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