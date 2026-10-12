import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_context_chip.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_question_card.dart';
import 'package:flutter/material.dart';

/// The generated set: context chip, category filters and the question cards.
/// Which filter and which card are open is local UI state.
class InterviewQuestionsView extends StatefulWidget {
  const InterviewQuestionsView({
    super.key,
    required this.contextLabel,
    required this.questions,
    required this.showBanglaAction,
    required this.busy,
    required this.errorMessage,
    required this.onPractice,
    required this.onToggleLanguage,
  });

  final String contextLabel;
  final List<InterviewPrepQuestion> questions;
  final bool showBanglaAction;
  final bool busy;
  final String? errorMessage;
  final ValueChanged<InterviewPrepQuestion> onPractice;
  final VoidCallback onToggleLanguage;

  @override
  State<InterviewQuestionsView> createState() => _InterviewQuestionsViewState();
}

class _InterviewQuestionsViewState extends State<InterviewQuestionsView> {
  InterviewQuestionCategory? _filter;
  String? _expandedId;

  /// Categories in the order they first appear in the set.
  List<InterviewQuestionCategory> get _categories => [
    ...{for (final question in widget.questions) question.category},
  ];

  List<InterviewPrepQuestion> get _visible => [
    for (final question in widget.questions)
      if (_filter == null || question.category == _filter) question,
  ];

  void _select(InterviewQuestionCategory? filter) {
    setState(() {
      _filter = filter;
      _expandedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A regenerated set can drop the selected category.
    if (_filter != null && !_categories.contains(_filter)) {
      _filter = null;
    }
    final visible = _visible;
    final expandedId = visible.any((item) => item.id == _expandedId)
        ? _expandedId
        : (visible.isEmpty ? null : visible.first.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      children: [
        InterviewContextChip(label: widget.contextLabel),
        const SizedBox(height: AppSpacing.s12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppChip(
                label: AppStrings.interviewFilterAll(widget.questions.length),
                variant: _filter == null
                    ? AppChipVariant.selected
                    : AppChipVariant.neutral,
                onTap: () => _select(null),
              ),
              for (final category in _categories) ...[
                const SizedBox(width: AppSpacing.s8),
                AppChip(
                  label: category.shortLabel,
                  variant: _filter == category
                      ? AppChipVariant.selected
                      : AppChipVariant.neutral,
                  onTap: () => _select(category),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s14),
        if (widget.errorMessage != null) ...[
          Text(
            widget.errorMessage!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        for (final question in visible) ...[
          InterviewQuestionCard(
            question: question,
            number: widget.questions.indexOf(question) + 1,
            expanded: question.id == expandedId,
            showBanglaAction: widget.showBanglaAction,
            busy: widget.busy,
            onTap: () => setState(() => _expandedId = question.id),
            onPractice: () => widget.onPractice(question),
            onToggleLanguage: widget.onToggleLanguage,
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        Text(
          AppStrings.interviewTruthful,
          style: AppTextStyles.hint,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
