import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/presentation/utils/star_answer.dart';
import 'package:flutter/material.dart';

/// One interview question. Collapsed it is a single tappable row; expanded it
/// shows the suggested answer (STAR labels in bold when the answer has them)
/// with Practice and the Bangla/English switch.
class InterviewQuestionCard extends StatelessWidget {
  const InterviewQuestionCard({
    super.key,
    required this.question,
    required this.number,
    required this.expanded,
    required this.showBanglaAction,
    required this.busy,
    required this.onTap,
    required this.onPractice,
    required this.onToggleLanguage,
  });

  final InterviewPrepQuestion question;

  /// 1-based position in the whole set (stays the same while filtering).
  final int number;
  final bool expanded;

  /// True while the questions are in English, so the action offers Bangla.
  final bool showBanglaAction;

  /// A regeneration is running; the language switch is disabled.
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onPractice;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final tag = AppStrings.interviewQuestionLabel(
      question.category.shortLabel,
      number,
    ).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: expanded ? AppColors.primary : AppColors.line,
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: expanded ? AppShadows.soft : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: expanded ? null : onTap,
          borderRadius: AppRadii.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: expanded
                ? _Expanded(
                    question: question,
                    tag: tag,
                    showBanglaAction: showBanglaAction,
                    busy: busy,
                    onPractice: onPractice,
                    onToggleLanguage: onToggleLanguage,
                  )
                : _Collapsed(question: question, tag: tag),
          ),
        ),
      ),
    );
  }
}

class _Collapsed extends StatelessWidget {
  const _Collapsed({required this.question, required this.tag});

  final InterviewPrepQuestion question;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: AppTextStyles.label.copyWith(color: AppColors.muted2),
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                question.question,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted2),
      ],
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({
    required this.question,
    required this.tag,
    required this.showBanglaAction,
    required this.busy,
    required this.onPractice,
    required this.onToggleLanguage,
  });

  final InterviewPrepQuestion question;
  final String tag;
  final bool showBanglaAction;
  final bool busy;
  final VoidCallback onPractice;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final answerLabel =
        AppStrings.interviewSuggestedAnswer.toUpperCase() +
        (isStarAnswer(question.answerText)
            ? AppStrings.interviewStarSuffix
            : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tag,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
            if (question.isFavorite)
              const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          question.question,
          style: AppTextStyles.itemTitle.copyWith(fontSize: 17),
        ),
        const SizedBox(height: AppSpacing.s14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.input + 2),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(answerLabel, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.s8),
              _AnswerText(answer: question.answerText),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: AppStrings.interviewPractice,
                background: AppColors.primarySoft,
                foreground: AppColors.primary,
                onTap: onPractice,
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: _ActionButton(
                label: showBanglaAction
                    ? AppStrings.interviewShowInBangla
                    : AppStrings.interviewShowInEnglish,
                background: AppColors.accent,
                foreground: AppColors.onAccent,
                onTap: busy ? null : onToggleLanguage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerText extends StatelessWidget {
  const _AnswerText({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final segments = parseStarAnswer(answer);
    if (segments.isEmpty) {
      return Text(
        AppStrings.interviewNoAnswer,
        style: AppTextStyles.body.copyWith(color: AppColors.muted),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          for (final (index, segment) in segments.indexed) ...[
            if (index > 0) const TextSpan(text: ' '),
            if (segment.label != null)
              TextSpan(
                text: '${segment.label} ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            TextSpan(text: segment.text),
          ],
        ],
      ),
      style: AppTextStyles.body.copyWith(color: AppColors.ink),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: background,
        borderRadius: AppRadii.buttonRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.buttonRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: foreground,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
