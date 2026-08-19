import '../models/medical_professional_data.dart';

/// Compose une ligne d'affichage pour un médecin référent (nom,
/// spécialité, lieu d'exercice, téléphone) — corrections de l'audit
/// passe 2 : ces champs étaient saisis mais jamais affichés au-delà
/// du nom. `null` si aucun nom n'est renseigné.
String? medicalProfessionalLine(
  MedicalProfessionalData? professional,
) {
  final name = professional?.name?.trim();

  if (name == null || name.isEmpty) {
    return null;
  }

  final details = <String>[];

  final specialty = professional?.specialty?.trim();

  if (specialty != null && specialty.isNotEmpty) {
    details.add(specialty);
  }

  final workplace = professional?.workplace?.trim();

  if (workplace != null && workplace.isNotEmpty) {
    details.add(workplace);
  }

  final phone = professional?.phoneNumber?.trim();

  if (phone != null && phone.isNotEmpty) {
    details.add('Tél. : $phone');
  }

  return details.isEmpty ? name : '$name — ${details.join(' — ')}';
}
