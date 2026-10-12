import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The ⋮ overflow menu used in flow top bars; currently one item, Print.
/// [tooltip] labels the button and [printLabel] the menu item.
class PrintMenuButton extends StatelessWidget {
  const PrintMenuButton({
    super.key,
    required this.tooltip,
    required this.printLabel,
    required this.enabled,
    required this.onPrint,
  });

  final String tooltip;
  final String printLabel;
  final bool enabled;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.inputRadius,
        side: BorderSide(color: AppColors.line),
      ),
      onSelected: (_) => onPrint(),
      itemBuilder: (context) => [
        PopupMenuItem<bool>(
          value: true,
          enabled: enabled,
          child: Row(
            children: [
              const Icon(
                Icons.print_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(printLabel, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}
