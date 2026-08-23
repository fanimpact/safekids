import 'package:flutter/material.dart';

/// Identité visuelle de KidsRelay — source unique.
///
/// Aucune couleur ne doit être écrite en dur dans un écran : elles
/// viennent toutes d'ici, directement ou via le `Theme` de
/// l'application. Avant le 23/08/2026, une cinquantaine de couleurs
/// Material par défaut (bleu, indigo, violet, brun…) étaient dispersées
/// dans 14 fichiers.
class KidsRelayColors {
  KidsRelayColors._();

  /// Couleur principale : titres, boutons pleins, barres.
  static const Color vertPin = Color(0xFF1F4A3F);

  /// Teinte douce du vert principal : fonds de section, bordures,
  /// états sélectionnés.
  static const Color sauge = Color(0xFFB8D0C4);

  /// Accent chaud : ce sur quoi l'œil doit se poser sans que ce soit
  /// une alerte — points importants, mises en avant.
  static const Color ambre = Color(0xFFE2A03F);

  /// Fond général de l'application.
  static const Color lin = Color(0xFFF5F3EF);

  /// Texte et éléments sombres.
  static const Color ardoise = Color(0xFF26302C);

  /// **Réservé au Mode Urgence et aux consignes vitales.**
  ///
  /// Ne jamais l'utiliser pour une action destructrice ordinaire
  /// (supprimer un profil), une erreur de saisie, ou une simple mise en
  /// garde : sa valeur tient à sa rareté. Un accompagnant doit pouvoir
  /// se dire « du rouge = urgence vitale » sans réfléchir.
  ///
  /// Pour une action destructrice, utiliser [ardoise] : le poids vient
  /// du libellé et de la confirmation, pas de la couleur.
  static const Color urgence = Color(0xFFC0392B);

  /// Déclinaisons du rouge d'urgence, pour les fonds et bordures des
  /// encarts. Mêmes règles d'usage que [urgence].
  static const Color urgenceFond = Color(0xFFFBEDEB);
  static const Color urgenceBordure = Color(0xFFE0A49D);

  /// Texte secondaire : légendes, aides à la saisie, précisions.
  static const Color ardoiseDouce = Color(0xFF5F6B66);

  /// Bordures neutres et séparateurs.
  static const Color bordure = Color(0xFFD9D5CE);

  /// Fond des cartes et blocs posés sur [lin].
  static const Color surface = Color(0xFFFFFFFF);
}

/// Familles de caractères, telles que déclarées dans `pubspec.yaml`.
class KidsRelayFonts {
  KidsRelayFonts._();

  /// Titres uniquement.
  static const String titres = 'PlusJakartaSans';

  /// Texte courant, y compris les libellés de boutons et de champs.
  static const String texte = 'Mulish';
}

/// Thème appliqué à toute l'application.
///
/// Volontairement sans thème sombre : en ajouter un demanderait de
/// revoir chaque écran, et ce n'est pas ce chantier.
ThemeData kidsRelayTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: KidsRelayColors.vertPin,
    onPrimary: Colors.white,
    primaryContainer: KidsRelayColors.sauge,
    onPrimaryContainer: KidsRelayColors.vertPin,
    secondary: KidsRelayColors.ambre,
    onSecondary: KidsRelayColors.ardoise,
    secondaryContainer: Color(0xFFF7E6C7),
    onSecondaryContainer: KidsRelayColors.ardoise,
    // `error` est le rouge d'urgence : c'est la seule voie par laquelle
    // Material peut l'introduire, et elle ne sert qu'aux messages
    // d'erreur des champs de saisie.
    error: KidsRelayColors.urgence,
    onError: Colors.white,
    errorContainer: KidsRelayColors.urgenceFond,
    onErrorContainer: KidsRelayColors.urgence,
    surface: KidsRelayColors.surface,
    onSurface: KidsRelayColors.ardoise,
    surfaceContainerHighest: KidsRelayColors.lin,
    onSurfaceVariant: KidsRelayColors.ardoiseDouce,
    outline: KidsRelayColors.bordure,
    outlineVariant: KidsRelayColors.sauge,
  );

  TextStyle titre(double taille, FontWeight graisse) => TextStyle(
        fontFamily: KidsRelayFonts.titres,
        fontSize: taille,
        fontWeight: graisse,
        color: KidsRelayColors.vertPin,
        height: 1.25,
      );

  TextStyle corps(
    double taille, {
    FontWeight graisse = FontWeight.w400,
    Color couleur = KidsRelayColors.ardoise,
  }) =>
      TextStyle(
        fontFamily: KidsRelayFonts.texte,
        fontSize: taille,
        fontWeight: graisse,
        color: couleur,
        height: 1.45,
      );

  final textTheme = TextTheme(
    displayLarge: titre(34, FontWeight.w700),
    displayMedium: titre(30, FontWeight.w700),
    displaySmall: titre(26, FontWeight.w700),
    headlineLarge: titre(26, FontWeight.w700),
    headlineMedium: titre(22, FontWeight.w700),
    headlineSmall: titre(20, FontWeight.w600),
    titleLarge: titre(20, FontWeight.w600),
    titleMedium: titre(17, FontWeight.w600),
    titleSmall: titre(15, FontWeight.w600),
    bodyLarge: corps(17),
    bodyMedium: corps(15),
    bodySmall: corps(13, couleur: KidsRelayColors.ardoiseDouce),
    labelLarge: corps(16, graisse: FontWeight.w600),
    labelMedium: corps(14, graisse: FontWeight.w600),
    labelSmall: corps(12, couleur: KidsRelayColors.ardoiseDouce),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KidsRelayColors.lin,
    textTheme: textTheme,
    fontFamily: KidsRelayFonts.texte,

    appBarTheme: AppBarTheme(
      backgroundColor: KidsRelayColors.vertPin,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: KidsRelayFonts.titres,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KidsRelayColors.vertPin,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: TextStyle(
          fontFamily: KidsRelayFonts.texte,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KidsRelayColors.vertPin,
        side: const BorderSide(color: KidsRelayColors.vertPin),
        minimumSize: const Size.fromHeight(52),
        textStyle: TextStyle(
          fontFamily: KidsRelayFonts.texte,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KidsRelayColors.vertPin,
        textStyle: TextStyle(
          fontFamily: KidsRelayFonts.texte,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KidsRelayColors.surface,
      labelStyle: corps(15, couleur: KidsRelayColors.ardoiseDouce),
      helperStyle: corps(13, couleur: KidsRelayColors.ardoiseDouce),
      helperMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KidsRelayColors.bordure),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KidsRelayColors.bordure),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: KidsRelayColors.vertPin,
          width: 2,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: KidsRelayColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KidsRelayColors.bordure),
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KidsRelayColors.vertPin
            : null,
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KidsRelayColors.vertPin
            : KidsRelayColors.ardoiseDouce,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KidsRelayColors.vertPin
            : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KidsRelayColors.sauge
            : null,
      ),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: KidsRelayColors.sauge,
        selectedForegroundColor: KidsRelayColors.vertPin,
        foregroundColor: KidsRelayColors.ardoiseDouce,
        side: const BorderSide(color: KidsRelayColors.bordure),
        textStyle: TextStyle(
          fontFamily: KidsRelayFonts.texte,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: KidsRelayColors.ardoise,
      contentTextStyle: corps(15, couleur: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: KidsRelayColors.bordure,
      space: 1,
      thickness: 1,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: KidsRelayColors.vertPin,
      textColor: KidsRelayColors.ardoise,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: KidsRelayColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      titleTextStyle: titre(20, FontWeight.w600),
      contentTextStyle: corps(15),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KidsRelayColors.vertPin,
    ),

    iconTheme: const IconThemeData(
      color: KidsRelayColors.vertPin,
    ),
  );
}
