import 'package:flutter/material.dart';

import '../models/activity_session/complete_activity_session_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import '../recommendation_engine/models/recommendation.dart';
import '../recommendation_engine/models/recommendation_category.dart';
import '../repositories/child_repository.dart';
import 'activities_home_page.dart';

class ActivityRecommendationsPage extends StatelessWidget {
  final CompleteActivitySessionData activitySession;
  final ActivityRecommendationResult recommendationResult;

  const ActivityRecommendationsPage({
    super.key,
    required this.activitySession,
    required this.recommendationResult,
  });

  static const List<RecommendationCategory> _categoryOrder = [
    RecommendationCategory.informationVigilance,
    RecommendationCategory.adaptation,
    RecommendationCategory.equipment,
    RecommendationCategory.emergencyMedication,
    RecommendationCategory.rememberToTake,
    RecommendationCategory.additionalInformation,
  ];

  String _categoryTitle(
    RecommendationCategory category,
  ) {
    switch (category) {
      case RecommendationCategory.informationVigilance:
        return 'Informations / Vigilances';

      case RecommendationCategory.adaptation:
        return 'Adaptations';

      case RecommendationCategory.equipment:
        return 'Matériel à emporter';

      case RecommendationCategory.emergencyMedication:
        return 'Médicaments d’urgence';

      case RecommendationCategory.rememberToTake:
        return 'Pensez à prendre…';

      case RecommendationCategory.additionalInformation:
        return 'Informations complémentaires';
    }
  }

  IconData _categoryIcon(
    RecommendationCategory category,
  ) {
    switch (category) {
      case RecommendationCategory.informationVigilance:
        return Icons.info_outline;

      case RecommendationCategory.adaptation:
        return Icons.tune;

      case RecommendationCategory.equipment:
        return Icons.backpack_outlined;

      case RecommendationCategory.emergencyMedication:
        return Icons.medical_services_outlined;

      case RecommendationCategory.rememberToTake:
        return Icons.medication_outlined;

      case RecommendationCategory.additionalInformation:
        return Icons.notes_outlined;
    }
  }

  String _childDisplayName(
    String childId,
  ) {
    final child = ChildRepository.instance.findByChildId(
      childId,
    );

    if (child == null) {
      return 'Enfant';
    }

    final firstName =
        child.essentialInformation.identity.firstName;

    final lastName =
        child.essentialInformation.identity.lastName;

    final displayName = [
      firstName,
      lastName,
    ].where(
      (value) =>
          value != null &&
          value.trim().isNotEmpty,
    ).map(
      (value) => value!.trim(),
    ).join(' ');

    return displayName.isEmpty
        ? 'Enfant'
        : displayName;
  }

  List<Recommendation> _globalRecommendationsForCategory(
    RecommendationCategory category,
  ) {
    return recommendationResult.globalRecommendations
        .where(
          (recommendation) =>
              recommendation.category == category,
        )
        .toList();
  }

  List<Recommendation> _childRecommendationsForCategory(
    String childId,
    RecommendationCategory category,
  ) {
    final childResult =
        recommendationResult.childResults.where(
      (result) => result.childId == childId,
    );

    if (childResult.isEmpty) {
      return [];
    }

    return childResult.first.recommendations
        .where(
          (recommendation) =>
              recommendation.category == category,
        )
        .toList();
  }

  bool _categoryHasRecommendations(
    RecommendationCategory category,
  ) {
    if (_globalRecommendationsForCategory(category).isNotEmpty) {
      return true;
    }

    for (final childId in activitySession.childIds) {
      if (_childRecommendationsForCategory(
        childId,
        category,
      ).isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Widget _buildRecommendationList(
    List<Recommendation> recommendations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations
          .map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recommendation.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCategory(
    RecommendationCategory category,
  ) {
    final globalRecommendations =
        _globalRecommendationsForCategory(
      category,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  _categoryIcon(category),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _categoryTitle(category),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (globalRecommendations.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Pour l’activité',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildRecommendationList(
                globalRecommendations,
              ),
            ],

            for (final childId
                in activitySession.childIds)
              if (_childRecommendationsForCategory(
                childId,
                category,
              ).isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  _childDisplayName(childId),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRecommendationList(
                  _childRecommendationsForCategory(
                    childId,
                    category,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  void _finish(
    BuildContext context,
  ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivitiesHomePage(),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _categoryOrder
        .where(_categoryHasRecommendations)
        .toList();

    final activityName =
        activitySession.activityName;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommandations',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Fiche de recommandations',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (activityName != null &&
                      activityName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (visibleCategories.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Aucune recommandation particulière pour cette activité.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final category
                        in visibleCategories)
                      _buildCategory(category),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      _finish(context),
                  child: const Text(
                    'Terminer',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}