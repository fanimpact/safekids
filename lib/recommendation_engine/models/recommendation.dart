import 'recommendation_category.dart';

class Recommendation {
  final String id;
  final RecommendationCategory category;
  final String? childId;
  final String text;

  /// Vitale/sécuritaire : jamais masquable par le personnel, quelle
  /// que soit la personne connectée (voir plan espace professionnel,
  /// §11.5, classification validée par Fanny le 18/08/2026).
  final bool isCritical;

  const Recommendation({
    required this.id,
    required this.category,
    required this.text,
    this.childId,
    this.isCritical = false,
  });
}