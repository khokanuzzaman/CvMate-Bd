import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

class AtsSeverityChip extends StatelessWidget {
  const AtsSeverityChip({super.key, required this.severity});

  final AtsSuggestionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForSeverity(Theme.of(context).colorScheme, severity);
    return Chip(
      label: Text(_label(severity)),
      backgroundColor: colors.$1,
      labelStyle: TextStyle(color: colors.$2),
      side: BorderSide(color: colors.$2.withValues(alpha: 0.2)),
      visualDensity: VisualDensity.compact,
    );
  }

  (Color, Color) _colorsForSeverity(
    ColorScheme scheme,
    AtsSuggestionSeverity severity,
  ) {
    return switch (severity) {
      AtsSuggestionSeverity.high => (
        scheme.error.withValues(alpha: 0.12),
        scheme.error,
      ),
      AtsSuggestionSeverity.medium => (
        const Color(0xFFFFF2D6),
        const Color(0xFF8C5A00),
      ),
      AtsSuggestionSeverity.low => (
        scheme.primary.withValues(alpha: 0.12),
        scheme.primary,
      ),
    };
  }

  String _label(AtsSuggestionSeverity severity) => switch (severity) {
    AtsSuggestionSeverity.high => 'High',
    AtsSuggestionSeverity.medium => 'Medium',
    AtsSuggestionSeverity.low => 'Low',
  };
}
