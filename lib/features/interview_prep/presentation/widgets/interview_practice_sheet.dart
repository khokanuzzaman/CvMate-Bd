import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the practice sheet for [questionId]: why it matters, the answer tip
/// and an editable answer (saved with the session), plus copy and favorite.
Future<void> showInterviewPracticeSheet(
  BuildContext context, {
  required String questionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => _PracticeSheet(questionId: questionId),
  );
}

class _PracticeSheet extends ConsumerStatefulWidget {
  const _PracticeSheet({required this.questionId});

  final String questionId;

  @override
  ConsumerState<_PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends ConsumerState<_PracticeSheet> {
  late final TextEditingController _answer;

  InterviewPrepQuestion? _find() {
    for (final question
        in ref.read(interviewPrepControllerProvider).questions) {
      if (question.id == widget.questionId) {
        return question;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _answer = TextEditingController(text: _find()?.answerText ?? '');
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _show(Future<String?> action) async {
    final message = await action;
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the favorite toggle reflects immediately.
    ref.watch(interviewPrepControllerProvider);
    final question = _find();
    if (question == null) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(interviewPrepControllerProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.s16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.interviewPracticeTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.s10),
            Text(
              question.question,
              style: AppTextStyles.itemTitle.copyWith(fontSize: 17),
            ),
            if (question.whyItMatters.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                AppStrings.interviewWhyItMatters.toUpperCase(),
                style: AppTextStyles.label,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                question.whyItMatters,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            ],
            if (question.answerTip.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                AppStrings.interviewAnswerTip(question.answerTip),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            AppTextArea(
              label: AppStrings.interviewYourAnswer,
              controller: _answer,
              minLines: 6,
              maxLines: 10,
              onChanged: (value) => controller.updateAnswer(question.id, value),
            ),
            const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.interviewCopyQuestion,
                    onPressed: () =>
                        _show(controller.copyQuestion(question.id)),
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.interviewCopyAnswer,
                    onPressed: () => _show(controller.copyAnswer(question.id)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            PrimaryButton(
              label: question.isFavorite
                  ? AppStrings.interviewUnfavorite
                  : AppStrings.interviewFavorite,
              leadingIcon: question.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              onPressed: () => controller.toggleFavorite(question.id),
            ),
          ],
        ),
      ),
    );
  }
}
