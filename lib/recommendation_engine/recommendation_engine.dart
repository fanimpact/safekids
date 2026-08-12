import '../models/activity_session/complete_activity_session_data.dart';
import '../repositories/child_repository.dart';
import 'models/activity_recommendation_result.dart';
import 'models/child_recommendation_result.dart';
import 'models/recommendation.dart';
import 'rules/clothing_rules.dart';
import 'rules/communication_rules.dart';
import 'rules/emergency_medication_rules.dart';
import 'rules/environment_rules.dart';
import 'rules/global_activity_rules.dart';
import 'rules/other_information_rules.dart';
import 'rules/overnight_stay_rules.dart';
import 'rules/safety_rules.dart';
import 'rules/toilets_rules.dart';
import 'rules/transitions_rules.dart';
import 'rules/transport_rules.dart';
import 'rules/universal_trigger_rules.dart';
import 'rules/walking_effort_rules.dart';
import 'rules/water_rules.dart';

class RecommendationEngine {
  final ChildRepository _childRepository;

  final UniversalTriggerRules _universalTriggerRules =
      const UniversalTriggerRules();

  final CommunicationRules _communicationRules =
      const CommunicationRules();

  final ToiletsRules _toiletsRules =
      const ToiletsRules();

  final TransitionsRules _transitionsRules =
      const TransitionsRules();

  final OtherInformationRules _otherInformationRules =
      const OtherInformationRules();

  final WaterRules _waterRules =
      const WaterRules();

  final WalkingEffortRules _walkingEffortRules =
      const WalkingEffortRules();

  final TransportRules _transportRules =
      const TransportRules();

  final OvernightStayRules _overnightStayRules =
      const OvernightStayRules();

  final EnvironmentRules _environmentRules =
      const EnvironmentRules();

  final ClothingRules _clothingRules =
      const ClothingRules();

  final SafetyRules _safetyRules =
      const SafetyRules();

  final EmergencyMedicationRules _emergencyMedicationRules =
      const EmergencyMedicationRules();

  final GlobalActivityRules _globalActivityRules =
      const GlobalActivityRules();

  RecommendationEngine({
    ChildRepository? childRepository,
  }) : _childRepository =
            childRepository ?? ChildRepository.instance;

  ActivityRecommendationResult generateRecommendations(
    CompleteActivitySessionData activitySession,
  ) {
    final childResults = <ChildRecommendationResult>[];

    for (final childId in activitySession.childIds) {
      final child = _childRepository.findByChildId(childId);

      if (child == null) {
        continue;
      }

      final recommendations = <Recommendation>[];

      recommendations.addAll(
        _universalTriggerRules.evaluate(child),
      );

      recommendations.addAll(
        _communicationRules.evaluate(child),
      );

      recommendations.addAll(
        _toiletsRules.evaluate(child),
      );

      recommendations.addAll(
        _transitionsRules.evaluate(child),
      );

      recommendations.addAll(
        _otherInformationRules.evaluate(child),
      );

      recommendations.addAll(
        _waterRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _walkingEffortRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _transportRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _overnightStayRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _environmentRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _clothingRules.evaluate(
          child,
          activitySession.activity,
        ),
      );

      recommendations.addAll(
        _safetyRules.evaluate(child),
      );

      recommendations.addAll(
        _emergencyMedicationRules.evaluate(child),
      );

      final deduplicatedRecommendations =
          _deduplicateRecommendations(
        recommendations,
      );

      childResults.add(
        ChildRecommendationResult(
          childId: childId,
          recommendations: List.unmodifiable(
            deduplicatedRecommendations,
          ),
        ),
      );
    }

    final globalRecommendations =
        _deduplicateRecommendations(
      _globalActivityRules.evaluate(
        activitySession.activity,
      ),
    );

    return ActivityRecommendationResult(
      childResults: List.unmodifiable(childResults),
      globalRecommendations: List.unmodifiable(
        globalRecommendations,
      ),
    );
  }

  List<Recommendation> _deduplicateRecommendations(
    List<Recommendation> recommendations,
  ) {
    final recommendationsById =
        <String, Recommendation>{};

    for (final recommendation in recommendations) {
      recommendationsById.putIfAbsent(
        recommendation.id,
        () => recommendation,
      );
    }

    return recommendationsById.values.toList();
  }
}