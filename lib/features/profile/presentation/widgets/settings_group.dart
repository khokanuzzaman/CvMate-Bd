import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// A white card of [SettingsRow]s separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.line),
            child,
          ],
        ],
      ),
    );
  }
}

/// One row: [label] (with an optional [subtitle]) and a [trailing] widget.
/// Tappable when [onTap] is set; [enabled] false mutes it. [destructive] paints
/// the label red (Log out).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  /// The "value ›" trailing used by navigation rows.
  static Widget value(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: AppTextStyles.body.copyWith(color: AppColors.muted)),
        const SizedBox(width: AppSpacing.s4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.danger
        : (enabled ? AppColors.ink : AppColors.muted2);

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (onTap == null || !enabled) {
      return Semantics(enabled: enabled, label: label, child: content);
    }
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
