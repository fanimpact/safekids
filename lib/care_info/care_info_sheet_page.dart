import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/complete_child_profile_data.dart';
import '../models/trigger_factor_data.dart';
import '../utils/age_utils.dart';
import '../utils/pdf_text.dart';

/// Fiche de lecture seule, générée uniquement à partir du profil déjà
/// rempli de l'enfant, pensée pour un accompagnant qui garde l'enfant
/// plusieurs jours (ex. grands-parents). Contrairement à la fiche de
/// recommandations d'activité, elle affiche tout ce qui est renseigné
/// dans le profil, sans lien à une activité précise. Elle ne contient
/// aucune consigne "que faire en cas d'urgence" (réservée au Mode
/// Urgence). Ce qui est affiché à l'écran et ce qui est exporté
/// (PDF / partage) sont strictement identiques : rien n'est
/// modifiable ici, cette page n'a pas d'état.
class CareInfoSheetPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const CareInfoSheetPage({
    super.key,
    required this.child,
  });

  String get _firstName {
    final value =
        child.essentialInformation.identity.firstName;

    if (value == null || value.trim().isEmpty) {
      return 'Enfant';
    }

    return value.trim();
  }

  String get _pageTitle {
    return "Ce qu'il faut savoir sur $_firstName";
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

    return details;
  }

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

      lines.add(
        date != null && date.isNotEmpty
            ? '$name (diagnostiquée : $date)'
            : name,
      );
    }

    return lines;
  }

  List<String> get _allergyLines {
    final lines = <String>[];

    for (final allergy
        in child.essentialInformation.allergies) {
      final allergen = allergy.allergen?.trim();

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

      lines.add(
        details.isEmpty
            ? name
            : '$name — ${details.join(' — ')}',
      );
    }

    return lines;
  }

  List<String> get _emergencyTreatmentLines {
    final lines = <String>[];

    for (final treatment in child
        .essentialInformation.emergencyTreatments) {
      final name = treatment.medicationName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final dosage = treatment.dosage?.trim();

      lines.add(
        dosage != null && dosage.isNotEmpty
            ? '$name — $dosage'
            : name,
      );
    }

    return lines;
  }

  List<String> get _medicalDeviceLines {
    final lines = <String>[];

    for (final device
        in child.essentialInformation.medicalDevices) {
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

  List<String> get _triggerFactorLines {
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    if (!triggerFactors.hasTriggerFactors) {
      return [];
    }

    final lines = <String>[];

    if (triggerFactors.flashingLights == true) {
      lines.add(
        triggerFactors.requiresGlassesOutdoors
            ? 'Photosensibilité (lumières clignotantes) — port de lunettes nécessaire en extérieur'
            : 'Photosensibilité (lumières clignotantes)',
      );
    }

    if (triggerFactors.heat == true) {
      lines.add('Chaleur');
    }

    if (triggerFactors.fatigueOrLackOfSleep == true) {
      lines.add('Fatigue / manque de sommeil');
    }

    if (triggerFactors.noise == true) {
      lines.add('Bruit');
    }

    if (triggerFactors.crowd == true) {
      lines.add('Foule');
    }

    if (triggerFactors.confinedSpaces == true) {
      lines.add('Espaces confinés');
    }

    if (triggerFactors.physicalEffort == true) {
      lines.add('Effort physique');
    }

    if (triggerFactors.stressOrStrongEmotions ==
        true) {
      lines.add('Stress / émotions fortes');
    }

    if (triggerFactors.waterContact) {
      final vigilance = switch (
          triggerFactors.waterVigilance) {
        WaterVigilance.mayJumpIntoWater =>
          'risque de se jeter dans l’eau',
        WaterVigilance.cannotSwim => 'ne sait pas nager',
        WaterVigilance.other =>
          _nonEmptyOrNull(
            triggerFactors.otherWaterVigilance,
          ),
        null => null,
      };

      lines.add(
        vigilance != null ? 'Eau — $vigilance' : 'Eau',
      );
    }

    if (triggerFactors.animals) {
      final vigilance = switch (
          triggerFactors.animalVigilance) {
        AnimalVigilance.importantFear =>
          'peur importante des animaux',
        AnimalVigilance
            .approachesWithoutPerceivingDanger =>
          'tendance à s’approcher des animaux sans percevoir le danger',
        AnimalVigilance.other =>
          _nonEmptyOrNull(
            triggerFactors.otherAnimalVigilance,
          ),
        null => null,
      };

      lines.add(
        vigilance != null
            ? 'Animaux — $vigilance'
            : 'Animaux',
      );
    }

    if (triggerFactors.height) {
      final vigilance = switch (
          triggerFactors.heightVigilance) {
        HeightVigilance.doesNotPerceiveDanger =>
          'absence de perception du danger',
        HeightVigilance.vertigoOrImportantFear =>
          'vertige ou peur importante',
        HeightVigilance.other =>
          _nonEmptyOrNull(
            triggerFactors.otherHeightVigilance,
          ),
        null => null,
      };

      lines.add(
        vigilance != null
            ? 'Hauteur — $vigilance'
            : 'Hauteur',
      );
    }

    final other = triggerFactors.other?.trim();

    if (other != null && other.isNotEmpty) {
      lines.add('Autre : $other');
    }

    return lines;
  }

  String? _nonEmptyOrNull(String? value) {
    final trimmed = value?.trim();

    return trimmed != null && trimmed.isNotEmpty
        ? trimmed
        : null;
  }

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

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            pdfSafeText(_pageTitle),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          if (_identityDetails.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                pdfSafeText(
                  _identityDetails.join(' — '),
                ),
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),

          pdfSectionTitle('Pathologies'),
          ..._pdfLines(
            _pathologyLines,
            'Aucune pathologie connue.',
          ),

          pdfSectionTitle('Allergies'),
          ..._pdfLines(
            _allergyLines,
            'Aucune allergie connue.',
          ),

          pdfSectionTitle('Traitements réguliers'),
          ..._pdfLines(
            _dailyTreatmentLines,
            'Aucun traitement régulier en cours.',
          ),

          pdfSectionTitle('Traitements d’urgence'),
          ..._pdfLines(
            _emergencyTreatmentLines,
            'Aucun traitement d’urgence prescrit.',
          ),

          pdfSectionTitle('Dispositifs médicaux'),
          ..._pdfLines(
            _medicalDeviceLines,
            'Aucun dispositif médical.',
          ),

          if (_triggerFactorLines.isNotEmpty) ...[
            pdfSectionTitle(
              'Facteurs déclenchants et sensibilités',
            ),
            ..._triggerFactorLines.map(pdfBullet),
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
            Row(
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
            ),
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
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 7,
                        ),
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
                ),
              ),
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

            _sectionCard(
              title: 'Pathologies',
              icon: Icons.medical_information_outlined,
              lines: _pathologyLines,
              emptyMessage: 'Aucune pathologie connue.',
            ),

            _sectionCard(
              title: 'Allergies',
              icon: Icons.warning_amber_rounded,
              lines: _allergyLines,
              emptyMessage: 'Aucune allergie connue.',
            ),

            _sectionCard(
              title: 'Traitements réguliers',
              icon: Icons.medication_outlined,
              lines: _dailyTreatmentLines,
              emptyMessage:
                  'Aucun traitement régulier en cours.',
            ),

            _sectionCard(
              title: 'Traitements d’urgence',
              icon: Icons.medical_services_outlined,
              lines: _emergencyTreatmentLines,
              emptyMessage:
                  'Aucun traitement d’urgence prescrit.',
            ),

            _sectionCard(
              title: 'Dispositifs médicaux',
              icon: Icons.settings_accessibility,
              lines: _medicalDeviceLines,
              emptyMessage: 'Aucun dispositif médical.',
            ),

            if (_triggerFactorLines.isNotEmpty)
              _sectionCard(
                title:
                    'Facteurs déclenchants et sensibilités',
                icon: Icons.visibility_outlined,
                lines: _triggerFactorLines,
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
