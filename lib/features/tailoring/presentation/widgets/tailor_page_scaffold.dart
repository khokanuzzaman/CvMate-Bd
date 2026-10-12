import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/progress_bar.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:flutter/material.dart';

/// Shared chrome of the three tailoring pages: top bar with the "Step n/3"
/// pill, the segmented progress steps, a scrolling body and a pinned footer.
class TailorPageScaffold extends StatelessWidget {
  const TailorPageScaffold({
    super.key,
    required this.page,
    required this.title,
    required this.onBack,
    required this.body,
    required this.footer,
    this.headerTrailing,
    this.stepsTrailing,
  });

  final TailoringPage page;
  final String title;
  final VoidCallback onBack;
  final Widget body;
  final Widget footer;

  /// Extra widget at the end of the top bar (e.g. the ⋮ menu).
  final Widget? headerTrailing;

  /// Widget to the right of the segmented steps (e.g. the match badge).
  final Widget? stepsTrailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTopBar(
                      title: title,
                      onBack: onBack,
                      stepLabel: AppStrings.tailorStepPill(page.step),
                    ),
                  ),
                  ?headerTrailing,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedSteps(
                      totalSteps: TailoringPage.values.length,
                      completedSteps: page.step,
                    ),
                  ),
                  if (stepsTrailing != null) ...[
                    const SizedBox(width: AppSpacing.s10),
                    stepsTrailing!,
                  ],
                ],
              ),
            ),
            Expanded(child: body),
            footer,
          ],
        ),
      ),
    );
  }
}
