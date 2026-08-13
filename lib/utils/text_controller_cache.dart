import 'package:flutter/material.dart';

/// Reuses one [TextEditingController] per key across rebuilds instead of
/// creating a new one on every build() call.
///
/// Questionnaire pages with repeatable items (pathologies, allergies,
/// treatments, contacts...) used to build a fresh [TextEditingController]
/// inline for every field on every rebuild. That loses cursor position on
/// any unrelated rebuild, and can show stale text if the list is reordered
/// (e.g. removing an earlier item shifts the following ones up), since a
/// key stays tied to a position, not to a specific item.
class TextControllerCache {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController of(String key, String value) {
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: value),
    );

    if (controller.text != value) {
      controller.text = value;
    }

    return controller;
  }

  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
  }
}
