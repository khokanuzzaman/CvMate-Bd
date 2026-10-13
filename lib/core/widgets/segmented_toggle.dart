import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/text_scale_clamp.dart';
import 'package:flutter/material.dart';

/// One choice in a [SegmentedToggle].
class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill-shaped segmented control: a white track with a `primary` selected
/// segment, equal-width segments, 48dp tall. (DESIGN_TOKENS.md → segmented)
///
/// At large system text the segments no longer fit side by side, so they stack
/// vertically (one per row, full width) instead of squeezing or overflowing.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  Widget _segment(SegmentedOption<T> option) => _Segment(
    label: option.label,
    selected: option.value == value,
    onTap: () => onChanged(option.value),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4 + 1),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input + 4),
        border: Border.all(color: AppColors.line),
      ),
      child: isLargeText(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final option in options) _segment(option)],
            )
          : Row(
              children: [
                for (final option in options) Expanded(child: _segment(option)),
              ],
            ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
