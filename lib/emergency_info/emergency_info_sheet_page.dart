import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/complete_child_profile_data.dart';
import '../utils/age_utils.dart';
import '../utils/pdf_text.dart';

/// Fiche de lecture seule, générée uniquement à partir du profil déjà
/// rempli de l'enfant. Ce qui est affiché à l'écran et ce qui est
/// exporté (PDF / partage) sont strictement identiques : rien n'est
/// modifiable ici, cette page n'a pas d'état.
class EmergencyInfoSheetPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const EmergencyInfoSheetPage({
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

  List<String> get _medicalHistoryLines {
    final lines = <String>[];

    for (final event
        in child.essentialInformation.medicalEvents) {
      final description = event.description?.trim();

      if (description == null ||
          description.isEmpty) {
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

      if (event.hospitalized == true) {
        final duration =
            event.hospitalizationDuration?.trim();

        details.add(
          duration != null && duration.isNotEmpty
              ? 'hospitalisation : $duration'
              : 'hospitalisation',
        );
      }

      if (event.importantExaminationsPerformed ==
          true) {
        final exams =
            event.importantExaminations?.trim();

        if (exams != null && exams.isNotEmpty) {
          details.add('examens : $exams');
        }
      }

      lines.add(
        details.isEmpty
            ? description
            : '$description — ${details.join(' — ')}',
      );

      if (event.hasOngoingConsequences == true) {
        final consequences =
            event.ongoingConsequences?.trim();

        if (consequences != null &&
            consequences.isNotEmpty) {
          lines.add(
            'Conséquences toujours présentes : $consequences',
          );
        }
      }
    }

    return lines;
  }

  List<String> get _observationLines {
    final lines = <String>[];

    for (final observation in child
        .essentialInformation.medicalObservations) {
      final description = observation.description?.trim();

      if (description == null ||
          description.isEmpty) {
        continue;
      }

      final details = <String>[];

      final date = observation.approximateDate?.trim();

      if (date != null && date.isNotEmpty) {
        details.add(date);
      }

      final conclusion = observation.conclusion?.trim();

      if (conclusion != null && conclusion.isNotEmpty) {
        details.add(conclusion);
      }

      lines.add(
        details.isEmpty
            ? description
            : '$description — ${details.join(' — ')}',
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

  List<String> get _discontinuedTreatmentLines {
    final lines = <String>[];

    for (final treatment in child
        .essentialInformation.discontinuedTreatments) {
      final name = treatment.medicationName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final stopDate =
          treatment.approximateStopDate?.trim();

      lines.add(
        stopDate != null && stopDate.isNotEmpty
            ? '$name — arrêté : $stopDate'
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

  List<String> get _primaryCareDoctorLines {
    final doctor =
        child.essentialInformation.primaryCareDoctor;

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
      name:
          'Informations essentielles - $_displayName',
    );
  }

  Future<void> _share() async {
    await Printing.sharePdf(
      bytes: await _buildPdfBytes(),
      filename:
          'informations_essentielles_$_displayName.pdf',
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            pdfSafeText(
              'Informations essentielles — $_displayName',
            ),
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

          pdfSectionTitle(
            'Pathologies et antécédents médicaux',
          ),
          ..._pdfLines([
            ..._pathologyLines,
            ..._medicalHistoryLines,
          ], 'Aucune pathologie ni antécédent connu.'),

          if (_observationLines.isNotEmpty) ...[
            pdfSectionTitle(
              'Observations médicales',
            ),
            ..._observationLines.map(pdfBullet),
          ],

          pdfSectionTitle(
            'Allergies et réactions connues',
          ),
          ..._pdfLines(
            _allergyLines,
            'Aucune allergie connue.',
          ),

          pdfSectionTitle(
            'Traitement d’urgence prescrit',
          ),
          ..._pdfLines(
            _emergencyTreatmentLines,
            'Aucun traitement d’urgence prescrit.',
          ),

          pdfSectionTitle(
            'Traitement quotidien en cours',
          ),
          ..._pdfLines(
            _dailyTreatmentLines,
            'Aucun traitement quotidien en cours.',
          ),

          pdfSectionTitle(
            'Traitements arrêtés',
          ),
          ..._pdfLines(
            _discontinuedTreatmentLines,
            'Aucun traitement arrêté connu.',
          ),

          pdfSectionTitle(
            'Dispositifs médicaux utilisés',
          ),
          ..._pdfLines(
            _medicalDeviceLines,
            'Aucun dispositif médical.',
          ),

          pdfSectionTitle(
            'Médecin traitant / référent',
          ),
          ..._pdfLines(
            _primaryCareDoctorLines,
            'Non renseigné.',
          ),

          pdfSectionTitle(
            'Contacts à prévenir',
          ),
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
        title: const Text(
          'Informations pour les secours',
        ),
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
              title:
                  'Pathologies et antécédents médicaux',
              icon: Icons.medical_information_outlined,
              lines: [
                ..._pathologyLines,
                ..._medicalHistoryLines,
              ],
              emptyMessage:
                  'Aucune pathologie ni antécédent connu.',
            ),

            if (_observationLines.isNotEmpty)
              _sectionCard(
                title: 'Observations médicales',
                icon: Icons.fact_check_outlined,
                lines: _observationLines,
                emptyMessage:
                    'Aucune observation médicale.',
              ),

            _sectionCard(
              title: 'Allergies et réactions connues',
              icon: Icons.warning_amber_rounded,
              lines: _allergyLines,
              emptyMessage: 'Aucune allergie connue.',
            ),

            _sectionCard(
              title: 'Traitement d’urgence prescrit',
              icon: Icons.medical_services_outlined,
              lines: _emergencyTreatmentLines,
              emptyMessage:
                  'Aucun traitement d’urgence prescrit.',
            ),

            _sectionCard(
              title: 'Traitement quotidien en cours',
              icon: Icons.medication_outlined,
              lines: _dailyTreatmentLines,
              emptyMessage:
                  'Aucun traitement quotidien en cours.',
            ),

            _sectionCard(
              title: 'Traitements arrêtés',
              icon: Icons.remove_circle_outline,
              lines: _discontinuedTreatmentLines,
              emptyMessage:
                  'Aucun traitement arrêté connu.',
            ),

            _sectionCard(
              title: 'Dispositifs médicaux utilisés',
              icon: Icons.settings_accessibility,
              lines: _medicalDeviceLines,
              emptyMessage: 'Aucun dispositif médical.',
            ),

            _sectionCard(
              title: 'Médecin traitant / référent',
              icon: Icons.local_hospital_outlined,
              lines: _primaryCareDoctorLines,
              emptyMessage: 'Non renseigné.',
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
