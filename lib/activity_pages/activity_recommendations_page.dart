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

  String _childDisplayName(
    String childId,
  ) {
    final child =
        ChildRepository.instance.findByChildId(
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

  List<Recommendation> _recommendationsForChild(
    String childId,
  ) {
    final results =
        recommendationResult.childResults.where(
      (result) => result.childId == childId,
    );

    if (results.isEmpty) {
      return [];
    }

    return results.first.recommendations;
  }

  List<Recommendation> _recommendationsForChildAndCategory(
    String childId,
    RecommendationCategory category,
  ) {
    return _recommendationsForChild(childId)
        .where(
          (recommendation) =>
              recommendation.category == category,
        )
        .toList();
  }

  List<String> _allergyTexts(
    String childId,
  ) {
    final child =
        ChildRepository.instance.findByChildId(
      childId,
    );

    if (child == null) {
      return [];
    }

    final texts = <String>[];

    for (final allergy
        in child.essentialInformation.allergies) {
      final allergen =
          allergy.allergen?.trim();

      if (allergen == null ||
          allergen.isEmpty) {
        continue;
      }

      final reaction =
          allergy.observedReaction?.trim();

      if (reaction != null &&
          reaction.isNotEmpty) {
        texts.add(
          'Allergie : $allergen — Réaction connue : $reaction',
        );
      } else {
        texts.add(
          'Allergie : $allergen',
        );
      }
    }

    return texts;
  }

  bool _isSituationRecommendation(
    Recommendation recommendation,
  ) {
    return recommendation.category ==
            RecommendationCategory.adaptation ||
        recommendation.category ==
            RecommendationCategory.equipment ||
        recommendation.category ==
            RecommendationCategory.rememberToTake;
  }

  String _situationTitle(
    Recommendation recommendation,
  ) {
    final id = recommendation.id;

    if (id.startsWith('water_')) {
      return 'Baignade / Eau';
    }

    if (id.startsWith('overnight_')) {
      return 'Nuit';
    }

    if (id.startsWith('transport_')) {
      return 'Transport';
    }

    if (id.startsWith(
          'prolonged_walking_',
        ) ||
        id.startsWith(
          'intense_physical_effort_',
        )) {
      return 'Marche / Effort';
    }

    if (id.startsWith('environment_')) {
      return 'Environnement';
    }

    if (id.startsWith('clothing_')) {
      return 'Habillage';
    }

    if (id.startsWith('toilets_')) {
      return 'Toilettes';
    }

    if (id.startsWith('communication_')) {
      return 'Communication';
    }

    if (id.startsWith('transitions_')) {
      return 'Transitions';
    }

    if (id == 'photosensitivity_glasses') {
      return 'Extérieur';
    }

    return 'Autres';
  }

  Map<String, Map<String, List<Recommendation>>>
      _buildSituationGroups() {
    final groups =
        <String, Map<String, List<Recommendation>>>{};

    for (final childId in activitySession.childIds) {
      final recommendations =
          _recommendationsForChild(childId);

      for (final recommendation
          in recommendations) {
        if (!_isSituationRecommendation(
          recommendation,
        )) {
          continue;
        }

        final situation =
            _situationTitle(recommendation);

        groups.putIfAbsent(
          situation,
          () =>
              <String, List<Recommendation>>{},
        );

        groups[situation]!.putIfAbsent(
          childId,
          () => <Recommendation>[],
        );

        groups[situation]![childId]!.add(
          recommendation,
        );
      }
    }

    return groups;
  }

  Widget _buildSectionTitle(
    String title, {
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 7,
            ),
            child: Icon(
              Icons.circle,
              size: 6,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantPoints() {
    final childrenWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final vigilanceRecommendations =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .informationVigilance,
      );

      final allergyTexts =
          _allergyTexts(childId);

      final additionalInformation =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .additionalInformation,
      );

      if (vigilanceRecommendations.isEmpty &&
          allergyTexts.isEmpty &&
          additionalInformation.isEmpty) {
        continue;
      }

      childrenWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _childDisplayName(childId),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              for (final text in allergyTexts)
                _buildBullet(text),

              for (final recommendation
                  in vigilanceRecommendations)
                _buildBullet(
                  recommendation.text,
                ),

              for (final recommendation
                  in additionalInformation)
                _buildBullet(
                  recommendation.text,
                ),
            ],
          ),
        ),
      );
    }

    if (childrenWidgets.isEmpty &&
        recommendationResult
            .globalRecommendations
            .where(
              (recommendation) =>
                  recommendation.category ==
                  RecommendationCategory
                      .informationVigilance,
            )
            .isEmpty) {
      return const SizedBox.shrink();
    }

    final globalVigilances =
        recommendationResult
            .globalRecommendations
            .where(
              (recommendation) =>
                  recommendation.category ==
                  RecommendationCategory
                      .informationVigilance,
            )
            .toList();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Points importants',
              icon:
                  Icons.warning_amber_rounded,
            ),

            if (globalVigilances.isNotEmpty) ...[
              const Text(
                'Pour l’activité',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              for (final recommendation
                  in globalVigilances)
                _buildBullet(
                  recommendation.text,
                ),

              const SizedBox(height: 10),
            ],

            ...childrenWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildSituations() {
    final groups =
        _buildSituationGroups();

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    const preferredOrder = [
      'Baignade / Eau',
      'Nuit',
      'Transport',
      'Marche / Effort',
      'Extérieur',
      'Environnement',
      'Habillage',
      'Toilettes',
      'Communication',
      'Transitions',
      'Autres',
    ];

    final orderedSituations = <String>[
      ...preferredOrder.where(
        groups.containsKey,
      ),
      ...groups.keys.where(
        (key) =>
            !preferredOrder.contains(key),
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'À prévoir par situation',
              icon:
                  Icons.checklist_rounded,
            ),

            for (final situation
                in orderedSituations) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 10,
                ),
                child: Text(
                  situation,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              for (final childId
                  in activitySession.childIds)
                if (groups[situation]!
                    .containsKey(childId)) ...[
                  Text(
                    _childDisplayName(
                      childId,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  for (final recommendation
                      in groups[situation]![
                          childId]!)
                    _buildBullet(
                      recommendation.text,
                    ),

                  const SizedBox(height: 8),
                ],

              if (situation !=
                  orderedSituations.last)
                const Divider(
                  height: 24,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyMedications() {
    final childWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final medications =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .emergencyMedication,
      );

      if (medications.isEmpty) {
        continue;
      }

      childWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _childDisplayName(childId),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              for (final medication
                  in medications)
                _buildBullet(
                  medication.text,
                ),
            ],
          ),
        ),
      );
    }

    if (childWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.red.shade300,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Médicaments d’urgence',
              icon:
                  Icons.medical_services_outlined,
              color:
                  Colors.red.shade800,
            ),
            ...childWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSummary() {
    final childWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final equipment =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.equipment,
      );

      final rememberToTake =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.rememberToTake,
      );

      final allItems = <Recommendation>[
        ...equipment,
        ...rememberToTake,
      ];

      if (allItems.isEmpty) {
        continue;
      }

      childWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _childDisplayName(childId),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              for (final item in allItems)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 7,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons
                            .check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      Expanded(
                        child: Text(
                          item.text,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (childWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Matériel à prévoir — récapitulatif',
              icon:
                  Icons.backpack_outlined,
            ),
            ...childWidgets,
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
  Widget build(
    BuildContext context,
  ) {
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
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                children: [
                  const Text(
                    'Fiche de recommandations',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (activityName != null &&
                      activityName
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      activityName.trim(),
                      style:
                          const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 24,
                  ),

                  _buildImportantPoints(),

                  _buildSituations(),

                  _buildEmergencyMedications(),

                  _buildEquipmentSummary(),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
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
                  child:
                      const Text(
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