import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:flutter/material.dart';

/// One question: tap the header to reveal the tip, an editable sample answer and
/// the copy / favorite actions.
class InterviewQuestionCard extends StatefulWidget {
  const InterviewQuestionCard({
    super.key,
    required this.question,
    required this.onCopyQuestion,
    required this.onCopyAnswer,
    required this.onToggleFavorite,
    required this.onAnswerChanged,
  });

  final InterviewPrepQuestion question;
  final VoidCallback onCopyQuestion;
  final VoidCallback onCopyAnswer;
  final VoidCallback onToggleFavorite;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<InterviewQuestionCard> createState() => _InterviewQuestionCardState();
}

class _InterviewQuestionCardState extends State<InterviewQuestionCard> {
  late final TextEditingController _answer;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _answer = TextEditingController(text: widget.question.answerText)
      ..addListener(() => widget.onAnswerChanged(_answer.text));
  }

  @override
  void didUpdateWidget(covariant InterviewQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.question.answerText;
    if (_answer.text != next) {
      _answer.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: _expanded
                ? AppStrings.interviewHideAnswer
                : AppStrings.interviewShowAnswer,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.cardRadius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (question.isFavorite) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s6),
                              ],
                              Expanded(
                                child: Text(
                                  question.question,
                                  style: AppTextStyles.itemTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            question.whyItMatters,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.interviewAnswerTip(question.answerTip),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AppTextArea(
                    controller: _answer,
                    label: AppStrings.interviewAnswerLabel,
                    minLines: 4,
                    maxLines: 8,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      SecondaryButton(
                        label: AppStrings.interviewCopyQuestion,
                        leadingIcon: Icons.copy_outlined,
                        expanded: false,
                        outlineColor: AppColors.lineStrong,
                        onPressed: widget.onCopyQuestion,
                      ),
                      SecondaryButton(
                        label: AppStrings.interviewCopyAnswer,
                        leadingIcon: Icons.copy_all_outlined,
                        expanded: false,
                        outlineColor: AppColors.lineStrong,
                        onPressed: widget.onCopyAnswer,
                      ),
                      SecondaryButton(
                        label: question.isFavorite
                            ? AppStrings.interviewUnfavorite
                            : AppStrings.interviewFavorite,
                        leadingIcon: question.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        expanded: false,
                        onPressed: widget.onToggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
