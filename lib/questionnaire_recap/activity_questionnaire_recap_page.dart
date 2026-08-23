import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/activity_profile_data.dart';
import '../models/complete_child_profile_data.dart';
import '../models/meals_data.dart';
import '../models/transport_data.dart';
import '../models/trigger_factor_data.dart';
import '../utils/pdf_theme.dart';
import '../utils/pdf_text.dart';

/// Récapitulatif intégral du questionnaire "Profil Activités" pour un
/// enfant : chaque question posée dans les 10 sections, avec la réponse
/// déjà donnée. Lecture seule — rien n'est modifiable ici.
class ActivityQuestionnaireRecapPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const ActivityQuestionnaireRecapPage({
    super.key,
    required this.child,
  });

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

  String _yesNo(bool? value) {
    if (value == null) {
      return 'Non renseigné';
    }

    return value ? 'Oui' : 'Non';
  }

  String _textOr(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty
        ? 'Non renseigné'
        : trimmed;
  }

  String _qa(String question, String answer) {
    return '$question — $answer';
  }

  String _qaBool(String question, bool? value) {
    return _qa(question, _yesNo(value));
  }

  String _qaText(String question, String? value) {
    return _qa(question, _textOr(value));
  }

  String _transportModeLabel(TransportMode mode) {
    return switch (mode) {
      TransportMode.car => 'Voiture',
      TransportMode.bus => 'Bus',
      TransportMode.train => 'Train',
      TransportMode.tram => 'Tramway',
      TransportMode.metro => 'Métro',
      TransportMode.plane => 'Avion',
      TransportMode.boatOrFerry => 'Bateau / Ferry',
      TransportMode.other => 'Autre',
    };
  }

  List<String> _aquaticActivityLines(
    ActivityProfileData profile,
  ) {
    final data = profile.aquaticActivity;

    final lines = <String>[
      'À proximité d’un point d’eau',
    ];

    final waterVigilance =
        child
            .essentialInformation
            .triggerFactors
            .waterVigilance;

    if (waterVigilance == WaterVigilance.mayJumpIntoWater) {
      lines.add(
        'D’après le profil santé, l’enfant risque de se jeter dans l’eau.',
      );
    }

    final cannotSwim =
        waterVigilance == WaterVigilance.cannotSwim;

    if (cannotSwim) {
      lines.add(
        'D’après le profil santé, l’enfant ne sait pas nager.',
      );

      lines.add(
        _qaBool(
          'Votre enfant doit-il disposer d’un gilet de flottaison lorsqu’il se trouve à proximité d’un point d’eau ?',
          data.requiresFlotationVestNearWater,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Votre enfant a-t-il besoin d’un adulte dédié à proximité d’un point d’eau pour assurer sa sécurité ?',
        data.requiresDedicatedAdultNearWater,
      ),
    );

    lines.add('Baignade');
    lines.add(
      _qaBool(
        'Votre enfant nécessite-t-il un équipement particulier ?',
        data.requiresSpecialEquipment,
      ),
    );

    if (data.requiresSpecialEquipment == true) {
      lines.add(
        _qaText(
          'Équipement nécessaire',
          data.specialEquipmentDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Une adaptation particulière de la surveillance est-elle nécessaire ?',
        data.requiresAdaptedSupervision,
      ),
    );

    if (data.requiresAdaptedSupervision == true) {
      lines.add(
        _qaBool('Prévenir le maître-nageur', data.notifyLifeguard),
      );
      lines.add(
        _qaBool(
          'Prévoir un adulte dédié',
          data.requiresDedicatedAdult,
        ),
      );
      lines.add(
        _qaText(
          'Autre adaptation de la surveillance',
          data.otherSupervisionDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Une autre adaptation importante est-elle nécessaire ?',
        data.requiresOtherAdaptation,
      ),
    );

    if (data.requiresOtherAdaptation == true) {
      lines.add(
        _qaText(
          'Précisez cette adaptation',
          data.otherAdaptationDetails,
        ),
      );
    }

    return lines;
  }

  List<String> _transportLines(
    ActivityProfileData profile,
  ) {
    final data = profile.transport;

    final lines = <String>[
      _qaBool(
        'Votre enfant a-t-il le mal des transports ?',
        data.motionSickness,
      ),
    ];

    if (data.motionSickness == true) {
      lines.add(
        _qa(
          'Moyen(s) de transport concerné(s)',
          data.motionSicknessTransports.isEmpty
              ? 'Non renseigné'
              : data.motionSicknessTransports
                  .map(_transportModeLabel)
                  .join(', '),
        ),
      );
      lines.add(
        _qaBool(
          'Votre enfant prend-il habituellement un médicament avant ce(s) transport(s) ?',
          data.takesMotionSicknessMedication,
        ),
      );

      if (data.takesMotionSicknessMedication == true) {
        if (data.motionSicknessMedicationNames.isEmpty) {
          lines.add(_qaText('Nom du médicament', null));
        } else {
          for (final entry
              in data.motionSicknessMedicationNames.entries) {
            lines.add(
              _qaText(
                'Nom du médicament – ${_transportModeLabel(entry.key)}',
                entry.value,
              ),
            );
          }
        }
      }
    }

    lines.add(
      _qaBool(
        'Votre enfant a-t-il besoin d’un équipement particulier pendant le transport ?',
        data.requiresSpecialEquipment,
      ),
    );

    if (data.requiresSpecialEquipment == true) {
      lines.add(
        _qaText(
          'Équipement nécessaire',
          data.specialEquipmentDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Votre enfant nécessite-t-il une attention particulière pendant le transport ?',
        data.requiresSpecialAttention,
      ),
    );

    if (data.requiresSpecialAttention == true) {
      lines.add(
        _qaText(
          'Précisez l’attention nécessaire',
          data.specialAttentionDetails,
        ),
      );
    }

    return lines;
  }

  List<String> _walkingEffortLines(
    ActivityProfileData profile,
  ) {
    final data = profile.walkingEffort;

    return [
      _qaBool(
        'La marche prolongée nécessite-t-elle une vigilance particulière pour votre enfant ?',
        data.prolongedWalkingRequiresVigilance,
      ),
      _qaBool(
        'Un effort physique intense nécessite-t-il une vigilance particulière pour votre enfant ?',
        data.intensePhysicalEffortRequiresVigilance,
      ),
    ];
  }

  List<String> _overnightStayLines(
    ActivityProfileData profile,
  ) {
    final data = profile.overnightStay;

    final lines = <String>[
      _qaBool(
        'Votre enfant utilise-t-il un appareillage pendant la nuit ?',
        data.usesNightDevice,
      ),
    ];

    if (data.usesNightDevice == true) {
      final deviceNames = child
          .essentialInformation
          .medicalDevices
          .where(
            (device) => data.nightDeviceIds
                .contains(device.deviceId),
          )
          .map((device) => device.deviceName?.trim())
          .where(
            (name) => name != null && name.isNotEmpty,
          )
          .cast<String>()
          .toList();

      lines.add(
        _qa(
          'Lequel (ou lesquels) ?',
          deviceNames.isEmpty
              ? 'Non renseigné'
              : deviceNames.join(' et '),
        ),
      );
      lines.add(
        _qaBool(
          'Cet appareillage nécessite-t-il une alimentation électrique ?',
          data.requiresElectricity,
        ),
      );

      if (data.requiresElectricity == true) {
        lines.add(
          _qaBool(
            'Une panne d’électricité peut-elle compromettre la sécurité ou la santé de votre enfant ?',
            data.powerFailureIsCritical,
          ),
        );
      }
    }

    lines.add(
      _qaBool(
        'Une adaptation particulière de la surveillance est-elle nécessaire pendant la nuit ?',
        data.requiresNightSupervision,
      ),
    );

    if (data.requiresNightSupervision == true) {
      lines.add(
        _qaText(
          'Précisez la surveillance nécessaire',
          data.nightSupervisionDetails,
        ),
      );
    }

    return lines;
  }

  List<String> _clothingLines(
    ActivityProfileData profile,
  ) {
    return [
      _qaBool(
        'Votre enfant nécessite-t-il qu’un adulte dédié l’aide lors d’un changement de tenue, par rapport à un enfant de son âge ?',
        profile.clothing.requiresAssistance,
      ),
    ];
  }

  List<String> _toiletsLines(
    ActivityProfileData profile,
  ) {
    return [
      _qaBool(
        'Votre enfant nécessite-t-il qu’un adulte dédié l’accompagne aux toilettes, par rapport à un enfant de son âge ?',
        profile.toilets.requiresAssistance,
      ),
    ];
  }

  List<String> _communicationLines(
    ActivityProfileData profile,
  ) {
    final data = profile.communication;

    final lines = <String>[
      _qaBool(
        'Votre enfant nécessite-t-il des adaptations particulières concernant la communication, par rapport à un enfant de son âge ?',
        data.requiresAdaptations,
      ),
    ];

    if (data.requiresAdaptations != true) {
      return lines;
    }

    lines.add(
      _qaBool(
        'Les consignes doivent être formulées avec des mots simples.',
        data.useSimpleInstructions,
      ),
    );
    lines.add(
      _qaBool(
        'Votre enfant peut donner l’impression d’avoir compris une consigne alors que ce n’est pas le cas.',
        data.mayAppearToUnderstand,
      ),
    );
    lines.add(
      _qaBool(
        'Il est préférable de vérifier individuellement que les consignes ont été comprises.',
        data.verifyUnderstandingIndividually,
      ),
    );
    lines.add(
      _qaBool(
        'Votre enfant utilise-t-il un support de communication particulier ?',
        data.usesCommunicationSupport,
      ),
    );

    if (data.usesCommunicationSupport == true) {
      lines.add(
        _qaText(
          'Précisez le support de communication utilisé',
          data.communicationSupportDetails,
        ),
      );
    }

    return lines;
  }

  List<String> _transitionsLines(
    ActivityProfileData profile,
  ) {
    final data = profile.transitions;

    final lines = <String>[
      _qaBool(
        'Votre enfant nécessite-t-il des adaptations particulières lors des transitions ou des changements d’activité, par rapport à un enfant de son âge ?',
        data.requiresAdaptations,
      ),
    ];

    if (data.requiresAdaptations != true) {
      return lines;
    }

    lines.add(
      _qaBool(
        'Les changements d’activité peuvent provoquer un stress important.',
        data.transitionsMayCauseStress,
      ),
    );
    lines.add(
      _qaBool(
        'Les changements de programme doivent être annoncés à l’avance.',
        data.changesMustBeAnnounced,
      ),
    );

    return lines;
  }

  List<String> _safetyLines(
    ActivityProfileData profile,
  ) {
    final data = profile.safety;

    final lines = <String>[
      _qaBool(
        'Votre enfant est-il susceptible de quitter brusquement le groupe ?',
        data.mayLeaveGroupSuddenly,
      ),
    ];
    lines.add(
      _qaBool(
        'Votre enfant nécessite-t-il un équipement de sécurité particulier ?',
        data.requiresSafetyEquipment,
      ),
    );

    if (data.requiresSafetyEquipment == true) {
      lines.add(
        _qaText(
          'Précisez l’équipement de sécurité nécessaire',
          data.safetyEquipmentDetails,
        ),
      );
    }

    return lines;
  }

  /// Section Repas. Les neuf questions sont posées à tous les parents
  /// (aucune question filtre), donc toutes figurent ici, y compris
  /// celles répondues "Non".
  List<String> _mealsLines(
    ActivityProfileData profile,
  ) {
    final data = profile.meals;

    final lines = <String>[
      _qaBool(
        'Votre enfant présente-t-il un risque de fausse route ou d’étouffement ?',
        data.hasChokingRisk,
      ),
    ];

    if (data.hasChokingRisk == true) {
      final preparations = <String>[];

      for (final preparation in MealPreparation.values) {
        if (!data.preparations.contains(preparation)) {
          continue;
        }

        preparations.add(_mealPreparationLabels[preparation]!);
      }

      lines.add(
        _qa(
          'Comment faut-il préparer ses repas et ses boissons ?',
          preparations.isEmpty
              ? 'Non renseigné'
              : preparations.join(', '),
        ),
      );

      if (data.preparations.contains(MealPreparation.other)) {
        lines.add(
          _qaText(
            'Précisez cette préparation',
            data.otherPreparationDetails,
          ),
        );
      }
    }

    lines.add(
      _qaBool(
        'Votre enfant doit-il être installé d’une façon particulière pour manger ?',
        data.requiresSpecificSeating,
      ),
    );

    if (data.requiresSpecificSeating == true) {
      lines.add(
        _qaText(
          'Précisez cette installation',
          data.seatingDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Y a-t-il des signes qui doivent alerter l’accompagnant pendant ou après le repas ?',
        data.hasWarningSigns,
      ),
    );

    if (data.hasWarningSigns == true) {
      lines.add(
        _qaText(
          'Lesquels, et que faire dans ce cas',
          data.warningSignsDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Votre enfant a-t-il besoin d’aide pendant la prise du repas ?',
        data.requiresAssistance,
      ),
    );

    if (data.requiresAssistance == true) {
      final level = data.assistanceLevel;

      lines.add(
        _qa(
          'De quelle aide s’agit-il ?',
          level == null
              ? 'Non renseigné'
              : _mealAssistanceLabels[level]!,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Votre enfant a-t-il besoin de matériel particulier pour manger dans de bonnes conditions ?',
        data.requiresSpecialEquipment,
      ),
    );

    if (data.requiresSpecialEquipment == true) {
      lines.add(
        _qaText(
          'Matériel nécessaire',
          data.specialEquipmentDetails,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Votre enfant a-t-il besoin d’une hydratation renforcée pour raison médicale ?',
        data.requiresIncreasedHydration,
      ),
    );

    lines.add(
      _qaBool(
        'Y a-t-il des aliments que votre enfant ne doit pas manger ?',
        data.hasDietaryRestrictions,
      ),
    );

    if (data.hasDietaryRestrictions == true) {
      final restrictions = <String>[];

      for (final restriction in MealDietaryRestriction.values) {
        if (!data.dietaryRestrictions.contains(restriction)) {
          continue;
        }

        restrictions.add(_mealRestrictionLabels[restriction]!);
      }

      lines.add(
        _qa(
          'Lesquels',
          restrictions.isEmpty
              ? 'Non renseigné'
              : restrictions.join(', '),
        ),
      );

      if (data.dietaryRestrictions.contains(
        MealDietaryRestriction.other,
      )) {
        lines.add(
          _qaText(
            'Précisez ce régime',
            data.otherDietaryRestrictionDetails,
          ),
        );
      }
    }

    lines.add(
      _qaBool(
        'Y a-t-il des aliments que votre enfant refuse ou ne tolère pas ?',
        data.hasFoodRefusals,
      ),
    );

    if (data.hasFoodRefusals == true) {
      lines.add(
        _qaText('Lesquels', data.foodRefusalDetails),
      );

      final stance = data.refusalStance;

      lines.add(
        _qa(
          'L’accompagnant doit-il insister ?',
          stance == null
              ? 'Non renseigné'
              : _mealRefusalStanceLabels[stance]!,
        ),
      );
    }

    lines.add(
      _qaBool(
        'Y a-t-il autre chose d’important à savoir sur les repas de votre enfant ?',
        data.hasOtherInformation,
      ),
    );

    if (data.hasOtherInformation == true) {
      lines.add(
        _qaText(
          'Précisez cette information',
          data.otherInformationDetails,
        ),
      );
    }

    return lines;
  }

  static const Map<MealPreparation, String> _mealPreparationLabels = {
    MealPreparation.smallPieces: 'Couper en petits morceaux',
    MealPreparation.minced: 'Alimentation hachée',
    MealPreparation.blended: 'Alimentation mixée',
    MealPreparation.thickenedDrinks: 'Boissons épaissies',
    MealPreparation.other: 'Autre',
  };

  static const Map<MealAssistanceLevel, String>
      _mealAssistanceLabels = {
    MealAssistanceLevel.adultNearby:
        'Il mange seul mais quelqu’un doit rester à côté de lui',
    MealAssistanceLevel.helpWithSomeGestures:
        'Il a besoin d’aide sur certains gestes (couper, ouvrir, '
            'porter à la bouche)',
    MealAssistanceLevel.fullyFedByAdult:
        'Il doit être nourri entièrement par un adulte',
  };

  static const Map<MealDietaryRestriction, String>
      _mealRestrictionLabels = {
    MealDietaryRestriction.glutenFree: 'Sans gluten',
    MealDietaryRestriction.lactoseFree: 'Sans lactose',
    MealDietaryRestriction.porkFree: 'Sans porc',
    MealDietaryRestriction.vegetarian: 'Végétarien',
    MealDietaryRestriction.other: 'Autre',
  };

  static const Map<MealRefusalStance, String>
      _mealRefusalStanceLabels = {
    MealRefusalStance.insist: 'Oui',
    MealRefusalStance.doNotInsist: 'Non',
  };

  List<String> _otherInformationLines(
    ActivityProfileData profile,
  ) {
    final data = profile.otherInformation;

    final lines = <String>[
      _qaBool(
        'Y a-t-il une autre information importante concernant l’accompagnement de votre enfant que nous n’avons pas abordée ?',
        data.hasOtherInformation,
      ),
    ];

    if (data.hasOtherInformation != true) {
      return lines;
    }

    for (final details in [
      data.details,
      data.secondDetails,
      data.thirdDetails,
      data.fourthDetails,
    ]) {
      final trimmed = details?.trim();

      if (trimmed != null && trimmed.isNotEmpty) {
        lines.add(_qa('Information complémentaire', trimmed));
      }
    }

    return lines;
  }

  List<_RecapSection> _sections(
    ActivityProfileData profile,
  ) {
    return [
      _RecapSection(
        title: 'Activité aquatique',
        icon: Icons.pool,
        lines: _aquaticActivityLines(profile),
      ),
      _RecapSection(
        title: 'Transport',
        icon: Icons.directions_bus,
        lines: _transportLines(profile),
      ),
      _RecapSection(
        title: 'Marche prolongée / effort physique',
        icon: Icons.directions_walk,
        lines: _walkingEffortLines(profile),
      ),
      _RecapSection(
        title: 'Séjour avec nuitée',
        icon: Icons.bed,
        lines: _overnightStayLines(profile),
      ),
      _RecapSection(
        title: 'Changement de tenue',
        icon: Icons.checkroom,
        lines: _clothingLines(profile),
      ),
      _RecapSection(
        title: 'Toilettes',
        icon: Icons.wc,
        lines: _toiletsLines(profile),
      ),
      _RecapSection(
        title: 'Communication',
        icon: Icons.chat_bubble_outline,
        lines: _communicationLines(profile),
      ),
      _RecapSection(
        title: 'Transitions / changements d’activité',
        icon: Icons.sync_alt,
        lines: _transitionsLines(profile),
      ),
      _RecapSection(
        title: 'Sécurité',
        icon: Icons.health_and_safety,
        lines: _safetyLines(profile),
      ),
      _RecapSection(
        title: 'Repas',
        icon: Icons.restaurant,
        lines: _mealsLines(profile),
      ),
      _RecapSection(
        title: 'Autres informations',
        icon: Icons.info_outline,
        lines: _otherInformationLines(profile),
      ),
    ];
  }

  Future<void> _print(
    ActivityProfileData profile,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdfBytes(profile),
      name: 'Profil activites - $_displayName',
    );
  }

  Future<void> _share(
    ActivityProfileData profile,
  ) async {
    await Printing.sharePdf(
      bytes: await _buildPdfBytes(profile),
      filename: 'profil_activites_$_displayName.pdf',
    );
  }

  Future<Uint8List> _buildPdfBytes(
    ActivityProfileData profile,
  ) async {
    final document = pw.Document();

    final theme = await pdfKidsRelayTheme();
    final policeTitres = await pdfTitleFont();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) => [
          pw.Text(
            pdfSafeText(
              'Profil Activités — $_displayName',
            ),
            style: pdfDocumentTitleStyle(policeTitres),
          ),
          for (final section in _sections(profile)) ...[
            pdfSectionTitle(section.title),
            ...section.lines.map(pdfBullet),
          ],
        ],
      ),
    );

    return document.save();
  }

  @override
  Widget build(BuildContext context) {
    final profile = child.activityProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Activités'),
        actions: profile == null
            ? null
            : [
                IconButton(
                  icon: const Icon(
                    Icons.print_outlined,
                  ),
                  tooltip: 'Imprimer / exporter en PDF',
                  onPressed: () => _print(profile),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Partager',
                  onPressed: () => _share(profile),
                ),
              ],
      ),
      body: SafeArea(
        child: profile == null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Le profil Activités n’a pas encore été rempli pour $_displayName.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  for (final section in _sections(profile))
                    Card(
                      margin: const EdgeInsets.only(
                        bottom: 16,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          18,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  section.icon,
                                  size: 22,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    section.title,
                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (final line
                                in section.lines)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  bottom: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets
                                              .only(
                                        top: 7,
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 9,
                                    ),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style:
                                            const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RecapSection {
  final String title;
  final IconData icon;
  final List<String> lines;

  _RecapSection({
    required this.title,
    required this.icon,
    required this.lines,
  });
}
