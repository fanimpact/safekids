/// Formats a birth date as an age in whole years, e.g. "8 ans".
///
/// Returns `null` if [dateOfBirth] is not set, so callers can decide
/// whether to hide the age line entirely rather than show an empty one.
String? formatAge(
  DateTime? dateOfBirth, {
  DateTime? now,
}) {
  if (dateOfBirth == null) {
    return null;
  }

  final today = now ?? DateTime.now();

  var age = today.year - dateOfBirth.year;

  final birthdayAlreadyPassedThisYear =
      today.month > dateOfBirth.month ||
          (today.month == dateOfBirth.month &&
              today.day >= dateOfBirth.day);

  if (!birthdayAlreadyPassedThisYear) {
    age--;
  }

  if (age < 0) {
    age = 0;
  }

  return age <= 1 ? '$age an' : '$age ans';
}
