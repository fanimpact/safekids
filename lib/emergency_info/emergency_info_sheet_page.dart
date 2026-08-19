import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/complete_child_profile_data.dart';
import '../models/medical_device_data.dart';
import '../recommendation_engine/rules/environment_rules.dart';
import '../recommendation_engine/rules/universal_trigger_rules.dart';
import '../utils/age_utils.dart';
import '../utils/date_format_utils.dart';
import '../utils/medical_professional_line.dart';
import '../utils/pdf_text.dart';
import '../utils/treatment_audience.dart';

/// Fiche de lecture seule, générée uniquement à partir du profil déjà
/// rempli de l'enfant. Ce qui est affiché à l'écran et ce qui est
/// exporté (PDF / partage) sont strictement identiques : rien n'est
/// modifiable ici, cette page n'a pas d'état.
class EmergencyInfoSheetPage extends StatelessWidget {
  final CompleteChildProfileData child;

  /// Détermine la mention accolée à chaque traitement (PAI, indications
  /// du parent, ou aucune) — voir `TreatmentAudience`. Par défaut
  /// [TreatmentAudience.owner] (aucune mention), pour ne rien changer
  /// aux appels existants qui ne la précisent pas encore.
  final TreatmentAudience audience;

  const EmergencyInfoSheetPage({
    super.key,
    required this.child,
    this.audience = TreatmentAudience.owner,
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

  /// Consignes d'urgence numérotées, rédigées par le parent pour une
  /// pathologie ou une allergie précise — jusqu'ici visibles
  /// uniquement dans le Mode Urgence interactif de l'app, jamais sur
  /// cette fiche imprimable/partageable. Corrigé (19/08/2026) :
  /// c'est justement l'accompagnant sans l'app sous la main (fiche
  /// papier, lien partagé, pas de réseau) qui en a le plus besoin.
  List<({String label, List<String> steps})>
      get _emergencyInstructionEntries {
    final entries = <({String label, List<String> steps})>[];

    for (final pathology
        in child.essentialInformation.pathologies) {
      final name = pathology.name?.trim();

      final steps = pathology.emergencyInstructionSteps
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();

      if (name == null || name.isEmpty || steps.isEmpty) {
        continue;
      }

      entries.add((label: name, steps: steps));
    }

    for (final allergy
        in child.essentialInformation.allergies) {
      final allergen = allergy.allergen?.trim();

      final steps = allergy.emergencyInstructionSteps
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();

      if (allergen == null ||
          allergen.isEmpty ||
          steps.isEmpty) {
        continue;
      }

      entries.add((label: allergen, steps: steps));
    }

    return entries;
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

      var line = date != null && date.isNotEmpty
          ? '$name (diagnostiquée : $date)'
          : name;

      // Corrigé (audit passe 2) : spécialité, lieu d'exercice et
      // téléphone saisis mais jamais affichés sur cette fiche.
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

      if (event.emergencyTreatmentGiven == true) {
        details.add('traitement d’urgence donné');
      } else if (event.emergencyTreatmentGiven == false) {
        details.add('traitement d’urgence non donné');
      }

      if (event.hospitalized == true) {
        final hospitalName =
            event.hospitalName?.trim();
        final duration =
            event.hospitalizationDuration?.trim();

        final hasHospitalName =
            hospitalName != null &&
                hospitalName.isNotEmpty;
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

      lines.add(
        details.isEmpty
            ? name
            : '$name — ${details.join(' — ')}',
      );
    }

    return lines;
  }

  /// Facteurs déclenchants et sensibilités du profil santé, dans le
  /// même ordre de priorité que sur la fiche "Ce qu'il faut savoir
  /// sur...", du risque le plus direct au moins direct. Corrigé
  /// (19/08/2026) : ce texte vient désormais exclusivement des
  /// méthodes publiques de `EnvironmentRules`/`UniversalTriggerRules`
  /// — plus jamais réécrit ici, pour ne plus jamais diverger du texte
  /// utilisé lors de la préparation d'une activité.
  List<String> get _triggerFactorLines {
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    const environmentRules = EnvironmentRules();
    const universalTriggerRules = UniversalTriggerRules();

    final lines = <String>[
      ...environmentRules
          .waterTriggerRecommendations(
        child.childId,
        triggerFactors,
      )
          .map((r) => r.text),
      ...environmentRules
          .heightRecommendations(
        child.childId,
        triggerFactors,
      )
          .map((r) => r.text),
      ...universalTriggerRules
          .photosensitivityRecommendations(
        child.childId,
        triggerFactors,
      )
          .map((r) => r.text),
      ...environmentRules
          .animalRecommendations(
        child.childId,
        triggerFactors,
      )
          .map((r) => r.text),
    ];

    final heat = universalTriggerRules.heatRecommendation(
      child.childId,
      triggerFactors,
    );

    if (heat != null) {
      lines.add(heat.text);
    }

    final fatigue =
        universalTriggerRules.fatigueRecommendation(
      child.childId,
      triggerFactors,
    );

    if (fatigue != null) {
      lines.add(fatigue.text);
    }

    final stress =
        universalTriggerRules.stressRecommendation(
      child.childId,
      triggerFactors,
    );

    if (stress != null) {
      lines.add(stress.text);
    }

    final physicalEffort =
        environmentRules.physicalEffortRecommendation(
      child.childId,
      triggerFactors,
    );

    if (physicalEffort != null) {
      lines.add(physicalEffort.text);
    }

    final noise = environmentRules.noiseRecommendation(
      child.childId,
      triggerFactors,
    );

    if (noise != null) {
      lines.add(noise.text);
    }

    final crowd = environmentRules.crowdRecommendation(
      child.childId,
      triggerFactors,
    );

    if (crowd != null) {
      lines.add(crowd.text);
    }

    final confinedSpace =
        environmentRules.confinedSpaceRecommendation(
      child.childId,
      triggerFactors,
    );

    if (confinedSpace != null) {
      lines.add(confinedSpace.text);
    }

    final other =
        universalTriggerRules.otherTriggerFactorRecommendation(
      child.childId,
      triggerFactors,
    );

    if (other != null) {
      lines.add(other.text);
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

  /// Corrigé (audit passe 2) : cette distinction existait déjà sur
  /// "Ce qu'il faut savoir sur...", pas ici — pourtant au moins aussi
  /// utile en urgence (un dispositif implanté change ce qu'il faut
  /// faire).
  List<String> get _nonPermanentMedicalDeviceLines {
    return _medicalDeviceLines(
      (device) => device.isWornOrImplantedPermanently != true,
    );
  }

  List<String> get _permanentMedicalDeviceLines {
    return _medicalDeviceLines(
      (device) => device.isWornOrImplantedPermanently == true,
    );
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

          ..._pdfEmergencyInstructions(),

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

          if (_triggerFactorLines.isNotEmpty) ...[
            pdfSectionTitle(
              'Facteurs déclenchants et sensibilités',
            ),
            ..._triggerFactorLines.map(pdfBullet),
          ],

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
            _nonPermanentMedicalDeviceLines,
            'Aucun dispositif médical.',
          ),

          if (_permanentMedicalDeviceLines.isNotEmpty) ...[
            pdfSectionTitle(
              'Dispositifs portés ou implantés en permanence',
            ),
            ..._permanentMedicalDeviceLines.map(pdfBullet),
          ],

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

  List<pw.Widget> _pdfEmergencyInstructions() {
    final entries = _emergencyInstructionEntries;

    if (entries.isEmpty) {
      return [];
    }

    final widgets = <pw.Widget>[
      pdfSectionTitle('Consignes d’urgence'),
    ];

    for (final entry in entries) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(
            top: 4,
            bottom: 2,
          ),
          child: pw.Text(
            pdfSafeText(entry.label),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      for (var index = 0;
          index < entry.steps.length;
          index++) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              bottom: 3,
            ),
            child: pw.Text(
              pdfSafeText(
                '${index + 1}. ${entry.steps[index]}',
              ),
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        );
      }
    }

    return widgets;
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

  Widget _emergencyInstructionsCard() {
    final entries = _emergencyInstructionEntries;

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency_outlined,
                  size: 22,
                  color: Colors.red.shade800,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Consignes d’urgence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var entryIndex = 0;
                entryIndex < entries.length;
                entryIndex++) ...[
              Text(
                entries[entryIndex].label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (var stepIndex = 0;
                  stepIndex <
                      entries[entryIndex].steps.length;
                  stepIndex++)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 6,
                    left: 4,
                  ),
                  child: Text(
                    '${stepIndex + 1}. '
                    '${entries[entryIndex].steps[stepIndex]}',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              if (entryIndex < entries.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
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

            _emergencyInstructionsCard(),

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

            if (_triggerFactorLines.isNotEmpty)
              _sectionCard(
                title:
                    'Facteurs déclenchants et sensibilités',
                icon: Icons.visibility_outlined,
                lines: _triggerFactorLines,
                emptyMessage: '',
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
              lines: _nonPermanentMedicalDeviceLines,
              emptyMessage: 'Aucun dispositif médical.',
            ),

            if (_permanentMedicalDeviceLines.isNotEmpty)
              _sectionCard(
                title:
                    'Dispositifs portés ou implantés en '
                    'permanence',
                icon: Icons.favorite_border,
                lines: _permanentMedicalDeviceLines,
                emptyMessage: '',
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
