import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Improve with AI" / "Generate with AI" pill. Opens the existing AI Improve
/// screen with [type] preselected, after saving the draft, and asks the builder
/// to re-read the draft when the user comes back (the AI screen can apply a
/// suggestion to it).
///
/// [solid] is the filled amber variant (`accent` / `onAccent`); otherwise the
/// soft `accentSoft` / `accentInk` pill. The tap target is 48dp high.
class AiActionPill extends ConsumerWidget {
  const AiActionPill({
    super.key,
    required this.type,
    required this.label,
    this.solid = false,
  });

  final AiImproveType type;
  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = solid ? AppColors.accent : AppColors.accentSoft;
    final foreground = solid ? AppColors.onAccent : AppColors.accentInk;
    final textStyle = (solid ? AppTextStyles.bodySm : AppTextStyles.caption)
        .copyWith(color: foreground, fontWeight: FontWeight.w700);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => _open(context, ref),
        borderRadius: AppRadii.pillRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: solid ? AppSpacing.s14 : AppSpacing.s10,
                vertical: solid ? AppSpacing.s8 : AppSpacing.s6,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.pillRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: solid ? 16 : 14,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.s6),
                  Text(label, style: textStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final builder = ref.read(cvBuilderControllerProvider.notifier);
    final aiImprove = ref.read(aiImproveControllerProvider.notifier);
    final refresh = ref.read(cvBuilderRefreshProvider.notifier);

    await builder.flushAutosave();
    if (!context.mounted) {
      return;
    }

    final error = ref.read(cvBuilderControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    aiImprove.selectImprovementType(type);
    await context.push(RouteNames.aiImprovePath);
    refresh.bump();
  }
}
