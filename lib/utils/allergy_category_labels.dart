import '../models/allergy_data.dart';

/// Libellés des types d'allergie et de leurs sous-questions, définis
/// une seule fois : le questionnaire de saisie, le récapitulatif et
/// les fiches doivent poser et restituer exactement la même question.
/// C'est le principe de source unique de formulation retenu le
/// 19/08/2026 pour les facteurs déclenchants, appliqué ici dès la
/// création de ces champs — plutôt que de laisser deux copies dériver.
const Map<AllergyCategory, String> allergyCategoryLabels = {
  AllergyCategory.food: 'Alimentaire',
  AllergyCategory.medication: 'Médicamenteuse',
  AllergyCategory.insectSting: "Piqûre d'insecte",
  AllergyCategory.contactOrEnvironment: 'Contact ou environnement',
  AllergyCategory.other: 'Autre',
};

const Map<AllergyCategory, String> allergyDetailLabels = {
  AllergyCategory.food: 'À quoi ?',
  AllergyCategory.medication: 'À quel médicament ?',
  AllergyCategory.insectSting: 'Quel insecte ?',
  AllergyCategory.contactOrEnvironment: 'À quoi ?',
  AllergyCategory.other: 'Préciser',
};

/// Types cochés d'une allergie, dans l'ordre de l'énumération, prêts à
/// être affichés ("Alimentaire, Médicamenteuse").
String allergyCategoriesLabel(AllergyData allergy) {
  return AllergyCategory.values
      .where(allergy.categories.contains)
      .map((category) => allergyCategoryLabels[category]!)
      .join(', ');
}
