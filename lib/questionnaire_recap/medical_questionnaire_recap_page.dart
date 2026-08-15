import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/complete_child_profile_data.dart';
import '../models/trigger_factor_data.dart';
import '../utils/date_format_utils.dart';
import '../utils/pdf_text.dart';

/// Récapitulatif intégral du questionnaire santé pour un enfant : chaque
/// question posée dans le parcours (Identité → Pathologies → Allergies →
/// Événements médicaux → Observations médicales → Facteurs déclenchants →
/// Traitements → Dispositifs médicaux → Contacts), avec la réponse déjà
/// donnée. Lecture seule — rien n'est modifiable ici.
class MedicalQuestionnaireRecapPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const MedicalQuestionnaireRecapPage({
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

  String _formatMeasurement(double value, String unit) {
    final formatted = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toString();

    return '$formatted $unit';
  }

  List<String> get _identityLines {
    final identity =
        child.essentialInformation.identity;

    final dateOfBirth = identity.dateOfBirth;

    return [
      _qaText(
        'Prénom de l’enfant',
        identity.firstName,
      ),
      _qaText(
        'Nom de famille de l’enfant',
        identity.lastName,
      ),
      _qa(
        'Date de naissance',
        dateOfBirth == null
            ? 'Non renseigné'
            : '${dateOfBirth.day.toString().padLeft(2, '0')}/'
                '${dateOfBirth.month.toString().padLeft(2, '0')}/'
                '${dateOfBirth.year}',
      ),
      _qa(
        'Taille de l’enfant en cm',
        identity.heightCm == null
            ? 'Non renseigné'
            : _formatMeasurement(
                identity.heightCm!,
                'cm',
              ),
      ),
      _qa(
        'Poids de l’enfant en kg',
        identity.weightKg == null
            ? 'Non renseigné'
            : _formatMeasurement(
                identity.weightKg!,
                'kg',
              ),
      ),
      if (identity.weightKg != null ||
          identity.heightCm != null)
        _qa(
          'À quelle date ces valeurs ont-elles été mesurées ?',
          identity.measurementsUpdatedAt == null
              ? 'Non renseigné'
              : formatShortDate(
                  identity.measurementsUpdatedAt!,
                ),
        ),
    ];
  }

  List<String> get _pathologyLines {
    final pathologies =
        child.essentialInformation.pathologies;

    if (pathologies.isEmpty) {
      return [
        'Votre enfant présente-t-il une ou plusieurs pathologies diagnostiquées par un professionnel de santé ? — Non',
      ];
    }

    final lines = <String>[
      'Votre enfant présente-t-il une ou plusieurs pathologies diagnostiquées par un professionnel de santé ? — Oui',
    ];

    for (var index = 0;
        index < pathologies.length;
        index++) {
      final pathology = pathologies[index];

      lines.add('Pathologie n°${index + 1}');
      lines.add(
        _qaText('Nom de la pathologie', pathology.name),
      );
      lines.add(
        _qaText(
          'Date ou année approximative du diagnostic',
          pathology.approximateDiagnosisDate,
        ),
      );
      lines.add(
        _qaBool(
          'Cette pathologie est-elle suivie par un professionnel de santé référent ?',
          pathology.hasReferringProfessional,
        ),
      );

      final professional = pathology.referringProfessional;

      if (pathology.hasReferringProfessional &&
          professional != null) {
        lines.add(
          _qaText(
            'Nom du professionnel référent',
            professional.name,
          ),
        );
        lines.add(
          _qaText('Spécialité', professional.specialty),
        );
        lines.add(
          _qaText(
            'Lieu d’exercice',
            professional.workplace,
          ),
        );
        lines.add(
          _qaText(
            'Téléphone (facultatif)',
            professional.phoneNumber,
          ),
        );
      }
    }

    return lines;
  }

  List<String> get _allergyLines {
    final allergies =
        child.essentialInformation.allergies;

    if (allergies.isEmpty) {
      return [
        'Votre enfant présente-t-il une ou plusieurs allergies nécessitant une vigilance particulière ? — Non',
      ];
    }

    final lines = <String>[
      'Votre enfant présente-t-il une ou plusieurs allergies nécessitant une vigilance particulière ? — Oui',
    ];

    for (var index = 0;
        index < allergies.length;
        index++) {
      final allergy = allergies[index];

      lines.add('Allergie n°${index + 1}');
      lines.add(
        _qaText(
          'À quoi votre enfant est-il allergique ?',
          allergy.allergen,
        ),
      );
      lines.add(
        _qaText(
          'Réaction déjà observée',
          allergy.observedReaction,
        ),
      );
    }

    return lines;
  }

  List<String> get _medicalEventLines {
    final events =
        child.essentialInformation.medicalEvents;

    if (events.isEmpty) {
      return ['Aucun événement médical renseigné.'];
    }

    final lines = <String>[];

    for (var index = 0; index < events.length; index++) {
      final event = events[index];

      lines.add('Événement n°${index + 1}');
      lines.add(
        _qaText(
          'Quel événement médical important s’est produit ?',
          event.description,
        ),
      );
      lines.add(
        _qaText(
          'Date ou année approximative',
          event.approximateDate,
        ),
      );
      lines.add(
        _qaBool(
          'Les secours sont-ils intervenus ?',
          event.emergencyServicesCalled,
        ),
      );
      lines.add(
        _qaBool(
          "Le traitement d'urgence a-t-il été donné lors de cet événement ?",
          event.emergencyTreatmentGiven,
        ),
      );
      lines.add(
        _qaBool(
          'L’enfant a-t-il été hospitalisé ?',
          event.hospitalized,
        ),
      );

      if (event.hospitalized == true) {
        lines.add(
          _qaText(
            'Dans quel hôpital ?',
            event.hospitalName,
          ),
        );
        lines.add(
          _qaText(
            'Durée de l’hospitalisation (facultatif)',
            event.hospitalizationDuration,
          ),
        );
      }

      lines.add(
        _qaBool(
          'Des examens médicaux importants ont-ils été réalisés ?',
          event.importantExaminationsPerformed,
        ),
      );

      if (event.importantExaminationsPerformed == true) {
        lines.add(
          _qaText('Lesquels ?', event.importantExaminations),
        );
      }
    }

    return lines;
  }

  List<String> get _medicalObservationLines {
    final observations =
        child.essentialInformation.medicalObservations;

    if (observations.isEmpty) {
      return ['Aucune observation médicale renseignée.'];
    }

    final lines = <String>[];

    for (var index = 0;
        index < observations.length;
        index++) {
      final observation = observations[index];

      lines.add('Observation n°${index + 1}');
      lines.add(
        _qaText(
          'Quel fait médical a été observé ?',
          observation.description,
        ),
      );
      lines.add(
        _qaText(
          'Date ou période approximative',
          observation.approximateDate,
        ),
      );
      lines.add(
        _qaText(
          'Conclusion',
          observation.conclusion,
        ),
      );
    }

    return lines;
  }

  List<String> get _primaryCareDoctorLines {
    final doctor =
        child.essentialInformation.primaryCareDoctor;

    return [
      _qaText('Nom du médecin traitant', doctor.name),
      _qaText('Lieu d’exercice', doctor.workplace),
      _qaText(
        'Téléphone (facultatif)',
        doctor.phoneNumber,
      ),
    ];
  }

  List<String> get _triggerFactorLines {
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    final lines = <String>[];

    lines.add(
      _qaBool(
        'Les lumières clignotantes (photosensibilité) nécessitent-elles une vigilance particulière pour votre enfant ?',
        triggerFactors.flashingLights,
      ),
    );

    if (triggerFactors.flashingLights == true) {
      lines.add(
        _qaBool(
          'Le port de lunettes est-il nécessaire lors des activités en extérieur ?',
          triggerFactors.requiresGlassesOutdoors,
        ),
      );
    }

    lines.add(
      _qaBool(
        'La chaleur nécessite-t-elle une vigilance particulière pour votre enfant ?',
        triggerFactors.heat,
      ),
    );
    lines.add(
      _qaBool(
        'La fatigue ou le manque de sommeil nécessitent-ils une vigilance particulière pour votre enfant ?',
        triggerFactors.fatigueOrLackOfSleep,
      ),
    );
    lines.add(
      _qaBool(
        'Le bruit nécessite-t-il une vigilance particulière pour votre enfant ?',
        triggerFactors.noise,
      ),
    );
    lines.add(
      _qaBool(
        'La foule nécessite-t-elle une vigilance particulière pour votre enfant ?',
        triggerFactors.crowd,
      ),
    );
    lines.add(
      _qaBool(
        'Les espaces confinés nécessitent-ils une vigilance particulière pour votre enfant ?',
        triggerFactors.confinedSpaces,
      ),
    );
    lines.add(
      _qaBool(
        'L’effort physique nécessite-t-il une vigilance particulière pour votre enfant ?',
        triggerFactors.physicalEffort,
      ),
    );
    lines.add(
      _qaBool(
        'Le stress ou les émotions fortes nécessitent-ils une vigilance particulière pour votre enfant ?',
        triggerFactors.stressOrStrongEmotions,
      ),
    );

    lines.add('Contact avec l’eau');
    lines.add(
      _qaBool(
        'Le contact avec l’eau nécessite-t-il une vigilance particulière pour votre enfant ?',
        triggerFactors.waterContact,
      ),
    );

    if (triggerFactors.waterContact == true) {
      lines.add(
        _qa(
          'Quelle vigilance est nécessaire ?',
          switch (triggerFactors.waterVigilance) {
            WaterVigilance.mayJumpIntoWater =>
              'Risque de se jeter dans l’eau',
            WaterVigilance.cannotSwim => 'Ne sait pas nager',
            WaterVigilance.other =>
              'Autre : ${_textOr(triggerFactors.otherWaterVigilance)}',
            null => 'Non renseigné',
          },
        ),
      );
    }

    lines.add('Présence d’animaux');
    lines.add(
      _qaBool(
        'La présence d’animaux nécessite-t-elle une vigilance particulière pour votre enfant ?',
        triggerFactors.animals,
      ),
    );

    if (triggerFactors.animals == true) {
      lines.add(
        _qa(
          'Quelle vigilance est nécessaire ?',
          switch (triggerFactors.animalVigilance) {
            AnimalVigilance.importantFear =>
              'Peur importante des animaux',
            AnimalVigilance.approachesWithoutPerceivingDanger =>
              'Tendance à s’approcher des animaux sans percevoir le danger',
            AnimalVigilance.other =>
              'Autre : ${_textOr(triggerFactors.otherAnimalVigilance)}',
            null => 'Non renseigné',
          },
        ),
      );
    }

    lines.add('Hauteur');
    lines.add(
      _qaBool(
        'La hauteur nécessite-t-elle une vigilance particulière pour votre enfant ?',
        triggerFactors.height,
      ),
    );

    if (triggerFactors.height == true) {
      lines.add(
        _qa(
          'Quelle vigilance est nécessaire ?',
          switch (triggerFactors.heightVigilance) {
            HeightVigilance.doesNotPerceiveDanger =>
              'Absence de perception du danger',
            HeightVigilance.vertigoOrImportantFear =>
              'Vertige ou peur importante',
            HeightVigilance.other =>
              'Autre : ${_textOr(triggerFactors.otherHeightVigilance)}',
            null => 'Non renseigné',
          },
        ),
      );
    }

    lines.add(
      _qaText(
        'Autre facteur déclencheur ou sensibilité',
        triggerFactors.other,
      ),
    );

    return lines;
  }

  List<String> get _dailyTreatmentLines {
    final treatments =
        child.essentialInformation.dailyTreatments;

    if (treatments.isEmpty) {
      return [
        'En dehors des traitements ponctuels (antibiotiques, Doliprane...), votre enfant suit-il un ou plusieurs traitements quotidiens prescrits ? — Non',
      ];
    }

    final lines = <String>[
      'En dehors des traitements ponctuels (antibiotiques, Doliprane...), votre enfant suit-il un ou plusieurs traitements quotidiens prescrits ? — Oui',
    ];

    for (var index = 0;
        index < treatments.length;
        index++) {
      final treatment = treatments[index];

      lines.add('Traitement quotidien n°${index + 1}');
      lines.add(
        _qaText('Nom du traitement', treatment.medicationName),
      );
      lines.add(_qaText('Posologie', treatment.dosage));
      lines.add(
        _qaText(
          'À quelle(s) heure(s) est-il habituellement administré ?',
          treatment.administrationTimes,
        ),
      );
    }

    return lines;
  }

  List<String> get _discontinuedTreatmentLines {
    final treatments = child
        .essentialInformation.discontinuedTreatments;

    if (treatments.isEmpty) {
      return [
        'Votre enfant a-t-il arrêté un traitement récemment ? — Non',
      ];
    }

    final lines = <String>[
      'Votre enfant a-t-il arrêté un traitement récemment ? — Oui',
    ];

    for (var index = 0;
        index < treatments.length;
        index++) {
      final treatment = treatments[index];

      lines.add('Traitement arrêté n°${index + 1}');
      lines.add(
        _qaText(
          'Nom du traitement',
          treatment.medicationName,
        ),
      );
      lines.add(
        _qaText(
          'Date d’arrêt approximative (mois/année suffit)',
          treatment.approximateStopDate,
        ),
      );
    }

    return lines;
  }

  List<String> get _emergencyTreatmentLines {
    final treatments =
        child.essentialInformation.emergencyTreatments;

    if (treatments.isEmpty) {
      return [
        'Votre enfant dispose-t-il d’un ou plusieurs traitements d’urgence prescrits ? — Non',
      ];
    }

    final lines = <String>[
      'Votre enfant dispose-t-il d’un ou plusieurs traitements d’urgence prescrits ? — Oui',
    ];

    for (var index = 0;
        index < treatments.length;
        index++) {
      final treatment = treatments[index];

      lines.add('Traitement d’urgence n°${index + 1}');
      lines.add(
        _qaText('Nom du traitement', treatment.medicationName),
      );
      lines.add(
        _qaText(
          'Dans quelle situation doit-il être administré ?',
          treatment.administrationCondition,
        ),
      );
      lines.add(_qaText('Posologie', treatment.dosage));
      lines.add(
        _qaText(
          'Mode d’administration',
          treatment.administrationMethod,
        ),
      );
    }

    return lines;
  }

  List<String> get _allergyTreatmentLines {
    final allergies =
        child.essentialInformation.allergies;

    if (allergies.isEmpty) {
      return ['Aucune allergie déclarée.'];
    }

    final lines = <String>[];

    for (final allergy in allergies) {
      final allergen = allergy.allergen?.trim();

      lines.add(
        allergen != null && allergen.isNotEmpty
            ? allergen
            : 'Allergie',
      );
      lines.add(
        _qaBool(
          'Votre enfant suit-il un traitement quotidien pour cette allergie ?',
          allergy.hasDailyTreatment,
        ),
      );

      if (allergy.hasDailyTreatment == true) {
        lines.add(
          _qaText(
            'Nom du traitement quotidien',
            allergy.dailyTreatmentName,
          ),
        );
        lines.add(
          _qaText(
            'Posologie',
            allergy.dailyTreatmentDosage,
          ),
        );
      }

      lines.add(
        _qaBool(
          'Votre enfant dispose-t-il d’un traitement d’urgence pour cette allergie ?',
          allergy.hasEmergencyTreatment,
        ),
      );

      if (allergy.hasEmergencyTreatment == true) {
        lines.add(
          _qaText(
            'Nom du traitement d’urgence',
            allergy.emergencyTreatmentName,
          ),
        );
        lines.add(
          _qaText(
            'Posologie',
            allergy.emergencyTreatmentDosage,
          ),
        );
      }
    }

    return lines;
  }

  List<String> get _medicalDeviceLines {
    final devices =
        child.essentialInformation.medicalDevices;

    if (devices.isEmpty) {
      return [
        'Votre enfant utilise-t-il un ou plusieurs dispositifs médicaux ? — Non',
      ];
    }

    final lines = <String>[
      'Votre enfant utilise-t-il un ou plusieurs dispositifs médicaux ? — Oui',
    ];

    for (var index = 0; index < devices.length; index++) {
      final device = devices[index];

      lines.add('Dispositif n°${index + 1}');
      lines.add(
        _qaText('Nom du dispositif', device.deviceName),
      );
      lines.add(_qaText('À quoi sert-il ?', device.mainUse));
      lines.add(
        _qa(
          'Comment ce dispositif est-il utilisé ?',
          switch (device.isWornOrImplantedPermanently) {
            true => 'Porté ou implanté en permanence',
            false =>
              'À emporter ou préparer pour chaque sortie',
            null => 'Non renseigné',
          },
        ),
      );
    }

    return lines;
  }

  List<String> get _contactLines {
    final contacts = child.essentialInformation.contacts;

    if (contacts.isEmpty) {
      return ['Aucun contact renseigné.'];
    }

    final lines = <String>[];

    for (var index = 0; index < contacts.length; index++) {
      final contact = contacts[index];

      lines.add(
        index == 0
            ? 'Parent ou responsable légal n°1'
            : index == 1
                ? 'Parent ou responsable légal n°2 (facultatif)'
                : 'Autre contact n°${index - 1}',
      );
      lines.add(
        _qaText('Nom et prénom', contact.fullName),
      );
      lines.add(
        _qaText('Lien avec l’enfant', contact.relationship),
      );
      lines.add(
        _qaText(
          'Numéro de téléphone',
          contact.phoneNumber,
        ),
      );
    }

    return lines;
  }

  List<_RecapSection> get _sections {
    return [
      _RecapSection(
        title: 'Identité',
        icon: Icons.badge_outlined,
        lines: _identityLines,
      ),
      _RecapSection(
        title: 'Pathologies diagnostiquées',
        icon: Icons.medical_information_outlined,
        lines: _pathologyLines,
      ),
      _RecapSection(
        title: 'Allergies importantes',
        icon: Icons.warning_amber_rounded,
        lines: _allergyLines,
      ),
      _RecapSection(
        title: 'Événements médicaux importants',
        icon: Icons.event_note_outlined,
        lines: _medicalEventLines,
      ),
      _RecapSection(
        title: 'Observations médicales',
        icon: Icons.fact_check_outlined,
        lines: _medicalObservationLines,
      ),
      _RecapSection(
        title: 'Médecin traitant',
        icon: Icons.local_hospital_outlined,
        lines: _primaryCareDoctorLines,
      ),
      _RecapSection(
        title:
            'Facteurs déclenchants et sensibilités',
        icon: Icons.sensors_outlined,
        lines: _triggerFactorLines,
      ),
      _RecapSection(
        title: 'Traitements réguliers',
        icon: Icons.medication_outlined,
        lines: _dailyTreatmentLines,
      ),
      _RecapSection(
        title: 'Traitements arrêtés',
        icon: Icons.remove_circle_outline,
        lines: _discontinuedTreatmentLines,
      ),
      _RecapSection(
        title: 'Traitements d’urgence',
        icon: Icons.medical_services_outlined,
        lines: _emergencyTreatmentLines,
      ),
      _RecapSection(
        title: 'Traitement lié à chaque allergie',
        icon: Icons.healing_outlined,
        lines: _allergyTreatmentLines,
      ),
      _RecapSection(
        title: 'Dispositifs médicaux',
        icon: Icons.settings_accessibility,
        lines: _medicalDeviceLines,
      ),
      _RecapSection(
        title: 'Contacts à prévenir',
        icon: Icons.contact_phone_outlined,
        lines: _contactLines,
      ),
    ];
  }

  Future<void> _print() async {
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdfBytes(),
      name: 'Questionnaire sante - $_displayName',
    );
  }

  Future<void> _share() async {
    await Printing.sharePdf(
      bytes: await _buildPdfBytes(),
      filename:
          'questionnaire_sante_$_displayName.pdf',
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
              'Questionnaire santé — $_displayName',
            ),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          for (final section in _sections) ...[
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire santé'),
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

            const SizedBox(height: 24),

            for (final section in _sections)
              Card(
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final line in section.lines)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Padding(
                                padding:
                                    EdgeInsets.only(
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
