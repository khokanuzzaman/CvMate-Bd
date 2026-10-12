import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// One entry of an [OverflowMenuButton].
class OverflowMenuItem {
  const OverflowMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool enabled;
}

/// The ⋮ overflow menu used in flow top bars. [tooltip] labels the button.
class OverflowMenuButton extends StatelessWidget {
  const OverflowMenuButton({
    super.key,
    required this.tooltip,
    required this.items,
  });

  final String tooltip;
  final List<OverflowMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.inputRadius,
        side: BorderSide(color: AppColors.line),
      ),
      onSelected: (index) => items[index].onSelected(),
      itemBuilder: (context) => [
        for (final (index, item) in items.indexed)
          PopupMenuItem<int>(
            value: index,
            enabled: item.enabled,
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s12),
                // Flexible so a long label (or large text) wraps inside the
                // menu's width instead of overflowing.
                Flexible(child: Text(item.label, style: AppTextStyles.body)),
              ],
            ),
          ),
      ],
    );
  }
}
