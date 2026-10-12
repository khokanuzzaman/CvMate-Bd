import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/print_menu_button.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/tailoring_export.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_page_scaffold.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_result_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 3/3 — the tailored CV: summary, emphasized skills and the before/after
/// bullet rewrites (all editable), then Cover letter and Save & export.
class TailorResultPage extends ConsumerWidget {
  const TailorResultPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tailoringControllerProvider);
    final result = state.result;
    final matchPercent = ref.watch(tailoredMatchPercentProvider);

    return TailorPageScaffold(
      page: TailoringPage.result,
      title: AppStrings.tailorResultTitle,
      onBack: onBack,
      headerTrailing: PrintMenuButton(
        tooltip: AppStrings.tailorMoreOptions,
        printLabel: AppStrings.tailorPrint,
        enabled: result != null && !state.isBusy,
        onPrint: () => printTailored(ref, context),
      ),
      stepsTrailing: matchPercent == null
          ? null
          : _MatchBadge(percent: matchPercent),
      body: result == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s16,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (result.tailoredSummary.trim().isNotEmpty) ...[
                    TailoredSummaryCard(summary: result.tailoredSummary),
                    const SizedBox(height: AppSpacing.s14),
                  ],
                  if (result.emphasizedSkills.isNotEmpty) ...[
                    TailoredSkillsCard(
                      skills: result.emphasizedSkills,
                      sourceCv: state.selectedCv,
                    ),
                    const SizedBox(height: AppSpacing.s14),
                  ],
                  if (result.rewrittenBullets.isNotEmpty)
                    TailoredBulletsCard(bullets: result.rewrittenBullets),
                ],
              ),
            ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.tailorCoverLetter,
                    leadingIcon: Icons.mail_outline_rounded,
                    onPressed: state.isBusy
                        ? null
                        : () async {
                            await ref
                                .read(tailoringFlowProvider.notifier)
                                .prepareCoverLetter();
                            if (context.mounted) {
                              context.push(RouteNames.coverLetterPath);
                            }
                          },
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: PrimaryButton(
                    label: AppStrings.tailorSaveExport,
                    leadingIcon: Icons.download_rounded,
                    onPressed: state.isBusy
                        ? null
                        : () => saveAndExportTailored(ref, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            Text(
              AppStrings.tailorSavesAsCopy,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Match 89%" pill, from the real keyword coverage of the tailored CV.
class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.successText,
          ),
          const SizedBox(width: AppSpacing.s6),
          Text(
            AppStrings.tailorMatchBadge(percent),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.successText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
