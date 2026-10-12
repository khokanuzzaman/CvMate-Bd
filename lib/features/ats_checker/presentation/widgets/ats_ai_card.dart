import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:flutter/material.dart';

/// Optional AI improvement: pick summary or objective, generate an editable
/// suggestion, then apply or copy it.
class AtsAiCard extends StatelessWidget {
  const AtsAiCard({
    super.key,
    required this.state,
    required this.suggestionController,
    required this.onTargetChanged,
    required this.onGenerate,
    required this.onApply,
    required this.onCopy,
  });

  final AtsCheckerState state;
  final TextEditingController suggestionController;
  final ValueChanged<AtsAiTarget> onTargetChanged;
  final VoidCallback onGenerate;
  final VoidCallback onApply;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.atsAiTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.atsAiBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s14),
          SegmentedToggle<AtsAiTarget>(
            options: [
              for (final target in AtsAiTarget.values)
                SegmentedOption(value: target, label: target.label),
            ],
            value: state.aiTarget,
            onChanged: onTargetChanged,
          ),
          const SizedBox(height: AppSpacing.s14),
          SecondaryButton(
            label: state.isGeneratingAiSuggestion
                ? AppStrings.atsAiGenerating
                : AppStrings.atsAiImprove,
            leadingIcon: Icons.auto_awesome_outlined,
            onPressed: state.isGeneratingAiSuggestion ? null : onGenerate,
          ),
          if (state.hasAiSuggestion) ...[
            const SizedBox(height: AppSpacing.s14),
            AppTextArea(
              controller: suggestionController,
              label: AppStrings.atsAiSuggestionLabel,
              minLines: 5,
              maxLines: 8,
            ),
            const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: AppStrings.atsAiApply,
                    onPressed: onApply,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.atsAiCopy,
                    outlineColor: AppColors.lineStrong,
                    onPressed: onCopy,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
