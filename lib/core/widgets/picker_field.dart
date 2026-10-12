import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A tappable field that shows a label and its current value (a date, a linked
/// item…) with a trailing icon, and an optional clear button. Looks like a text
/// field; [value] is shown muted while [hasValue] is false.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hasValue = true,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.onClear,
    this.clearTooltip,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool hasValue;
  final IconData icon;
  final VoidCallback? onClear;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.s6),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '$label, $value',
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadii.inputRadius,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s14,
                      vertical: AppSpacing.s10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadii.inputRadius,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: AppTextStyles.bodySm.copyWith(
                                color: hasValue
                                    ? AppColors.ink
                                    : AppColors.placeholder,
                              ),
                            ),
                          ),
                          Icon(icon, size: 20, color: AppColors.muted2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                tooltip: clearTooltip,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
          ],
        ),
      ],
    );
  }
}

/// One choice in [showOptionSheet].
class OptionItem {
  const OptionItem({required this.id, required this.title, this.subtitle});

  final String id;
  final String title;
  final String? subtitle;
}

/// Id returned by [showOptionSheet] when the "none" entry is chosen.
const String kNoOptionChoice = '';

/// Bottom sheet of [options]; resolves to the chosen id, [kNoOptionChoice] for
/// the optional [noneLabel] entry, or null when dismissed.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<OptionItem> options,
  required String? selectedId,
  String? noneLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.s16,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text(title, style: AppTextStyles.title),
            ),
            if (noneLabel != null)
              _OptionRow(
                title: noneLabel,
                selected: selectedId == null,
                onTap: () => Navigator.of(context).pop(kNoOptionChoice),
              ),
            for (final option in options)
              _OptionRow(
                title: option.title,
                subtitle: option.subtitle,
                selected: option.id == selectedId,
                onTap: () => Navigator.of(context).pop(option.id),
              ),
          ],
        ),
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.inputRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.itemTitle),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
