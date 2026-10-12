import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_question_card.dart';
import 'package:flutter/material.dart';

/// The generated set: copy / save actions, then the questions by category.
class InterviewResultsCard extends StatelessWidget {
  const InterviewResultsCard({
    super.key,
    required this.state,
    required this.onCopyAllQuestions,
    required this.onCopyAllAnswers,
    required this.onSaveSession,
    required this.onStartOver,
    required this.onCopyQuestion,
    required this.onCopyAnswer,
    required this.onToggleFavorite,
    required this.onAnswerChanged,
  });

  final InterviewPrepState state;
  final VoidCallback onCopyAllQuestions;
  final VoidCallback onCopyAllAnswers;
  final VoidCallback onSaveSession;
  final VoidCallback onStartOver;
  final ValueChanged<String> onCopyQuestion;
  final ValueChanged<String> onCopyAnswer;
  final ValueChanged<String> onToggleFavorite;
  final void Function(String questionId, String value) onAnswerChanged;

  List<InterviewPrepQuestion> _in(InterviewQuestionCategory category) => [
    for (final question in state.questions)
      if (question.category == category) question,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.interviewResultsTitle, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.s6),
        Text(
          AppStrings.interviewResultsBody,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s14),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: AppStrings.interviewCopyAllQuestions,
                leadingIcon: Icons.list_alt_outlined,
                outlineColor: AppColors.lineStrong,
                onPressed: onCopyAllQuestions,
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: SecondaryButton(
                label: AppStrings.interviewCopyAllAnswers,
                leadingIcon: Icons.copy_all_outlined,
                outlineColor: AppColors.lineStrong,
                onPressed: onCopyAllAnswers,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: state.isSavingSession
                    ? AppStrings.interviewSaving
                    : AppStrings.interviewSaveSession,
                leadingIcon: Icons.save_outlined,
                onPressed: state.isSavingSession ? null : onSaveSession,
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: SecondaryButton(
                label: AppStrings.commonStartOver,
                leadingIcon: Icons.refresh_rounded,
                onPressed: onStartOver,
              ),
            ),
          ],
        ),
        for (final category in InterviewQuestionCategory.values)
          if (_in(category).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s20),
            SectionLabel(category.label),
            const SizedBox(height: AppSpacing.s10),
            for (final question in _in(category)) ...[
              InterviewQuestionCard(
                key: ValueKey(question.id),
                question: question,
                onCopyQuestion: () => onCopyQuestion(question.id),
                onCopyAnswer: () => onCopyAnswer(question.id),
                onToggleFavorite: () => onToggleFavorite(question.id),
                onAnswerChanged: (value) => onAnswerChanged(question.id, value),
              ),
              const SizedBox(height: AppSpacing.s10),
            ],
          ],
      ],
    );
  }
}
