import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:flutter/material.dart';

/// A wrapping row of single-choice chips: the selected one is filled `primary`,
/// the others neutral. Each chip is a 48dp-high touch target.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final String Function(T option) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final option in options)
          AppChip(
            label: labelOf(option),
            variant: option == value
                ? AppChipVariant.selected
                : AppChipVariant.neutral,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}
