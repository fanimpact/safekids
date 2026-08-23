import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/complete_child_profile_data.dart';
import '../models/meals_data.dart';
import '../models/medical_device_data.dart';
import '../models/transport_data.dart';
import '../recommendation_engine/rules/environment_rules.dart';
import '../recommendation_engine/rules/universal_trigger_rules.dart';
import '../utils/age_utils.dart';
import '../utils/date_format_utils.dart';
import '../utils/medical_professional_line.dart';
import '../utils/pdf_theme.dart';
import '../utils/pdf_text.dart';
import '../utils/treatment_audience.dart';

/// Un groupe de lignes avec son propre sous-titre, affiché à l'intérieur
/// d'une même section (ex. "Traitements d'urgence" / "Traitements
/// réguliers" dans la section "Médicaments").
typedef _LineGroup = ({String heading, List<String> lines});

/// Fiche de lecture seule, générée uniquement à partir du profil déjà
/// rempli de l'enfant, pensée pour un accompagnant qui garde l'enfant
/// plusieurs jours (ex. grands-parents). Contrairement à la fiche de
/// recommandations d'activité, elle affiche tout ce qui est renseigné
/// dans le profil (santé ET activités), sans lien à une activité
/// précise. Elle ne contient aucune consigne "que faire en cas
/// d'urgence" (réservée au Mode Urgence). Trois sections, sur le
/// modèle de la fiche de recommandations d'activité : les points de
/// vigilance et de sécurité, les médicaments, puis le matériel à
/// prévoir. Ce qui est affiché à l'écran et ce qui est exporté
/// (PDF / partage) sont strictement identiques : rien n'est
/// modifiable ici, cette page n'a pas d'état.
class CareInfoSheetPage extends StatelessWidget {
  final CompleteChildProfileData child;

  /// Détermine la mention accolée à chaque traitement (PAI, indications
  /// du parent, ou aucune) — voir `TreatmentAudience`.
  final TreatmentAudience audience;

  const CareInfoSheetPage({
    super.key,
    required this.child,
    this.audience = TreatmentAudience.owner,
  });

  String get _firstName {
    final value =
        child.essentialInformation.identity.firstName;

    if (value == null || value.trim().isEmpty) {
      return 'l’enfant';
    }

    return value.trim();
  }

  String get _pageTitle {
    return "Ce qu'il faut savoir sur $_displayName";
  }

  String get _displayName {
    final identity =
        child.essentialInformation.identity;

    final parts = [
      identity.firstName,
      identity.lastName,
    ].where(
      (value) =>
          value != null && value.trim().isNotEmpty,
    ).map(
      (value) => value!.trim(),
    );

    final name = parts.join(' ');

    return name.isEmpty ? 'Enfant' : name;
  }

  String? get _ageLine {
    return formatAge(
      child.essentialInformation.identity.dateOfBirth,
    );
  }

  String _formatMeasurement(
    double value,
    String unit,
  ) {
    final formatted = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toString();

    return '$formatted $unit';
  }

  List<String> get _identityDetails {
    final identity =
        child.essentialInformation.identity;

    final details = <String>[];

    final age = _ageLine;

    if (age != null) {
      details.add(age);
    }

    if (identity.weightKg != null) {
      details.add(
        _formatMeasurement(
          identity.weightKg!,
          'kg',
        ),
      );
    }

    if (identity.heightCm != null) {
      details.add(
        _formatMeasurement(
          identity.heightCm!,
          'cm',
        ),
      );
    }

    if (identity.weightKg != null ||
        identity.heightCm != null) {
      details.add(
        identity.measurementsUpdatedAt == null
            ? 'date de mesure non renseignée'
            : 'mesurés le ${formatShortDate(
                identity.measurementsUpdatedAt!,
              )}',
      );
    }

    return details;
  }

  // ---------------------------------------------------------------------
  // Contenu brut par catégorie, réutilisé pour composer les 3 sections
  // ci-dessous ainsi que les Contacts.
  // ---------------------------------------------------------------------

  List<String> get _pathologyLines {
    final lines = <String>[];

    for (final pathology
        in child.essentialInformation.pathologies) {
      final name = pathology.name?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final date =
          pathology.approximateDiagnosisDate?.trim();

      var line = date != null && date.isNotEmpty
          ? '$name (diagnostiquée : $date)'
          : name;

      final professionalLine = pathology
              .hasReferringProfessional ==
              true
          ? medicalProfessionalLine(
              pathology.referringProfessional,
            )
          : null;

      if (professionalLine != null) {
        line = '$line — suivi par $professionalLine';
      }

      lines.add(line);
    }

    return lines;
  }

  /// Antécédents médicaux marquants (événements médicaux passés) —
  /// distincts des pathologies diagnostiquées ci-dessus. Corrigé
  /// (audit passe 2) : absents de cette fiche jusqu'ici, alors que
  /// déjà affichés sur la fiche secours.
  List<String> get _medicalHistoryLines {
    final lines = <String>[];

    for (final event
        in child.essentialInformation.medicalEvents) {
      final description = event.description?.trim();

      if (description == null || description.isEmpty) {
        continue;
      }

      final details = <String>[];

      final date = event.approximateDate?.trim();

      if (date != null && date.isNotEmpty) {
        details.add(date);
      }

      if (event.emergencyServicesCalled == true) {
        details.add('secours intervenus');
      }

      if (event.emergencyTreatmentGiven == true) {
        details.add('traitement d’urgence donné');
      } else if (event.emergencyTreatmentGiven == false) {
        details.add('traitement d’urgence non donné');
      }

      if (event.hospitalized == true) {
        final hospitalName = event.hospitalName?.trim();
        final duration =
            event.hospitalizationDuration?.trim();

        final hasHospitalName =
            hospitalName != null && hospitalName.isNotEmpty;
        final hasDuration =
            duration != null && duration.isNotEmpty;

        if (hasHospitalName && hasDuration) {
          details.add(
            'hospitalisation à $hospitalName : $duration',
          );
        } else if (hasHospitalName) {
          details.add('hospitalisation à $hospitalName');
        } else if (hasDuration) {
          details.add('hospitalisation : $duration');
        } else {
          details.add('hospitalisation');
        }
      }

      if (event.importantExaminationsPerformed == true) {
        final exams = event.importantExaminations?.trim();

        if (exams != null && exams.isNotEmpty) {
          details.add('examens : $exams');
        }
      }

      lines.add(
        details.isEmpty
            ? description
            : '$description — ${details.join(' — ')}',
      );
    }

    return lines;
  }

  /// Nom, spécialité, lieu d'exercice et téléphone du médecin
  /// traitant — corrigé (audit passe 2) : absent de cette fiche
  /// jusqu'ici, alors que déjà affiché sur la fiche secours.
  List<String> get _primaryCareDoctorLines {
    final doctor = child.essentialInformation.primaryCareDoctor;

    final lines = <String>[];

    final name = doctor.name?.trim();

    if (name != null && name.isNotEmpty) {
      lines.add(name);
    }

    final workplace = doctor.workplace?.trim();

    if (workplace != null && workplace.isNotEmpty) {
      lines.add(workplace);
    }

    final phone = doctor.phoneNumber?.trim();

    if (phone != null && phone.isNotEmpty) {
      lines.add('Tél. : $phone');
    }

    return lines;
  }

  /// Allergies hors repas. Les allergies alimentaires sont affichées
  /// avec la section Repas plus bas (22/08/2026) — au moment où elles
  /// servent, plutôt qu'en vrac avec les pathologies. Une allergie
  /// enregistrée sans type part aussi côté repas, par prudence : voir
  /// `AllergyData.concernsMeals`.
  List<String> get _allergyLines {
    final lines = <String>[];

    for (final allergy
        in child.essentialInformation.allergies) {
      if (allergy.concernsMeals) {
        continue;
      }

      final allergen = allergy.label?.trim();

      if (allergen == null || allergen.isEmpty) {
        continue;
      }

      final reaction =
          allergy.observedReaction?.trim();

      lines.add(
        reaction != null && reaction.isNotEmpty
            ? '$allergen — réaction : $reaction'
            : allergen,
      );
    }

    return lines;
  }

  List<String> get _dailyTreatmentLines {
    final lines = <String>[];

    for (final treatment
        in child.essentialInformation.dailyTreatments) {
      final name = treatment.medicationName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final details = <String>[];

      final dosage = treatment.dosage?.trim();

      if (dosage != null && dosage.isNotEmpty) {
        details.add(dosage);
      }

      final times =
          treatment.administrationTimes?.trim();

      if (times != null && times.isNotEmpty) {
        details.add(times);
      }

      final mention = treatmentMentionSuffix(audience);

      if (mention != null) {
        details.add(mention);
      }

      lines.add(
        details.isEmpty
            ? name
            : '$name — ${details.join(' — ')}',
      );
    }

    return lines;
  }

  /// Ne renvoie une ligne que si elle apporte une information en plus
  /// du simple nom du traitement (dosage...) : le nom seul est déjà
  /// couvert par la consigne "à garder à portée de main en permanence"
  /// dans `_medicationGroups`, pas besoin de le répéter à l'identique.
  List<String> get _emergencyTreatmentLines {
    final lines = <String>[];

    for (final treatment in child
        .essentialInformation.emergencyTreatments) {
      final name = treatment.medicationName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final details = <String>[];

      final dosage = treatment.dosage?.trim();

      if (dosage != null && dosage.isNotEmpty) {
        details.add(dosage);
      }

      final condition =
          treatment.administrationCondition?.trim();

      if (condition != null && condition.isNotEmpty) {
        details.add(condition);
      }

      final method = treatment.administrationMethod?.trim();

      if (method != null && method.isNotEmpty) {
        details.add(method);
      }

      final mention = treatmentMentionSuffix(audience);

      if (mention != null) {
        details.add(mention);
      }

      if (details.isEmpty) {
        continue;
      }

      lines.add('$name — ${details.join(' — ')}');
    }

    return lines;
  }

  List<String> _medicalDeviceLines(
    bool Function(MedicalDeviceData device) matches,
  ) {
    final lines = <String>[];

    for (final device
        in child.essentialInformation.medicalDevices) {
      if (!matches(device)) {
        continue;
      }

      final name = device.deviceName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final use = device.mainUse?.trim();

      lines.add(
        use != null && use.isNotEmpty
            ? '$name — $use'
            : name,
      );
    }

    return lines;
  }

  /// Dispositifs à emporter/préparer pour chaque sortie. Un dispositif
  /// non renseigné (question pas encore répondue) est inclus par
  /// défaut, pour ne jamais faire disparaître silencieusement une
  /// information qui pourrait être nécessaire.
  List<String> get _equipmentToBringLines {
    return _medicalDeviceLines(
      (device) =>
          device.isWornOrImplantedPermanently != true,
    );
  }

  /// Dispositifs portés ou implantés en permanence sur l'enfant : à
  /// titre informatif uniquement, ils n'ont rien à préparer pour une
  /// sortie.
  List<String> get _permanentlyWornDeviceLines {
    return _medicalDeviceLines(
      (device) =>
          device.isWornOrImplantedPermanently == true,
    );
  }

  /// Noms (sans le détail de dosage) de tous les traitements d'urgence
  /// de l'enfant, toutes sources confondues — utilisé pour la consigne
  /// "à garder à portée de main en permanence".
  List<String> get _emergencyMedicationNames {
    final names = <String>[];

    for (final treatment
        in child.essentialInformation.emergencyTreatments) {
      final name = treatment.medicationName?.trim();

      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }

    return names;
  }

  List<String> _walkingEffortVigilanceLines() {
    final walkingEffort =
        child.activityProfile?.walkingEffort;

    if (walkingEffort == null) {
      return [];
    }

    final lines = <String>[];

    if (walkingEffort
            .prolongedWalkingRequiresVigilance ==
        true) {
      lines.add(
        'Marche prolongée : vigilance particulière',
      );
    }

    if (walkingEffort
            .intensePhysicalEffortRequiresVigilance ==
        true) {
      lines.add(
        'Effort physique intense : vigilance particulière',
      );
    }

    return lines;
  }

  List<String> get _dailyLifeLines {
    final activityProfile = child.activityProfile;

    if (activityProfile == null) {
      return [];
    }

    final lines = <String>[];

    if (activityProfile.clothing.requiresAssistance ==
        true) {
      lines.add(
        'Habillage : besoin d’aide pour changer de tenue',
      );
    }

    if (activityProfile.toilets.requiresAssistance ==
        true) {
      lines.add(
        'Toilettes : besoin d’accompagnement',
      );
    }

    final communication = activityProfile.communication;

    if (communication.useSimpleInstructions) {
      lines.add(
        'Communication : utiliser des consignes simples',
      );
    }

    if (communication.mayAppearToUnderstand ||
        communication.verifyUnderstandingIndividually) {
      lines.add(
        'Communication : vérifier sa compréhension individuellement',
      );
    }

    if (communication.usesCommunicationSupport == true) {
      final details = communication
          .communicationSupportDetails
          ?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Communication : $details');
      }
    }

    final transitions = activityProfile.transitions;

    if (transitions.transitionsMayCauseStress) {
      lines.add(
        'Transitions : les changements d’activité peuvent provoquer un stress important',
      );
    }

    if (transitions.changesMustBeAnnounced) {
      lines.add(
        'Transitions : les changements de programme doivent être annoncés à l’avance',
      );
    }

    final aquaticActivity =
        activityProfile.aquaticActivity;

    if (aquaticActivity.requiresFlotationVestNearWater ==
        true) {
      lines.add(
        'Baignade : gilet de flottaison nécessaire à proximité d’un point d’eau',
      );
    }

    if (aquaticActivity.requiresDedicatedAdultNearWater ==
        true) {
      lines.add(
        'Baignade : adulte dédié nécessaire à proximité d’un point d’eau',
      );
    }

    if (aquaticActivity.requiresSpecialEquipment == true) {
      final details = aquaticActivity
          .specialEquipmentDetails
          ?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Baignade : équipement nécessaire — $details');
      }
    }

    if (aquaticActivity.requiresAdaptedSupervision ==
        true) {
      final otherSupervisionDetails = aquaticActivity
          .otherSupervisionDetails
          ?.trim();

      final supervisionDetails = <String>[
        if (aquaticActivity.notifyLifeguard)
          'prévenir le maître-nageur',
        if (aquaticActivity.requiresDedicatedAdult)
          'adulte dédié',
        if (otherSupervisionDetails != null &&
            otherSupervisionDetails.isNotEmpty)
          otherSupervisionDetails,
      ];

      if (supervisionDetails.isNotEmpty) {
        lines.add(
          'Baignade : surveillance adaptée — ${_joinWithAnd(supervisionDetails)}',
        );
      }
    }

    if (aquaticActivity.requiresOtherAdaptation == true) {
      final details = aquaticActivity
          .otherAdaptationDetails
          ?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Baignade : $details');
      }
    }

    final transport = activityProfile.transport;

    if (transport.motionSickness == true &&
        transport.motionSicknessTransports.isNotEmpty) {
      final modes = transport.motionSicknessTransports
          .map(_transportModeLabel)
          .toList();

      lines.add(
        'Transport : mal des transports en ${_joinWithAnd(modes)}',
      );
    }

    if (transport.motionSickness == true &&
        transport.takesMotionSicknessMedication == true) {
      final names = transport
          .motionSicknessMedicationNames.values
          .where((name) => name.trim().isNotEmpty)
          .toList();

      lines.add(
        names.isEmpty
            ? 'Transport : traitement contre le mal des transports nécessaire'
            : 'Transport : traitement contre le mal des transports — ${_joinWithAnd(names)}',
      );
    }

    if (transport.requiresSpecialEquipment == true) {
      final details =
          transport.specialEquipmentDetails?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Transport : équipement nécessaire — $details');
      }
    }

    if (transport.requiresSpecialAttention == true) {
      final details =
          transport.specialAttentionDetails?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Transport : attention particulière — $details');
      }
    }

    final otherInformation =
        activityProfile.otherInformation;

    if (otherInformation.hasOtherInformation == true) {
      for (final details in [
        otherInformation.details,
        otherInformation.secondDetails,
        otherInformation.thirdDetails,
        otherInformation.fourthDetails,
      ]) {
        final trimmed = details?.trim();

        if (trimmed != null && trimmed.isNotEmpty) {
          lines.add('Information complémentaire : $trimmed');
        }
      }
    }

    return lines;
  }

  /// Section Repas (profil Activités), affichée en entier sur cette
  /// fiche : contrairement à la fiche de recommandations d'activité,
  /// elle ne dépend d'aucune activité précise et montre tout ce qui
  /// est renseigné.
  ///
  /// Les allergies alimentaires y sont reprises depuis le profil
  /// santé, jamais ressaisies dans le questionnaire Repas.
  List<String> get _mealsLines {
    final lines = <String>[];

    for (final allergy
        in child.essentialInformation.allergies) {
      if (!allergy.concernsMeals) {
        continue;
      }

      final allergen = allergy.label?.trim();

      if (allergen == null || allergen.isEmpty) {
        continue;
      }

      final reaction = allergy.observedReaction?.trim();

      lines.add(
        reaction != null && reaction.isNotEmpty
            ? 'Repas — allergie alimentaire : $allergen — '
                'réaction : $reaction'
            : 'Repas — allergie alimentaire : $allergen',
      );
    }

    final meals = child.activityProfile?.meals;

    if (meals == null) {
      return lines;
    }

    if (meals.hasChokingRisk == true) {
      final preparations = <String>[];

      for (final preparation in MealPreparation.values) {
        if (!meals.preparations.contains(preparation)) {
          continue;
        }

        if (preparation == MealPreparation.other) {
          final details = meals.otherPreparationDetails?.trim();

          if (details != null && details.isNotEmpty) {
            preparations.add(details);
          }

          continue;
        }

        preparations.add(_mealPreparationLabels[preparation]!);
      }

      lines.add(
        preparations.isEmpty
            ? 'Repas : risque de fausse route ou d’étouffement'
            : 'Repas : risque de fausse route ou d’étouffement — '
                'préparation : ${preparations.join(', ')}',
      );
    }

    if (meals.requiresSpecificSeating == true) {
      final details = meals.seatingDetails?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Repas : installation particulière — $details');
      }
    }

    if (meals.hasWarningSigns == true) {
      final details = meals.warningSignsDetails?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Repas : signes à surveiller — $details');
      }
    }

    if (meals.requiresAssistance == true) {
      final level = meals.assistanceLevel;

      if (level != null) {
        lines.add(
          'Repas : ${_mealAssistanceLabels[level]!}',
        );
      }
    }

    if (meals.requiresSpecialEquipment == true) {
      final details = meals.specialEquipmentDetails?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Repas : matériel nécessaire — $details');
      }
    }

    if (meals.requiresIncreasedHydration == true) {
      lines.add(
        'Repas : hydratation renforcée nécessaire pour raison '
        'médicale',
      );
    }

    if (meals.hasDietaryRestrictions == true) {
      final restrictions = <String>[];

      for (final restriction in MealDietaryRestriction.values) {
        if (!meals.dietaryRestrictions.contains(restriction)) {
          continue;
        }

        if (restriction == MealDietaryRestriction.other) {
          final details =
              meals.otherDietaryRestrictionDetails?.trim();

          if (details != null && details.isNotEmpty) {
            restrictions.add(details);
          }

          continue;
        }

        restrictions.add(_mealRestrictionLabels[restriction]!);
      }

      if (restrictions.isNotEmpty) {
        lines.add(
          'Repas : aliments à ne pas donner — '
          '${restrictions.join(', ')}',
        );
      }
    }

    if (meals.hasFoodRefusals == true) {
      final details = meals.foodRefusalDetails?.trim();

      if (details != null && details.isNotEmpty) {
        final stance = meals.refusalStance;

        lines.add(
          stance == null
              ? 'Repas : aliments refusés ou mal tolérés — $details'
              : 'Repas : aliments refusés ou mal tolérés — $details '
                  '(${_mealRefusalStanceLabels[stance]!})',
        );
      }
    }

    if (meals.hasOtherInformation == true) {
      final details = meals.otherInformationDetails?.trim();

      if (details != null && details.isNotEmpty) {
        // Intitulé explicite : sans lui, la ligne se lisait
        // "Repas : <texte>", sans dire de quelle question elle
        // répondait — la seule du bloc dans ce cas.
        lines.add('Repas — autre information : $details');
      }
    }

    return lines;
  }

  /// Matériel de repas, repris dans le récapitulatif "Matériel à
  /// prévoir" en bas de fiche : c'est là que l'accompagnant lit sa
  /// liste de préparation d'un coup d'œil, et un verre à bec ou des
  /// couverts adaptés s'y emportent au même titre qu'un dispositif
  /// médical.
  ///
  /// Volontairement redondant avec la ligne "Repas : matériel
  /// nécessaire" de la section du dessus, comme l'équipement l'est
  /// déjà sur la fiche de recommandations d'activité (bloc de
  /// situation + récapitulatif) : les deux endroits répondent à deux
  /// moments de lecture différents.
  List<String> get _mealEquipmentLines {
    final meals = child.activityProfile?.meals;

    if (meals == null || meals.requiresSpecialEquipment != true) {
      return [];
    }

    final details = meals.specialEquipmentDetails?.trim();

    if (details == null || details.isEmpty) {
      return [];
    }

    return ['Repas : $details'];
  }

  static const Map<MealPreparation, String> _mealPreparationLabels = {
    MealPreparation.smallPieces: 'couper en petits morceaux',
    MealPreparation.minced: 'alimentation hachée',
    MealPreparation.blended: 'alimentation mixée',
    MealPreparation.thickenedDrinks: 'boissons épaissies',
  };

  static const Map<MealAssistanceLevel, String>
      _mealAssistanceLabels = {
    MealAssistanceLevel.adultNearby:
        'mange seul, mais un adulte doit rester à côté de lui',
    MealAssistanceLevel.helpWithSomeGestures:
        'aide nécessaire sur certains gestes (couper, ouvrir, '
            'porter à la bouche)',
    MealAssistanceLevel.fullyFedByAdult:
        'doit être nourri entièrement par un adulte',
  };

  static const Map<MealDietaryRestriction, String>
      _mealRestrictionLabels = {
    MealDietaryRestriction.glutenFree: 'sans gluten',
    MealDietaryRestriction.lactoseFree: 'sans lactose',
    MealDietaryRestriction.porkFree: 'sans porc',
    MealDietaryRestriction.vegetarian: 'végétarien',
  };

  static const Map<MealRefusalStance, String>
      _mealRefusalStanceLabels = {
    MealRefusalStance.insist: 'insister',
    MealRefusalStance.doNotInsist: 'ne pas insister',
  };

  String _transportModeLabel(TransportMode mode) {
    return switch (mode) {
      TransportMode.car => 'voiture',
      TransportMode.bus => 'bus',
      TransportMode.train => 'train',
      TransportMode.tram => 'tramway',
      TransportMode.metro => 'métro',
      TransportMode.plane => 'avion',
      TransportMode.boatOrFerry => 'bateau / ferry',
      TransportMode.other => 'autre moyen de transport',
    };
  }

  String _joinWithAnd(List<String> values) {
    if (values.length <= 1) {
      return values.join();
    }

    return '${values.sublist(0, values.length - 1).join(', ')} et ${values.last}';
  }

  // ---------------------------------------------------------------------
  // Section 1 — "S'occuper de [prénom]".
  // Tous les points de vigilance et de sécurité, du plus important au
  // moins important : la ou les pathologies en tête, puis les risques
  // vitaux (eau, hauteur), les allergies, puis le reste des facteurs de
  // vigilance (santé et profil Activités), et enfin les informations
  // pratiques du quotidien (habillage, toilettes, communication,
  // transport). Ne contient ni médicaments ni matériel : ils ont leurs
  // propres sections ci-dessous, pour éviter toute redondance.
  // ---------------------------------------------------------------------

  /// Ordre de priorité fixe, valable pour tous les enfants (pas
  /// déterminé par l'ordre de saisie dans le questionnaire) :
  /// 1. En tête : pathologies, dispositifs portés en permanence,
  ///    allergies.
  /// 2. Facteurs pouvant directement déclencher un événement médical
  ///    grave : eau, hauteur, photosensibilité, animaux.
  /// 3. Vigilances générales : chaleur, fatigue, stress, effort
  ///    physique, bruit, foule, espaces confinés, autre.
  /// 4. Informations pratiques, tout ce qui vient du profil Activités :
  ///    marche prolongée / effort physique intense, sécurité, puis
  ///    habillage / toilettes / communication / transport.
  List<String> get _careVigilanceLines {
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    final lines = <String>[
      ..._pathologyLines.map(
        (line) => 'Pathologie : $line',
      ),
      ..._medicalHistoryLines.map(
        (line) => 'Antécédent : $line',
      ),
      ..._permanentlyWornDeviceLines.map(
        (line) => 'Dispositif porté en permanence : $line',
      ),
      ..._allergyLines.map(
        (line) => 'Allergie : $line',
      ),
    ];

    // Danger médical direct + vigilances générales — corrigé
    // (19/08/2026) : ce texte vient désormais exclusivement des
    // méthodes publiques de EnvironmentRules/UniversalTriggerRules,
    // les mêmes que celles utilisées par la fiche secours et par la
    // préparation d'activité — plus jamais réécrit ici.
    const environmentRules = EnvironmentRules();
    const universalTriggerRules = UniversalTriggerRules();
    final childId = child.childId;

    lines.addAll(
      environmentRules
          .waterTriggerRecommendations(childId, triggerFactors)
          .map((r) => r.text),
    );
    lines.addAll(
      environmentRules
          .heightRecommendations(childId, triggerFactors)
          .map((r) => r.text),
    );
    lines.addAll(
      universalTriggerRules
          .photosensitivityRecommendations(
        childId,
        triggerFactors,
      )
          .map((r) => r.text),
    );
    lines.addAll(
      environmentRules
          .animalRecommendations(childId, triggerFactors)
          .map((r) => r.text),
    );

    for (final recommendation in [
      universalTriggerRules.heatRecommendation(
        childId,
        triggerFactors,
      ),
      universalTriggerRules.fatigueRecommendation(
        childId,
        triggerFactors,
      ),
      universalTriggerRules.stressRecommendation(
        childId,
        triggerFactors,
      ),
      environmentRules.physicalEffortRecommendation(
        childId,
        triggerFactors,
      ),
      environmentRules.noiseRecommendation(
        childId,
        triggerFactors,
      ),
      environmentRules.crowdRecommendation(
        childId,
        triggerFactors,
      ),
      environmentRules.confinedSpaceRecommendation(
        childId,
        triggerFactors,
      ),
      universalTriggerRules.otherTriggerFactorRecommendation(
        childId,
        triggerFactors,
      ),
    ]) {
      if (recommendation != null) {
        lines.add(recommendation.text);
      }
    }

    // Informations pratiques (tout ce qui vient du profil Activités).

    lines.addAll(_walkingEffortVigilanceLines());

    final safety = child.activityProfile?.safety;

    if (safety != null) {
      if (safety.mayLeaveGroupSuddenly == true) {
        lines.add(
          'Sécurité : l’enfant peut quitter le groupe soudainement',
        );
      }

      if (safety.requiresSafetyEquipment == true) {
        final details =
            safety.safetyEquipmentDetails?.trim();

        if (details != null && details.isNotEmpty) {
          lines.add('Équipement de sécurité : $details');
        }
      }
    }

    lines.addAll(_overnightStayLines);

    lines.addAll(_dailyLifeLines);

    lines.addAll(_mealsLines);

    return lines;
  }

  /// Nuitée (profil Activités) : appareillage utilisé la nuit (résolu
  /// depuis le dispositif médical déjà déclaré, jamais ressaisi ici),
  /// besoin d'alimentation électrique de secours, surveillance
  /// nocturne.
  List<String> get _overnightStayLines {
    final overnightStay =
        child.activityProfile?.overnightStay;

    if (overnightStay == null) {
      return [];
    }

    final lines = <String>[];

    if (overnightStay.usesNightDevice == true &&
        overnightStay.nightDeviceIds.isNotEmpty) {
      final deviceNames = child
          .essentialInformation
          .medicalDevices
          .where(
            (device) => overnightStay.nightDeviceIds
                .contains(device.deviceId),
          )
          .map((device) => device.deviceName?.trim())
          .where(
            (name) => name != null && name.isNotEmpty,
          )
          .cast<String>()
          .toList();

      if (deviceNames.isNotEmpty) {
        lines.add(
          'Nuitée : utilise ${_joinWithAnd(deviceNames)} pendant la nuit',
        );
      }
    }

    if (overnightStay.requiresElectricity == true &&
        overnightStay.powerFailureIsCritical == true) {
      lines.add(
        'Nuitée : alimentation électrique de secours nécessaire en cas de coupure',
      );
    }

    if (overnightStay.requiresNightSupervision == true) {
      final details = overnightStay
          .nightSupervisionDetails
          ?.trim();

      if (details != null && details.isNotEmpty) {
        lines.add('Nuitée : surveillance nécessaire — $details');
      }
    }

    return lines;
  }

  // ---------------------------------------------------------------------
  // Section 2 — "Médicaments".
  // Deux sous-parties bien séparées : traitements d'urgence, puis
  // traitements réguliers. Rien d'autre n'y figure.
  // ---------------------------------------------------------------------

  List<_LineGroup> get _medicationGroups {
    final emergencyLines = <String>[
      if (_emergencyMedicationNames.isNotEmpty)
        'Traitement d’urgence à garder à portée de main en permanence : ${_joinWithAnd(_emergencyMedicationNames)}',
      ..._emergencyTreatmentLines,
    ];

    return [
      (
        heading: 'Traitements d’urgence',
        lines: emergencyLines,
      ),
      (
        heading: 'Traitements réguliers',
        lines: _dailyTreatmentLines,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Section 3 — "Matériel à prévoir".
  // Tout ce qui est à emporter/préparer pour chaque sortie : les
  // dispositifs médicaux, et le matériel de repas (corrigé le
  // 22/08/2026 — cette section ne listait que les dispositifs, alors
  // qu'un verre à bec ou des couverts adaptés s'oublient tout autant).
  // Les dispositifs portés/implantés en permanence sont mentionnés dans
  // la section 1 à la place, une seule fois au total.
  // ---------------------------------------------------------------------

  List<String> get _equipmentLines => [
        ..._equipmentToBringLines,
        ..._mealEquipmentLines,
      ];

  List<String> get _contactLines {
    final contacts = [
      ...child.essentialInformation.contacts,
    ]..sort(
      (a, b) => (b.isPrimaryContact ? 1 : 0)
          .compareTo(a.isPrimaryContact ? 1 : 0),
    );

    final lines = <String>[];

    for (final contact in contacts) {
      final name = contact.fullName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final details = <String>[];

      final relationship = contact.relationship?.trim();

      if (relationship != null &&
          relationship.isNotEmpty) {
        details.add(relationship);
      }

      final phone = contact.phoneNumber?.trim();

      if (phone != null && phone.isNotEmpty) {
        details.add(phone);
      }

      lines.add(
        details.isEmpty
            ? name
            : '$name — ${details.join(' — ')}',
      );
    }

    return lines;
  }

  Future<void> _print() async {
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdfBytes(),
      name: _pageTitle,
    );
  }

  Future<void> _share() async {
    await Printing.sharePdf(
      bytes: await _buildPdfBytes(),
      filename:
          'informations_accompagnement_$_displayName.pdf',
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    final document = pw.Document();

    final theme = await pdfKidsRelayTheme();
    final policeTitres = await pdfTitleFont();

    final medicationGroups = _medicationGroups
        .where((group) => group.lines.isNotEmpty)
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) => [
          pw.Text(
            pdfSafeText(_pageTitle),
            style: pdfDocumentTitleStyle(policeTitres),
          ),

          if (_identityDetails.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                pdfSafeText(
                  _identityDetails.join(' — '),
                ),
                style: pdfSubtitleStyle,
              ),
            ),

          if (_careVigilanceLines.isNotEmpty) ...[
            pdfSectionTitle("S'occuper de $_firstName"),
            ..._careVigilanceLines.map(pdfBullet),
          ],

          if (medicationGroups.isNotEmpty) ...[
            pdfSectionTitle('Médicaments'),
            for (final group in medicationGroups) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                  top: 4,
                  bottom: 2,
                ),
                child: pw.Text(
                  pdfSafeText(group.heading),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              ...group.lines.map(pdfBullet),
            ],
          ],

          if (_equipmentLines.isNotEmpty) ...[
            pdfSectionTitle('Matériel à prévoir'),
            ..._equipmentLines.map(pdfBullet),
          ],

          if (_primaryCareDoctorLines.isNotEmpty) ...[
            pdfSectionTitle('Médecin traitant'),
            ..._primaryCareDoctorLines.map(pdfBullet),
          ],

          pdfSectionTitle('Contacts à prévenir'),
          ..._pdfLines(
            _contactLines,
            'Aucun contact renseigné.',
          ),
        ],
      ),
    );

    return document.save();
  }

  List<pw.Widget> _pdfLines(
    List<String> lines,
    String emptyMessage,
  ) {
    if (lines.isEmpty) {
      return [pdfBullet(emptyMessage)];
    }

    return lines.map(pdfBullet).toList();
  }

  Widget _sectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulletLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(
              Icons.circle,
              size: 6,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<String> lines,
    required String emptyMessage,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionHeader(title: title, icon: icon),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...lines.map(_bulletLine),
          ],
        ),
      ),
    );
  }

  Widget _groupedSectionCard({
    required String title,
    required IconData icon,
    required List<_LineGroup> groups,
  }) {
    final nonEmptyGroups = groups
        .where((group) => group.lines.isNotEmpty)
        .toList();

    if (nonEmptyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionHeader(title: title, icon: icon),
            const SizedBox(height: 12),
            for (final group in nonEmptyGroups) ...[
              Text(
                group.heading,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...group.lines.map(_bulletLine),
              if (group != nonEmptyGroups.last)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  child: Divider(height: 20),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimer / exporter en PDF',
            onPressed: _print,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
            onPressed: _share,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (_identityDetails.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _identityDetails.join(' · '),
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_careVigilanceLines.isNotEmpty)
              _sectionCard(
                title: "S'occuper de $_firstName",
                icon: Icons.health_and_safety_outlined,
                lines: _careVigilanceLines,
                emptyMessage: '',
              ),

            _groupedSectionCard(
              title: 'Médicaments',
              icon: Icons.medication_outlined,
              groups: _medicationGroups,
            ),

            if (_equipmentLines.isNotEmpty)
              _sectionCard(
                title: 'Matériel à prévoir',
                icon: Icons.backpack_outlined,
                lines: _equipmentLines,
                emptyMessage: '',
              ),

            if (_primaryCareDoctorLines.isNotEmpty)
              _sectionCard(
                title: 'Médecin traitant',
                icon: Icons.local_hospital_outlined,
                lines: _primaryCareDoctorLines,
                emptyMessage: '',
              ),

            _sectionCard(
              title: 'Contacts à prévenir',
              icon: Icons.contact_phone_outlined,
              lines: _contactLines,
              emptyMessage: 'Aucun contact renseigné.',
            ),
          ],
        ),
      ),
    );
  }
}
