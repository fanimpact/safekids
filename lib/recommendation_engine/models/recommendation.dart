import 'recommendation_category.dart';

class Recommendation {
  final String id;
  final RecommendationCategory category;
  final String? childId;
  final String text;

  const Recommendation({
    required this.id,
    required this.category,
    required this.text,
    this.childId,
  });
}