import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "AI actions left: N" from the AI server (cached offline). Takes no space
/// while the value is unknown.
class AiActionsLeftLabel extends ConsumerWidget {
  const AiActionsLeftLabel({super.key, this.center = false});

  final bool center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(aiEntitlementProvider).asData?.value;
    if (entitlement == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.s6),
        Text(
          entitlement.actionsLeftLabel,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
