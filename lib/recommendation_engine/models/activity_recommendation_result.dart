import 'child_recommendation_result.dart';
import 'recommendation.dart';

class ActivityRecommendationResult {
  final List<ChildRecommendationResult> childResults;
  final List<Recommendation> globalRecommendations;

  const ActivityRecommendationResult({
    required this.childResults,
    required this.globalRecommendations,
  });
}