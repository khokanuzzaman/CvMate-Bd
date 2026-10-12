import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_display.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2/3 — the keyword match: score ring with the real coverage %, matched
/// and missing keyword chips, and the "tailor my CV" action.
class TailorMatchPage extends ConsumerWidget {
  const TailorMatchPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tailoringControllerProvider);
    final report = state.matchReport;
    final tailoring = state.stage == TailoringStage.tailoring;

    return TailorPageScaffold(
      page: TailoringPage.match,
      title: AppStrings.tailorMatchTitle,
      onBack: onBack,
      body: report == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s16,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: _MatchBody(report: report),
            ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s16,
        ),
        child: PrimaryButton(
          label: tailoring
              ? AppStrings.tailorTailoring
              : AppStrings.tailorTailorMyCv,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: report == null || state.isBusy
              ? null
              : () => ref.read(tailoringFlowProvider.notifier).tailor(),
        ),
      ),
    );
  }
}

class _MatchBody extends StatelessWidget {
  const _MatchBody({required this.report});

  final AtsJobMatchReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreCard(
          percent: report.matchPercentage,
          hasMissing: report.missingKeywords.isNotEmpty,
        ),
        if (report.matchedKeywords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s18),
          _KeywordGroup(
            label: AppStrings.tailorMatched,
            keywords: report.matchedKeywords,
            variant: AppChipVariant.matched,
            labelColor: AppColors.successText,
            pillColor: AppColors.successSoft,
          ),
        ],
        if (report.missingKeywords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s18),
          _KeywordGroup(
            label: AppStrings.tailorMissing,
            keywords: report.missingKeywords,
            variant: AppChipVariant.missing,
            labelColor: AppColors.accentInk,
            pillColor: AppColors.accentSoft,
          ),
        ],
        const SizedBox(height: AppSpacing.s18),
        const _TruthfulNote(),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.percent, required this.hasMissing});

  final int percent;
  final bool hasMissing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Row(
        children: [
          ScoreRing(percent: percent, size: 92),
          const SizedBox(width: AppSpacing.s18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(matchHeadline(percent), style: AppTextStyles.appBar),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  matchBody(hasMissingKeywords: hasMissing),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordGroup extends StatelessWidget {
  const _KeywordGroup({
    required this.label,
    required this.keywords,
    required this.variant,
    required this.labelColor,
    required this.pillColor,
  });

  final String label;
  final List<String> keywords;
  final AppChipVariant variant;
  final Color labelColor;
  final Color pillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.label.copyWith(color: labelColor),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s10,
                vertical: AppSpacing.s4,
              ),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: AppRadii.pillRadius,
              ),
              child: Text(
                '${keywords.length}',
                style: AppTextStyles.label.copyWith(color: labelColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s10),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final keyword in keywords)
              AppChip(label: keyword, variant: variant),
          ],
        ),
      ],
    );
  }
}

class _TruthfulNote extends StatelessWidget {
  const _TruthfulNote();

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body.copyWith(color: AppColors.primaryDeep);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  const TextSpan(text: AppStrings.tailorTruthfulPrefix),
                  TextSpan(
                    text: AppStrings.tailorTruthfulEmphasis,
                    style: base.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: AppStrings.tailorTruthfulSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
