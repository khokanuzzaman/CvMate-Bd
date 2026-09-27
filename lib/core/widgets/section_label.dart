import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// UPPERCASE section label (muted, 11.5/700, letter-spacing .06em), with an
/// optional trailing widget such as a count pill. (DESIGN_TOKENS.md → SectionLabel)
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text.toUpperCase(), style: AppTextStyles.label),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s8),
          trailing!,
        ],
      ],
    );
  }
}
