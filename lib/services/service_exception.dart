/// Échec d'une opération de service, avec un message déjà rédigé pour
/// la personne qui l'a déclenchée.
///
/// Remplace la remontée de `PostgrestException` jusque dans les écrans
/// (23/08/2026) : un écran n'a pas à connaître le type d'exception du
/// SDK de la base pour savoir quoi afficher.
///
/// N'y mettre que des messages lisibles. Une exception technique brute
/// ne doit jamais être enveloppée ici telle quelle : les écrans
/// affichent [message] sans le relire.
class ServiceException implements Exception {
  final String message;

  const ServiceException(this.message);

  @override
  String toString() => message;
}
