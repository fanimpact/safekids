import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import '../recommendation_engine/models/recommendation.dart';
import '../recommendation_engine/models/recommendation_category.dart';
import '../repositories/child_repository.dart';
import '../utils/age_utils.dart';
import '../utils/date_format_utils.dart';
import '../utils/pdf_text.dart';
import 'activities_home_page.dart';

class ActivityRecommendationsPage extends StatelessWidget {
  final CompleteActivitySessionData activitySession;
  final ActivityRecommendationResult recommendationResult;
  final CompleteChildProfileData? Function(String childId) findChild;

  ActivityRecommendationsPage({
    super.key,
    required this.activitySession,
    required this.recommendationResult,
    CompleteChildProfileData? Function(String childId)? findChild,
  }) : findChild = findChild ?? ChildRepository.instance.findByChildId;

  String _childDisplayName(
    String childId,
  ) {
    final child = findChild(
      childId,
    );

    if (child == null) {
      return 'Enfant';
    }

    final firstName =
        child.essentialInformation.identity.firstName;

    final lastName =
        child.essentialInformation.identity.lastName;

    final displayName = [
      firstName,
      lastName,
    ].where(
      (value) =>
          value != null &&
          value.trim().isNotEmpty,
    ).map(
      (value) => value!.trim(),
    ).join(' ');

    return displayName.isEmpty
        ? 'Enfant'
        : displayName;
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

  /// Âge, poids, taille et date de mesure de l'enfant, dans le même
  /// format que sur la fiche secours et la fiche "Ce qu'il faut savoir
  /// sur...". Retourne null si rien n'est renseigné.
  String? _childMeasurementDetails(
    String childId,
  ) {
    final child = findChild(
      childId,
    );

    if (child == null) {
      return null;
    }

    final identity =
        child.essentialInformation.identity;

    final parts = <String>[];

    final age = formatAge(identity.dateOfBirth);

    if (age != null) {
      parts.add(age);
    }

    if (identity.weightKg != null) {
      parts.add(
        _formatMeasurement(
          identity.weightKg!,
          'kg',
        ),
      );
    }

    if (identity.heightCm != null) {
      parts.add(
        _formatMeasurement(
          identity.heightCm!,
          'cm',
        ),
      );
    }

    if (identity.weightKg != null ||
        identity.heightCm != null) {
      parts.add(
        identity.measurementsUpdatedAt == null
            ? 'date de mesure non renseignée'
            : 'mesurés le ${formatShortDate(
                identity.measurementsUpdatedAt!,
              )}',
      );
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' · ');
  }

  Widget _buildChildrenIdentitySummary() {
    final lines = <Widget>[];

    for (final childId in activitySession.childIds) {
      final details = _childMeasurementDetails(childId);

      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: _childDisplayName(childId),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details != null)
                  TextSpan(text: ' — $details'),
              ],
            ),
          ),
        ),
      );
    }

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  List<pw.Widget> _pdfChildrenIdentitySummary() {
    final widgets = <pw.Widget>[];

    for (final childId in activitySession.childIds) {
      final details = _childMeasurementDetails(childId);
      final name = _childDisplayName(childId);

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Text(
            pdfSafeText(
              details == null
                  ? name
                  : '$name — $details',
            ),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    return widgets;
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  List<Recommendation> _recommendationsForChild(
    String childId,
  ) {
    final results =
        recommendationResult.childResults.where(
      (result) => result.childId == childId,
    );

    if (results.isEmpty) {
      return [];
    }

    return results.first.recommendations;
  }

  List<Recommendation> _recommendationsForChildAndCategory(
    String childId,
    RecommendationCategory category,
  ) {
    return _recommendationsForChild(childId)
        .where(
          (recommendation) =>
              recommendation.category == category,
        )
        .toList();
  }

  List<String> _allergyTexts(
    String childId,
  ) {
    final child = findChild(
      childId,
    );

    if (child == null) {
      return [];
    }

    final texts = <String>[];

    for (final allergy
        in child.essentialInformation.allergies) {
      final allergen =
          allergy.allergen?.trim();

      if (allergen == null ||
          allergen.isEmpty) {
        continue;
      }

      final reaction =
          allergy.observedReaction?.trim();

      if (reaction != null &&
          reaction.isNotEmpty) {
        texts.add(
          'Allergie : $allergen — Réaction connue : $reaction',
        );
      } else {
        texts.add(
          'Allergie : $allergen',
        );
      }
    }

    return texts;
  }

  bool _isSituationRecommendation(
    Recommendation recommendation,
  ) {
    return recommendation.category ==
            RecommendationCategory.adaptation ||
        recommendation.category ==
            RecommendationCategory.equipment ||
        recommendation.category ==
            RecommendationCategory.rememberToTake;
  }

  String _situationTitle(
    Recommendation recommendation,
  ) {
    final id = recommendation.id;

    if (id.startsWith('water_')) {
      return 'Baignade / Eau';
    }

    if (id.startsWith('overnight_')) {
      return 'Nuit';
    }

    if (id.startsWith('transport_')) {
      return 'Transport';
    }

    if (id.startsWith(
          'prolonged_walking_',
        ) ||
        id.startsWith(
          'intense_physical_effort_',
        )) {
      return 'Marche / Effort';
    }

    if (id.startsWith('environment_')) {
      return 'Environnement';
    }

    if (id.startsWith('clothing_')) {
      return 'Habillage';
    }

    if (id.startsWith('toilets_')) {
      return 'Toilettes';
    }

    if (id.startsWith('communication_')) {
      return 'Communication';
    }

    if (id.startsWith('transitions_')) {
      return 'Transitions';
    }

    if (id == 'photosensitivity_glasses') {
      return 'Extérieur';
    }

    return 'Autres';
  }

  Map<String, Map<String, List<Recommendation>>>
      _buildSituationGroups() {
    final groups =
        <String, Map<String, List<Recommendation>>>{};

    for (final childId in activitySession.childIds) {
      final recommendations =
          _recommendationsForChild(childId);

      for (final recommendation
          in recommendations) {
        if (!_isSituationRecommendation(
          recommendation,
        )) {
          continue;
        }

        final situation =
            _situationTitle(recommendation);

        groups.putIfAbsent(
          situation,
          () =>
              <String, List<Recommendation>>{},
        );

        groups[situation]!.putIfAbsent(
          childId,
          () => <Recommendation>[],
        );

        groups[situation]![childId]!.add(
          recommendation,
        );
      }
    }

    return groups;
  }

  Widget _buildSectionTitle(
    String title, {
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildTitle(
    String childId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        _childDisplayName(childId),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBullet(
    String text,
  ) {
    return Padding(
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
              text,
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

  Widget _buildImportantPoints() {
    final childrenWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final vigilanceRecommendations =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .informationVigilance,
      );

      final allergyTexts =
          _allergyTexts(childId);

      final additionalInformation =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .additionalInformation,
      );

      if (vigilanceRecommendations.isEmpty &&
          allergyTexts.isEmpty &&
          additionalInformation.isEmpty) {
        continue;
      }

      childrenWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildChildTitle(childId),

              for (final text in allergyTexts)
                _buildBullet(text),

              for (final recommendation
                  in vigilanceRecommendations)
                _buildBullet(
                  recommendation.text,
                ),

              for (final recommendation
                  in additionalInformation)
                _buildBullet(
                  recommendation.text,
                ),
            ],
          ),
        ),
      );
    }

    final globalVigilances =
        recommendationResult
            .globalRecommendations
            .where(
              (recommendation) =>
                  recommendation.category ==
                  RecommendationCategory
                      .informationVigilance,
            )
            .toList();

    if (childrenWidgets.isEmpty &&
        globalVigilances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Points importants',
              icon:
                  Icons.warning_amber_rounded,
            ),

            if (globalVigilances.isNotEmpty) ...[
              const Text(
                'Pour l’activité',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              for (final recommendation
                  in globalVigilances)
                _buildBullet(
                  recommendation.text,
                ),

              const Divider(
                height: 28,
              ),
            ],

            ...childrenWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildSituations() {
    final groups =
        _buildSituationGroups();

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    const preferredOrder = [
      'Baignade / Eau',
      'Nuit',
      'Transport',
      'Marche / Effort',
      'Extérieur',
      'Environnement',
      'Habillage',
      'Toilettes',
      'Communication',
      'Transitions',
      'Autres',
    ];

    final orderedSituations = <String>[
      ...preferredOrder.where(
        groups.containsKey,
      ),
      ...groups.keys.where(
        (key) =>
            !preferredOrder.contains(key),
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'À prévoir par situation',
              icon:
                  Icons.checklist_rounded,
            ),

            for (final situation
                in orderedSituations) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                  bottom: 12,
                ),
                child: Text(
                  situation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              for (final childId
                  in activitySession.childIds)
                if (groups[situation]!
                    .containsKey(childId)) ...[
                  _buildChildTitle(childId),

                  for (final recommendation
                      in groups[situation]![
                          childId]!)
                    _buildBullet(
                      recommendation.text,
                    ),

                  const SizedBox(height: 8),
                ],

              if (situation !=
                  orderedSituations.last)
                const Divider(
                  height: 28,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyMedications() {
    final childWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final medications =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory
            .emergencyMedication,
      );

      if (medications.isEmpty) {
        continue;
      }

      childWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildChildTitle(childId),

              for (final medication
                  in medications)
                _buildBullet(
                  medication.text,
                ),
            ],
          ),
        ),
      );
    }

    if (childWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.red.shade300,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Médicaments d’urgence',
              icon:
                  Icons.medical_services_outlined,
              color:
                  Colors.red.shade800,
            ),
            ...childWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSummary() {
    final childWidgets = <Widget>[];

    for (final childId in activitySession.childIds) {
      final equipment =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.equipment,
      );

      final rememberToTake =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.rememberToTake,
      );

      final allItems = <Recommendation>[
        ...equipment,
        ...rememberToTake,
      ];

      if (allItems.isEmpty) {
        continue;
      }

      childWidgets.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildChildTitle(childId),

              for (final item in allItems)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons
                            .check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      Expanded(
                        child: Text(
                          item.text,
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
      );
    }

    if (childWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Matériel à prévoir — récapitulatif',
              icon:
                  Icons.backpack_outlined,
            ),
            ...childWidgets,
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfChildTitle(
    String childId,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        top: 6,
        bottom: 4,
      ),
      child: pw.Text(
        pdfSafeText(_childDisplayName(childId)),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  List<pw.Widget> _pdfImportantPointsSection() {
    final widgets = <pw.Widget>[];

    final globalVigilances =
        recommendationResult
            .globalRecommendations
            .where(
              (recommendation) =>
                  recommendation.category ==
                  RecommendationCategory
                      .informationVigilance,
            )
            .toList();

    final childBlocks = <pw.Widget>[];

    for (final childId in activitySession.childIds) {
      final vigilanceRecommendations =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.informationVigilance,
      );

      final allergyTexts = _allergyTexts(childId);

      final additionalInformation =
          _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.additionalInformation,
      );

      if (vigilanceRecommendations.isEmpty &&
          allergyTexts.isEmpty &&
          additionalInformation.isEmpty) {
        continue;
      }

      childBlocks.add(_pdfChildTitle(childId));

      for (final text in allergyTexts) {
        childBlocks.add(pdfBullet(text));
      }

      for (final recommendation in vigilanceRecommendations) {
        childBlocks.add(pdfBullet(recommendation.text));
      }

      for (final recommendation in additionalInformation) {
        childBlocks.add(pdfBullet(recommendation.text));
      }
    }

    if (globalVigilances.isEmpty && childBlocks.isEmpty) {
      return widgets;
    }

    widgets.add(pdfSectionTitle('Points importants'));

    for (final recommendation in globalVigilances) {
      widgets.add(pdfBullet(recommendation.text));
    }

    widgets.addAll(childBlocks);

    return widgets;
  }

  List<pw.Widget> _pdfSituationsSection() {
    final groups = _buildSituationGroups();

    if (groups.isEmpty) {
      return [];
    }

    const preferredOrder = [
      'Baignade / Eau',
      'Nuit',
      'Transport',
      'Marche / Effort',
      'Extérieur',
      'Environnement',
      'Habillage',
      'Toilettes',
      'Communication',
      'Transitions',
      'Autres',
    ];

    final orderedSituations = <String>[
      ...preferredOrder.where(groups.containsKey),
      ...groups.keys.where(
        (key) => !preferredOrder.contains(key),
      ),
    ];

    final widgets = <pw.Widget>[
      pdfSectionTitle('À prévoir par situation'),
    ];

    for (final situation in orderedSituations) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(
            top: 6,
            bottom: 2,
          ),
          child: pw.Text(
            situation,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      for (final childId in activitySession.childIds) {
        if (!groups[situation]!.containsKey(childId)) {
          continue;
        }

        widgets.add(_pdfChildTitle(childId));

        for (final recommendation
            in groups[situation]![childId]!) {
          widgets.add(pdfBullet(recommendation.text));
        }
      }
    }

    return widgets;
  }

  List<pw.Widget> _pdfEmergencyMedicationsSection() {
    final childBlocks = <pw.Widget>[];

    for (final childId in activitySession.childIds) {
      final medications = _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.emergencyMedication,
      );

      if (medications.isEmpty) {
        continue;
      }

      childBlocks.add(_pdfChildTitle(childId));

      for (final medication in medications) {
        childBlocks.add(pdfBullet(medication.text));
      }
    }

    if (childBlocks.isEmpty) {
      return [];
    }

    return [
      pdfSectionTitle('Médicaments d’urgence'),
      ...childBlocks,
    ];
  }

  List<pw.Widget> _pdfEquipmentSummarySection() {
    final childBlocks = <pw.Widget>[];

    for (final childId in activitySession.childIds) {
      final equipment = _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.equipment,
      );

      final rememberToTake = _recommendationsForChildAndCategory(
        childId,
        RecommendationCategory.rememberToTake,
      );

      final allItems = <Recommendation>[
        ...equipment,
        ...rememberToTake,
      ];

      if (allItems.isEmpty) {
        continue;
      }

      childBlocks.add(_pdfChildTitle(childId));

      for (final item in allItems) {
        childBlocks.add(pdfBullet(item.text));
      }
    }

    if (childBlocks.isEmpty) {
      return [];
    }

    return [
      pdfSectionTitle('Matériel à prévoir — récapitulatif'),
      ...childBlocks,
    ];
  }

  Future<Uint8List> _buildPdfBytes() async {
    final document = pw.Document();

    final activityName = activitySession.activityName;
    final activityDate = activitySession.date;
    final activityLocation = activitySession.location?.trim();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Fiche de recommandations',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          if (activityName != null &&
              activityName.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                pdfSafeText(activityName.trim()),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

          if (activityDate != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                '${_formatDate(activityDate)} à '
                '${_formatTime(activityDate)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),

          if (activityLocation != null &&
              activityLocation.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                pdfSafeText(activityLocation),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),

          ..._pdfChildrenIdentitySummary(),

          ..._pdfImportantPointsSection(),
          ..._pdfSituationsSection(),
          ..._pdfEmergencyMedicationsSection(),
          ..._pdfEquipmentSummarySection(),
        ],
      ),
    );

    return document.save();
  }

  Future<void> _printRecommendations() async {
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdfBytes(),
      name: 'Fiche de recommandations',
    );
  }

  void _finish(
    BuildContext context,
  ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivitiesHomePage(),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final activityName =
        activitySession.activityName;
    final activityDate =
        activitySession.date;
    final activityLocation =
        activitySession.location?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommandations',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimer / exporter en PDF',
            onPressed: _printRecommendations,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                children: [
                  const Text(
                    'Fiche de recommandations',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (activityName != null &&
                      activityName
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      activityName.trim(),
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],

                  if (activityDate != null) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(
                            activityDate,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(
                            activityDate,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (activityLocation != null &&
                      activityLocation
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activityLocation,
                            style:
                                const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  _buildChildrenIdentitySummary(),

                  const SizedBox(
                    height: 24,
                  ),

                  _buildImportantPoints(),

                  _buildSituations(),

                  _buildEmergencyMedications(),

                  _buildEquipmentSummary(),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      _finish(context),
                  child:
                      const Text(
                    'Terminer',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}