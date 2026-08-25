/// Ce qu'il est advenu du parent, une fois la note enregistrée.
///
/// **Pourquoi ce type existe.** Jusqu'au 26/08/2026, `saveNote`
/// avalait l'exception de la notification ET ignorait le corps de la
/// réponse. L'écran affichait donc un succès identique que le parent
/// ait été prévenu ou non — et la fonction serveur, elle, répond
/// honnêtement `{ok: true, notifie: false}` quand il n'y a pas d'email
/// exploitable ou que l'envoi échoue. L'information existait ; le
/// client la jetait.
///
/// Ce fichier ne dépend d'aucun SDK : il se teste sans base.
enum SuiteNote {
  /// Note générale au groupe : personne n'est prévenu, et c'est voulu.
  /// Le parent ne la verra jamais — le RLS lui refuse les notes sans
  /// enfant rattaché.
  sansDestinataire,

  /// Le parent a reçu l'email.
  parentPrevenu,

  /// La note est enregistrée et lisible dans l'espace du parent, mais
  /// l'email n'est pas parti. Ce n'est pas un échec de l'enregistrement
  /// et il n'y a rien à refaire : c'est une information, pas une
  /// erreur.
  parentNonPrevenu,
}

/// Lit la réponse de `notifier-note-ajoutee`.
///
/// La fonction serveur renvoie `{ok: true, notifie: bool}` — voir
/// `supabase/functions/notifier-note-ajoutee/index.ts`. Tout le reste
/// (corps illisible, statut inattendu, exception réseau) se lit comme
/// « pas prévenu » : l'écran doit dire ce qu'il sait, et il ne sait
/// pas que le parent a été prévenu.
SuiteNote suiteDepuisReponse(
  Object? corps, {
  required int? statut,
}) {
  if (statut != null && statut >= 300) {
    return SuiteNote.parentNonPrevenu;
  }

  if (corps is! Map) {
    return SuiteNote.parentNonPrevenu;
  }

  return corps['notifie'] == true
      ? SuiteNote.parentPrevenu
      : SuiteNote.parentNonPrevenu;
}

/// Ce que le professionnel lit après avoir enregistré.
///
/// Les trois cas sont distincts à dessein : « note enregistrée » tout
/// court laissait croire qu'une note générale au groupe informait
/// quelqu'un, et qu'un email en échec était parti.
String messageSuiteNote(SuiteNote suite) {
  switch (suite) {
    case SuiteNote.sansDestinataire:
      return 'Note enregistrée. Elle reste dans l’établissement : '
          'aucun parent n’en est informé.';
    case SuiteNote.parentPrevenu:
      return 'Note enregistrée. Le parent a été prévenu par email.';
    case SuiteNote.parentNonPrevenu:
      return 'Note enregistrée. L’email n’a pas pu être envoyé au '
          'parent, mais la note est visible dans son espace.';
  }
}
