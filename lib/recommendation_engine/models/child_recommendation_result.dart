import 'recommendation.dart';

class ChildRecommendationResult {
  final String childId;
  final List<Recommendation> recommendations;

  const ChildRecommendationResult({
    required this.childId,
    required this.recommendations,
  });
}