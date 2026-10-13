import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/text_scale_clamp.dart';
import 'package:flutter/material.dart';

/// A secondary + primary button pair. Side by side normally (secondary left,
/// primary right); stacked vertically — primary on top — once the system text
/// is large, where two labels no longer fit on one line and would truncate.
class AdaptiveButtonRow extends StatelessWidget {
  const AdaptiveButtonRow({
    super.key,
    required this.secondary,
    required this.primary,
    this.secondaryFlex = 1,
    this.primaryFlex = 1,
  });

  final Widget secondary;
  final Widget primary;
  final int secondaryFlex;
  final int primaryFlex;

  @override
  Widget build(BuildContext context) {
    if (isLargeText(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: AppSpacing.s10),
          secondary,
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: secondaryFlex, child: secondary),
        const SizedBox(width: AppSpacing.s12),
        Expanded(flex: primaryFlex, child: primary),
      ],
    );
  }
}
