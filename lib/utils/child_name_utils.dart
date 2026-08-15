import '../models/identity_data.dart';

/// Nom complet (prénom + nom de famille) d'un enfant, pour les endroits
/// où plusieurs enfants doivent pouvoir être distingués (listes,
/// sélecteurs, titres de page). Retombe sur [fallback] si rien n'est
/// renseigné.
String childFullName(
  IdentityData identity, {
  String fallback = 'Enfant',
}) {
  final parts = [
    identity.firstName,
    identity.lastName,
  ].where(
    (value) => value != null && value.trim().isNotEmpty,
  ).map((value) => value!.trim());

  final name = parts.join(' ');

  return name.isEmpty ? fallback : name;
}
