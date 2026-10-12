import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_quick_prompts.dart';
import 'package:flutter/material.dart';

/// Built-in practice questions, each with a tip and a copy button.
class InterviewQuickPracticeCard extends StatelessWidget {
  const InterviewQuickPracticeCard({
    super.key,
    required this.prompts,
    required this.onCopy,
  });

  final List<QuickPracticePrompt> prompts;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.interviewQuickTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.interviewQuickBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final (index, prompt) in prompts.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.question,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            prompt.tip,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onCopy(prompt.question),
                    tooltip: AppStrings.interviewCopyQuestion,
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const Icon(
                      Icons.copy_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
