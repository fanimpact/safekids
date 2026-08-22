/// Type d'une allergie, coché par le parent à la saisie. Une même
/// allergie peut relever de plusieurs types (un enfant allergique aux
/// fruits à coque peut l'être à l'ingestion comme au contact), d'où un
/// ensemble et non une valeur unique.
///
/// L'ordre de déclaration est l'ordre d'affichage : questionnaire,
/// récapitulatif et fiches le suivent, pour que la même allergie se
/// lise toujours pareil d'un écran à l'autre.
enum AllergyCategory {
  food,
  medication,
  insectSting,
  contactOrEnvironment,
  other,
}

class AllergyData {
  static int _nextId = 0;

  final String allergyId;

  /// Types cochés par le parent. Vide uniquement sur une allergie
  /// enregistrée avant le 22/08/2026 — la saisie l'exige désormais.
  final Set<AllergyCategory> categories;

  /// Précision saisie pour chaque type coché ("À quoi ?", "À quel
  /// médicament ?"…). C'est ce qui remplace l'ancien champ unique
  /// `allergen` : la précision est portée par la sous-question du
  /// type, pour ne pas faire saisir deux fois la même information.
  final Map<AllergyCategory, String> details;

  /// Ancien champ `allergen`, relu depuis les enregistrements
  /// antérieurs au 22/08/2026 et jamais saisissable. Sert uniquement
  /// de repli d'affichage tant que le parent n'a pas ressaisi
  /// l'allergie avec ses types.
  final String? legacyAllergen;

  String? observedReaction;

  /// Étapes à suivre en cas d'urgence liée à cette allergie,
  /// dans l'ordre, saisies par le parent. Affichées numérotées
  /// automatiquement dans le Mode Urgence.
  final List<String> emergencyInstructionSteps;

  AllergyData({
    String? allergyId,
    Set<AllergyCategory>? categories,
    Map<AllergyCategory, String>? details,
    this.legacyAllergen,
    this.observedReaction,
    List<String>? emergencyInstructionSteps,
  })  : allergyId = allergyId ?? _createAllergyId(),
        categories = categories ?? <AllergyCategory>{},
        details = details ?? <AllergyCategory, String>{},
        emergencyInstructionSteps =
            emergencyInstructionSteps ?? [];

  static String _createAllergyId() {
    _nextId++;
    return 'allergy_$_nextId';
  }

  /// Ce qui s'affiche partout où l'allergène était affiché avant :
  /// les précisions des types cochés, dans l'ordre de l'énumération.
  /// Retombe sur l'ancien champ pour une allergie non encore
  /// retypée, et vaut `null` quand il n'y a rien à montrer — les
  /// appelants filtrent déjà ce cas.
  String? get label {
    final parts = <String>[];

    for (final category in AllergyCategory.values) {
      if (!categories.contains(category)) {
        continue;
      }

      final detail = details[category]?.trim();

      if (detail != null && detail.isNotEmpty) {
        parts.add(detail);
      }
    }

    if (parts.isNotEmpty) {
      return parts.join(' / ');
    }

    final legacy = legacyAllergen?.trim();

    return legacy == null || legacy.isEmpty ? null : legacy;
  }

  bool get isFood => categories.contains(AllergyCategory.food);

  /// Vrai quand cette allergie doit remonter au moment du repas.
  /// Une allergie sans type — donc antérieure à la catégorisation —
  /// est incluse volontairement : le repli demandé est de continuer à
  /// l'afficher partout, plutôt que de la faire disparaître d'une
  /// fiche parce qu'on ignore son type.
  bool get concernsMeals => categories.isEmpty || isFood;

  Map<String, dynamic> toJson() => {
        'allergyId': allergyId,
        'categories':
            categories.map((category) => category.name).toList(),
        'details': details.map(
          (category, detail) => MapEntry(category.name, detail),
        ),
        'allergen': legacyAllergen,
        'observedReaction': observedReaction,
        'emergencyInstructionSteps': emergencyInstructionSteps,
      };

  factory AllergyData.fromJson(
    Map<String, dynamic> json,
  ) {
    final categories = <AllergyCategory>{};

    for (final raw in (json['categories'] as List<dynamic>?) ?? []) {
      final category = _categoryFromName(raw as String?);

      if (category != null) {
        categories.add(category);
      }
    }

    final details = <AllergyCategory, String>{};
    final rawDetails = json['details'];

    if (rawDetails is Map) {
      for (final entry in rawDetails.entries) {
        final category = _categoryFromName(entry.key as String?);
        final detail = entry.value;

        if (category != null && detail is String) {
          details[category] = detail;
        }
      }
    }

    return AllergyData(
      allergyId: json['allergyId'] as String?,
      categories: categories,
      details: details,
      legacyAllergen: json['allergen'] as String?,
      observedReaction: json['observedReaction'] as String?,
      emergencyInstructionSteps:
          (json['emergencyInstructionSteps'] as List<dynamic>?)
              ?.map((step) => step as String)
              .toList(),
    );
  }
}

AllergyCategory? _categoryFromName(String? name) {
  if (name == null) {
    return null;
  }

  for (final category in AllergyCategory.values) {
    if (category.name == name) {
      return category;
    }
  }

  return null;
}
