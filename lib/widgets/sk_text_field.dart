import 'package:flutter/material.dart';

class SkTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  final int? maxLength;
  final String? helperText;

  /// Hauteur du champ en lignes. Reste à 1 par défaut : la quasi
  /// totalité des questions attend une réponse courte. Passe à 3 pour
  /// les rares champs où la consigne demande explicitement de décrire
  /// (section Repas : les signes qui alertent et la conduite à tenir).
  final int maxLines;

  const SkTextField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLength,
    this.helperText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}