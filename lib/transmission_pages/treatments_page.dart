import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../utils/text_controller_cache.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'contacts_page.dart';

class TreatmentsPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const TreatmentsPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<TreatmentsPage> createState() =>
      _TreatmentsPageState();
}

class _TreatmentsPageState
    extends State<TreatmentsPage> {
  bool? _hasDailyTreatments;
  bool? _hasDiscontinuedTreatments;
  bool? _hasEmergencyTreatments;
  bool? _hasMedicalDevices;

  final _controllers = TextControllerCache();

  @override
  void initState() {
    super.initState();

    final draft =
        widget.transmissionController.formData;

    if (draft.dailyTreatments.isNotEmpty) {
      _hasDailyTreatments = true;
    }

    if (draft.discontinuedTreatments.isNotEmpty) {
      _hasDiscontinuedTreatments = true;
    }

    if (draft.emergencyTreatments.isNotEmpty) {
      _hasEmergencyTreatments = true;
    }

    if (draft.medicalDevices.isNotEmpty) {
      _hasMedicalDevices = true;
    }
  }

  @override
  void dispose() {
    _controllers.disposeAll();
    super.dispose();
  }

  void _updateHasDailyTreatments(
    bool value,
  ) {
    setState(() {
      _hasDailyTreatments = value;

      if (value) {
        widget.transmissionController
            .ensureFirstDailyTreatment();
      } else {
        widget.transmissionController
            .formData.dailyTreatments
            .clear();
      }
    });
  }

  void _updateHasDiscontinuedTreatments(
    bool value,
  ) {
    setState(() {
      _hasDiscontinuedTreatments = value;

      if (value) {
        widget.transmissionController
            .ensureFirstDiscontinuedTreatment();
      } else {
        widget.transmissionController
            .formData.discontinuedTreatments
            .clear();
      }
    });
  }

  void _updateHasEmergencyTreatments(
    bool value,
  ) {
    setState(() {
      _hasEmergencyTreatments = value;

      if (value) {
        widget.transmissionController
            .ensureFirstEmergencyTreatment();
      } else {
        widget.transmissionController
            .formData.emergencyTreatments
            .clear();
      }
    });
  }

  void _updateHasMedicalDevices(
    bool value,
  ) {
    setState(() {
      _hasMedicalDevices = value;

      if (value) {
        widget.transmissionController
            .ensureFirstMedicalDevice();
      } else {
        widget.transmissionController
            .formData.medicalDevices
            .clear();
      }
    });
  }

  void _addDailyTreatment() {
    setState(() {
      widget.transmissionController
          .addDailyTreatment();
    });
  }

  void _removeDailyTreatment(
    int index,
  ) {
    setState(() {
      widget.transmissionController
          .removeDailyTreatment(index);
    });
  }

  void _addDiscontinuedTreatment() {
    setState(() {
      widget.transmissionController
          .addDiscontinuedTreatment();
    });
  }

  void _removeDiscontinuedTreatment(
    int index,
  ) {
    setState(() {
      widget.transmissionController
          .removeDiscontinuedTreatment(index);
    });
  }

  void _addEmergencyTreatment() {
    setState(() {
      widget.transmissionController
          .addEmergencyTreatment();
    });
  }

  void _removeEmergencyTreatment(
    int index,
  ) {
    setState(() {
      widget.transmissionController
          .removeEmergencyTreatment(index);
    });
  }

  void _updateAllergyHasDailyTreatment(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateAllergyHasDailyTreatment(
        index,
        value,
      );
    });
  }

  void _updateAllergyHasEmergencyTreatment(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateAllergyHasEmergencyTreatment(
        index,
        value,
      );
    });
  }

  void _addMedicalDevice() {
    setState(() {
      widget.transmissionController
          .addMedicalDevice();
    });
  }

  void _removeMedicalDevice(
    int index,
  ) {
    setState(() {
      widget.transmissionController
          .removeMedicalDevice(index);
    });
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContactsPage(
          transmissionController:
              widget.transmissionController,
        ),
      ),
    );
  }

  Widget _buildDailyTreatmentPathologies(
    int treatmentIndex,
  ) {
    final draft =
        widget.transmissionController.formData;

    final pathologies = draft.pathologies
        .where(
          (pathology) =>
              pathology.name != null &&
              pathology.name!
                  .trim()
                  .isNotEmpty,
        )
        .toList();

    if (pathologies.isEmpty) {
      return const SizedBox.shrink();
    }

    final treatment =
        draft.dailyTreatments[
          treatmentIndex
        ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Ce traitement est-il lié à une ou plusieurs pathologies renseignées ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        for (final pathology in pathologies)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity.leading,
            title: Text(
              pathology.name!.trim(),
            ),
            value: treatment
                .relatedPathologyIds
                .contains(
              pathology.pathologyId,
            ),
            onChanged: (value) {
              setState(() {
                widget
                    .transmissionController
                    .updateDailyTreatmentPathology(
                  treatmentIndex,
                  pathology.pathologyId,
                  value ?? false,
                );
              });
            },
          ),
      ],
    );
  }

  Widget _buildEmergencyTreatmentPathologies(
    int treatmentIndex,
  ) {
    final draft =
        widget.transmissionController.formData;

    final pathologies = draft.pathologies
        .where(
          (pathology) =>
              pathology.name != null &&
              pathology.name!
                  .trim()
                  .isNotEmpty,
        )
        .toList();

    if (pathologies.isEmpty) {
      return const SizedBox.shrink();
    }

    final treatment =
        draft.emergencyTreatments[
          treatmentIndex
        ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Ce traitement est-il lié à une ou plusieurs pathologies renseignées ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        for (final pathology in pathologies)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity.leading,
            title: Text(
              pathology.name!.trim(),
            ),
            value: treatment
                .relatedPathologyIds
                .contains(
              pathology.pathologyId,
            ),
            onChanged: (value) {
              setState(() {
                widget
                    .transmissionController
                    .updateEmergencyTreatmentPathology(
                  treatmentIndex,
                  pathology.pathologyId,
                  value ?? false,
                );
              });
            },
          ),
      ],
    );
  }

  Widget _buildDailyTreatmentAllergies(
    int treatmentIndex,
  ) {
    final draft =
        widget.transmissionController.formData;

    final allergies = draft.allergies
        .where(
          (allergy) =>
              allergy.allergen != null &&
              allergy.allergen!
                  .trim()
                  .isNotEmpty,
        )
        .toList();

    if (allergies.isEmpty) {
      return const SizedBox.shrink();
    }

    final treatment =
        draft.dailyTreatments[
          treatmentIndex
        ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Ce traitement est-il lié à une ou plusieurs allergies renseignées ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        for (final allergy in allergies)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity.leading,
            title: Text(
              allergy.allergen!.trim(),
            ),
            value: treatment
                .relatedAllergyIds
                .contains(
              allergy.allergyId,
            ),
            onChanged: (value) {
              setState(() {
                widget
                    .transmissionController
                    .updateDailyTreatmentAllergy(
                  treatmentIndex,
                  allergy.allergyId,
                  value ?? false,
                );
              });
            },
          ),
      ],
    );
  }

  Widget _buildEmergencyTreatmentAllergies(
    int treatmentIndex,
  ) {
    final draft =
        widget.transmissionController.formData;

    final allergies = draft.allergies
        .where(
          (allergy) =>
              allergy.allergen != null &&
              allergy.allergen!
                  .trim()
                  .isNotEmpty,
        )
        .toList();

    if (allergies.isEmpty) {
      return const SizedBox.shrink();
    }

    final treatment =
        draft.emergencyTreatments[
          treatmentIndex
        ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Ce traitement est-il lié à une ou plusieurs allergies renseignées ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        for (final allergy in allergies)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity.leading,
            title: Text(
              allergy.allergen!.trim(),
            ),
            value: treatment
                .relatedAllergyIds
                .contains(
              allergy.allergyId,
            ),
            onChanged: (value) {
              setState(() {
                widget
                    .transmissionController
                    .updateEmergencyTreatmentAllergy(
                  treatmentIndex,
                  allergy.allergyId,
                  value ?? false,
                );
              });
            },
          ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final draft =
        widget.transmissionController.formData;

    final dailyTreatments =
        draft.dailyTreatments;

    final discontinuedTreatments =
        draft.discontinuedTreatments;

    final emergencyTreatments =
        draft.emergencyTreatments;

    final allergies =
        draft.allergies;

    final medicalDevices =
        draft.medicalDevices;

    return QuestionnairePage(
      title: "",
      subtitle:
          "Quels sont les traitements actuellement prescrits à votre enfant ?",
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Traitements réguliers",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SkYesNoField(
            label:
                "En dehors des traitements ponctuels (antibiotiques, Doliprane...), votre enfant suit-il un ou plusieurs traitements quotidiens prescrits ?",
            value:
                _hasDailyTreatments,
            onChanged:
                _updateHasDailyTreatments,
          ),

          if (_hasDailyTreatments ==
              true) ...[
            const SizedBox(
              height: 28,
            ),

            for (
              int index = 0;
              index <
                  dailyTreatments.length;
              index++
            ) ...[
              Text(
                "Traitement quotidien n°${index + 1}",
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SkTextField(
                label:
                    "Nom du traitement",
                controller:
                    _controllers.of(
                  'dailyTreatment_${index}_name',
                  dailyTreatments[
                                  index]
                              .medicationName ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateDailyTreatmentName(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label: "Posologie",
                controller:
                    _controllers.of(
                  'dailyTreatment_${index}_dosage',
                  dailyTreatments[
                                  index]
                              .dosage ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateDailyTreatmentDosage(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label:
                    "À quelle(s) heure(s) est-il habituellement administré ?",
                controller:
                    _controllers.of(
                  'dailyTreatment_${index}_times',
                  dailyTreatments[
                                  index]
                              .administrationTimes ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateDailyTreatmentTimes(
                    index,
                    value,
                  );
                },
              ),

              _buildDailyTreatmentPathologies(
                index,
              ),

              _buildDailyTreatmentAllergies(
                index,
              ),

              if (dailyTreatments
                      .length >
                  1) ...[
                const SizedBox(
                  height: 12,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerRight,
                  child:
                      TextButton.icon(
                    onPressed: () =>
                        _removeDailyTreatment(
                      index,
                    ),
                    icon: const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label:
                        const Text(
                      "Supprimer",
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 28,
              ),
            ],

            OutlinedButton.icon(
              onPressed:
                  _addDailyTreatment,
              icon:
                  const Icon(
                Icons.add,
              ),
              label: const Text(
                "Ajouter un traitement quotidien",
              ),
            ),
          ],

          const SizedBox(
            height: 40,
          ),

          const Divider(),

          const SizedBox(
            height: 30,
          ),

          const Text(
            "Traitements arrêtés",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SkYesNoField(
            label:
                "Votre enfant a-t-il arrêté un traitement récemment ?",
            value:
                _hasDiscontinuedTreatments,
            onChanged:
                _updateHasDiscontinuedTreatments,
          ),

          if (_hasDiscontinuedTreatments ==
              true) ...[
            const SizedBox(
              height: 28,
            ),

            for (
              int index = 0;
              index <
                  discontinuedTreatments
                      .length;
              index++
            ) ...[
              Text(
                "Traitement arrêté n°${index + 1}",
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SkTextField(
                label:
                    "Nom du traitement",
                controller:
                    _controllers.of(
                  'discontinuedTreatment_${index}_name',
                  discontinuedTreatments[
                                  index]
                              .medicationName ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateDiscontinuedTreatmentName(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label:
                    "Date d’arrêt approximative (mois/année suffit)",
                controller:
                    _controllers.of(
                  'discontinuedTreatment_${index}_stopDate',
                  discontinuedTreatments[
                                  index]
                              .approximateStopDate ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateDiscontinuedTreatmentStopDate(
                    index,
                    value,
                  );
                },
              ),

              if (discontinuedTreatments
                      .length >
                  1) ...[
                const SizedBox(
                  height: 12,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerRight,
                  child:
                      TextButton.icon(
                    onPressed: () =>
                        _removeDiscontinuedTreatment(
                      index,
                    ),
                    icon: const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label:
                        const Text(
                      "Supprimer",
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 28,
              ),
            ],

            OutlinedButton.icon(
              onPressed:
                  _addDiscontinuedTreatment,
              icon:
                  const Icon(
                Icons.add,
              ),
              label: const Text(
                "Ajouter un traitement arrêté",
              ),
            ),
          ],

          const SizedBox(
            height: 40,
          ),

          const Divider(),

          const SizedBox(
            height: 30,
          ),

          const Text(
            "Traitements d’urgence",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SkYesNoField(
            label:
                "Votre enfant dispose-t-il d’un ou plusieurs traitements d’urgence prescrits ?",
            value:
                _hasEmergencyTreatments,
            onChanged:
                _updateHasEmergencyTreatments,
          ),

          if (_hasEmergencyTreatments ==
              true) ...[
            const SizedBox(
              height: 28,
            ),

            for (
              int index = 0;
              index <
                  emergencyTreatments
                      .length;
              index++
            ) ...[
              Text(
                "Traitement d’urgence n°${index + 1}",
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SkTextField(
                label:
                    "Nom du traitement",
                controller:
                    _controllers.of(
                  'emergencyTreatment_${index}_name',
                  emergencyTreatments[
                                  index]
                              .medicationName ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateEmergencyTreatmentName(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label:
                    "Dans quelle situation doit-il être administré ?",
                controller:
                    _controllers.of(
                  'emergencyTreatment_${index}_condition',
                  emergencyTreatments[
                                  index]
                              .administrationCondition ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateEmergencyTreatmentCondition(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label: "Posologie",
                controller:
                    _controllers.of(
                  'emergencyTreatment_${index}_dosage',
                  emergencyTreatments[
                                  index]
                              .dosage ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateEmergencyTreatmentDosage(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label:
                    "Mode d’administration",
                controller:
                    _controllers.of(
                  'emergencyTreatment_${index}_method',
                  emergencyTreatments[
                                  index]
                              .administrationMethod ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateEmergencyTreatmentMethod(
                    index,
                    value,
                  );
                },
              ),

              _buildEmergencyTreatmentPathologies(
                index,
              ),

              _buildEmergencyTreatmentAllergies(
                index,
              ),

              if (emergencyTreatments
                      .length >
                  1) ...[
                const SizedBox(
                  height: 12,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerRight,
                  child:
                      TextButton.icon(
                    onPressed: () =>
                        _removeEmergencyTreatment(
                      index,
                    ),
                    icon: const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label:
                        const Text(
                      "Supprimer",
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 28,
              ),
            ],

            OutlinedButton.icon(
              onPressed:
                  _addEmergencyTreatment,
              icon:
                  const Icon(
                Icons.add,
              ),
              label: const Text(
                "Ajouter un traitement d’urgence",
              ),
            ),
          ],

          const SizedBox(
            height: 40,
          ),

          const Divider(),

          const SizedBox(
            height: 30,
          ),

          const Text(
            "Allergies",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            "Renseignez ici le traitement associé à chaque allergie déjà déclarée. "
            "Pour ajouter ou modifier une allergie, revenez à l’étape « Santé de votre enfant ».",
          ),

          if (allergies.isEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            const Text(
              "Aucune allergie déclarée pour le moment.",
            ),
          ],

          if (allergies.isNotEmpty) ...[
            const SizedBox(
              height: 28,
            ),

            for (
              int index = 0;
              index <
                  allergies.length;
              index++
            ) ...[
              Text(
                allergies[index]
                            .allergen !=
                        null &&
                        allergies[index]
                            .allergen!
                            .trim()
                            .isNotEmpty
                    ? allergies[index]
                        .allergen!
                        .trim()
                    : "Allergie n°${index + 1}",
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SkYesNoField(
                label:
                    "Votre enfant suit-il un traitement quotidien pour cette allergie ?",
                value:
                    allergies[index]
                        .hasDailyTreatment,
                onChanged: (value) {
                  _updateAllergyHasDailyTreatment(
                    index,
                    value,
                  );
                },
              ),

              if (allergies[index]
                      .hasDailyTreatment ==
                  true) ...[
                const SizedBox(
                  height: 20,
                ),

                SkTextField(
                  label:
                      "Nom du traitement quotidien",
                  controller:
                      _controllers.of(
                    '${allergies[index].allergyId}_dailyTreatmentName',
                    allergies[index]
                                .dailyTreatmentName ??
                            '',
                  ),
                  onChanged:
                      (value) {
                    widget
                        .transmissionController
                        .updateAllergyDailyTreatmentName(
                      index,
                      value,
                    );
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                SkTextField(
                  label:
                      "Posologie",
                  controller:
                      _controllers.of(
                    '${allergies[index].allergyId}_dailyTreatmentDosage',
                    allergies[index]
                                .dailyTreatmentDosage ??
                            '',
                  ),
                  onChanged:
                      (value) {
                    widget
                        .transmissionController
                        .updateAllergyDailyTreatmentDosage(
                      index,
                      value,
                    );
                  },
                ),
              ],

              const SizedBox(
                height: 24,
              ),

              SkYesNoField(
                label:
                    "Votre enfant dispose-t-il d’un traitement d’urgence pour cette allergie ?",
                value:
                    allergies[index]
                        .hasEmergencyTreatment,
                onChanged: (value) {
                  _updateAllergyHasEmergencyTreatment(
                    index,
                    value,
                  );
                },
              ),

              if (allergies[index]
                      .hasEmergencyTreatment ==
                  true) ...[
                const SizedBox(
                  height: 20,
                ),

                SkTextField(
                  label:
                      "Nom du traitement d’urgence",
                  controller:
                      _controllers.of(
                    '${allergies[index].allergyId}_emergencyTreatmentName',
                    allergies[index]
                                .emergencyTreatmentName ??
                            '',
                  ),
                  onChanged:
                      (value) {
                    widget
                        .transmissionController
                        .updateAllergyEmergencyTreatmentName(
                      index,
                      value,
                    );
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                SkTextField(
                  label:
                      "Posologie",
                  controller:
                      _controllers.of(
                    '${allergies[index].allergyId}_emergencyTreatmentDosage',
                    allergies[index]
                                .emergencyTreatmentDosage ??
                            '',
                  ),
                  onChanged:
                      (value) {
                    widget
                        .transmissionController
                        .updateAllergyEmergencyTreatmentDosage(
                      index,
                      value,
                    );
                  },
                ),
              ],

              const SizedBox(
                height: 28,
              ),
            ],
          ],

          const SizedBox(
            height: 40,
          ),

          const Divider(),

          const SizedBox(
            height: 30,
          ),

          const Text(
            "Dispositifs médicaux",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SkYesNoField(
            label:
                "Votre enfant utilise-t-il un ou plusieurs dispositifs médicaux ?",
            value:
                _hasMedicalDevices,
            onChanged:
                _updateHasMedicalDevices,
          ),

          if (_hasMedicalDevices ==
              true) ...[
            const SizedBox(
              height: 28,
            ),

            for (
              int index = 0;
              index <
                  medicalDevices.length;
              index++
            ) ...[
              Text(
                "Dispositif n°${index + 1}",
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SkTextField(
                label:
                    "Nom du dispositif",
                controller:
                    _controllers.of(
                  'medicalDevice_${index}_name',
                  medicalDevices[
                                  index]
                              .deviceName ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateMedicalDeviceName(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SkTextField(
                label:
                    "À quoi sert-il ?",
                controller:
                    _controllers.of(
                  'medicalDevice_${index}_use',
                  medicalDevices[
                                  index]
                              .mainUse ??
                          '',
                ),
                onChanged: (value) {
                  widget
                      .transmissionController
                      .updateMedicalDeviceUse(
                    index,
                    value,
                  );
                },
              ),

              if (medicalDevices
                      .length >
                  1) ...[
                const SizedBox(
                  height: 12,
                ),

                Align(
                  alignment:
                      Alignment
                          .centerRight,
                  child:
                      TextButton.icon(
                    onPressed: () =>
                        _removeMedicalDevice(
                      index,
                    ),
                    icon: const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label:
                        const Text(
                      "Supprimer",
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 28,
              ),
            ],

            OutlinedButton.icon(
              onPressed:
                  _addMedicalDevice,
              icon:
                  const Icon(
                Icons.add,
              ),
              label:
                  const Text(
                "Ajouter un dispositif",
              ),
            ),
          ],

          const SizedBox(
            height: 30,
          ),

          FilledButton(
            onPressed:
                _continue,
            child:
                const Text(
              "Continuer",
            ),
          ),
        ],
      ),
    );
  }
}