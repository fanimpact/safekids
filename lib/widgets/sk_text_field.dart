import 'package:flutter/material.dart';

class SkTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  final int? maxLength;
  final String? helperText;

  const SkTextField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.maxLength,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}