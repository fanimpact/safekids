import '../models/emergency_treatment_data.dart';

/// À quelle étape (index, 0-based) d'un protocole d'urgence [steps] ce
/// traitement est administré — corrections de l'inventaire du
/// 19/08/2026 (Mode Urgence). Priorité au choix explicite du parent
/// (`administrationStepByPathologyId`/`administrationStepByAllergyId`,
/// renseigné sur la page des traitements) ; à défaut, un repli
/// automatique cherche le nom du médicament dans le texte des étapes
/// (insensible à la casse) — utile pour les profils déjà remplis avant
/// que ce lien explicite existe, jamais un substitut fiable à long
/// terme puisque le parent n'écrit pas forcément le nom mot pour mot.
int? resolveAdministrationStepIndex({
  required EmergencyTreatmentData treatment,
  required String pathologyOrAllergyId,
  required bool isPathology,
  required List<String> steps,
}) {
  final explicit = isPathology
      ? treatment.administrationStepByPathologyId[
          pathologyOrAllergyId]
      : treatment.administrationStepByAllergyId[
          pathologyOrAllergyId];

  if (explicit != null &&
      explicit >= 0 &&
      explicit < steps.length) {
    return explicit;
  }

  final name = treatment.medicationName?.trim();

  if (name == null || name.isEmpty) {
    return null;
  }

  final lowerName = name.toLowerCase();

  for (var index = 0; index < steps.length; index++) {
    if (steps[index].toLowerCase().contains(lowerName)) {
      return index;
    }
  }

  return null;
}

/// Ligne d'affichage d'un traitement d'urgence en Mode Urgence : nom,
/// dosage, condition, mode d'administration — tout ce dont
/// l'accompagnant a besoin pour l'administrer, au même endroit.
String emergencyTreatmentDetailLine(
  EmergencyTreatmentData treatment,
) {
  final name = treatment.medicationName?.trim() ?? '';

  final details = <String>[];

  final dosage = treatment.dosage?.trim();

  if (dosage != null && dosage.isNotEmpty) {
    details.add(dosage);
  }

  final condition = treatment.administrationCondition?.trim();

  if (condition != null && condition.isNotEmpty) {
    details.add(condition);
  }

  final method = treatment.administrationMethod?.trim();

  if (method != null && method.isNotEmpty) {
    details.add(method);
  }

  return details.isEmpty
      ? name
      : '$name — ${details.join(' — ')}';
}
