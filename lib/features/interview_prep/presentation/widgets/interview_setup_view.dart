import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/features/interview_prep/presentation/utils/interview_quick_prompts.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/cv_picker.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Before any questions exist: pick the CV and role, choose the interview type,
/// language and answer style, reopen a saved session, or rehearse the built-in
/// quick-practice questions.
class InterviewSetupView extends ConsumerStatefulWidget {
  const InterviewSetupView({
    super.key,
    required this.state,
    required this.onCreateCv,
    required this.onCopyQuickQuestion,
  });

  final InterviewPrepState state;
  final VoidCallback onCreateCv;
  final ValueChanged<String> onCopyQuickQuestion;

  @override
  ConsumerState<InterviewSetupView> createState() => _InterviewSetupViewState();
}

class _InterviewSetupViewState extends ConsumerState<InterviewSetupView> {
  late final TextEditingController _role;
  late final TextEditingController _company;
  late final TextEditingController _jobPost;

  @override
  void initState() {
    super.initState();
    final state = widget.state;
    _role = TextEditingController(text: state.targetJobTitle);
    _company = TextEditingController(text: state.companyName);
    _jobPost = TextEditingController(text: state.jobPostText);
  }

  @override
  void dispose() {
    _role.dispose();
    _company.dispose();
    _jobPost.dispose();
    super.dispose();
  }

  /// The controller owns the values (picking a CV fills the role); mirror them
  /// into the fields without touching text the user is typing.
  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _pickCv() async {
    final state = widget.state;
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.selectedCvId,
    );
    if (id != null && mounted) {
      ref.read(interviewPrepControllerProvider.notifier).selectCv(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(interviewPrepControllerProvider.notifier);
    _sync(_role, state.targetJobTitle);
    _sync(_company, state.companyName);
    _sync(_jobPost, state.jobPostText);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      children: [
        const SectionLabel(AppStrings.interviewSetupLabel),
        const SizedBox(height: AppSpacing.s8),
        if (state.hasSavedCvs) ...[
          CvPickerCard(
            cv: state.selectedCv,
            emptyLabel: AppStrings.interviewNoCvSelected,
            onTap: _pickCv,
          ),
          if (state.selectedCv != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => controller.selectCv(null),
                child: const Text(AppStrings.interviewWithoutCv),
              ),
            ),
        ] else
          _NoCvCard(onCreateCv: widget.onCreateCv),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          label: AppStrings.interviewRoleLabel,
          hintText: AppStrings.interviewRoleHint,
          controller: _role,
          fillColor: AppColors.surface,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: controller.updateTargetJobTitle,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextField(
          label:
              '${AppStrings.interviewCompanyLabel} '
              '${AppStrings.interviewOptional}',
          hintText: AppStrings.interviewCompanyHint,
          controller: _company,
          fillColor: AppColors.surface,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: controller.updateCompanyName,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextArea(
          label:
              '${AppStrings.interviewJobPostLabel} '
              '${AppStrings.interviewOptional}',
          hintText: AppStrings.interviewJobPostHint,
          controller: _jobPost,
          fillColor: AppColors.surface,
          minLines: 5,
          maxLines: 8,
          onChanged: controller.updateJobPostText,
        ),
        const SizedBox(height: AppSpacing.s20),
        const SectionLabel(AppStrings.interviewTypeLabel),
        const SizedBox(height: AppSpacing.s8),
        _ChipGroup<InterviewType>(
          values: InterviewType.values,
          selected: state.interviewType,
          labelOf: (type) => type.label,
          onSelected: controller.selectInterviewType,
        ),
        const SizedBox(height: AppSpacing.s16),
        const SectionLabel(AppStrings.interviewLanguageLabel),
        const SizedBox(height: AppSpacing.s8),
        _ChipGroup<AiOutputLanguage>(
          values: AiOutputLanguage.values,
          selected: state.language,
          labelOf: (language) => language == AiOutputLanguage.english
              ? AppStrings.interviewEnglish
              : AppStrings.interviewBangla,
          onSelected: controller.selectLanguage,
        ),
        const SizedBox(height: AppSpacing.s16),
        const SectionLabel(AppStrings.interviewAnswerStyleLabel),
        const SizedBox(height: AppSpacing.s8),
        _ChipGroup<InterviewAnswerStyle>(
          values: InterviewAnswerStyle.values,
          selected: state.answerStyle,
          labelOf: (style) => style.label,
          onSelected: controller.selectAnswerStyle,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(
            state.errorMessage!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ],
        if (state.hasRecentSessions) ...[
          const SizedBox(height: AppSpacing.s22),
          const SectionLabel(AppStrings.interviewRecent),
          const SizedBox(height: AppSpacing.s8),
          _RecentSessions(state: state, onOpen: controller.loadSession),
        ],
        const SizedBox(height: AppSpacing.s22),
        const SectionLabel(AppStrings.interviewQuickPractice),
        const SizedBox(height: AppSpacing.s4),
        Text(
          AppStrings.interviewQuickPracticeBody,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.s8),
        _QuickPractice(
          prompts: interviewQuickPrompts(state.language),
          onCopy: widget.onCopyQuickQuestion,
        ),
      ],
    );
  }
}

class _NoCvCard extends StatelessWidget {
  const _NoCvCard({required this.onCreateCv});

  final VoidCallback onCreateCv;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.interviewNoCvTitle, style: AppTextStyles.itemTitle),
          const SizedBox(height: AppSpacing.s4),
          Text(
            AppStrings.interviewNoCvBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          SecondaryButton(
            label: AppStrings.interviewCreateCv,
            onPressed: onCreateCv,
          ),
        ],
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final value in values)
          AppChip(
            label: labelOf(value),
            variant: value == selected
                ? AppChipVariant.selected
                : AppChipVariant.neutral,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.state, required this.onOpen});

  static const int _maxShown = 4;

  final InterviewPrepState state;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final sessions = state.recentSessions.take(_maxShown).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, session) in sessions.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.line),
            InkWell(
              onTap: () => onOpen(session.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.displayTitle,
                              style: AppTextStyles.itemTitle,
                            ),
                            Text(
                              '${session.displaySubtitle} · '
                              '${DateFormatter.shortDate(session.updatedAt)}',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickPractice extends StatelessWidget {
  const _QuickPractice({required this.prompts, required this.onCopy});

  final List<InterviewQuickPrompt> prompts;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, prompt) in prompts.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s14,
                AppSpacing.s10,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.question,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          prompt.tip,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onCopy(prompt.question),
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    color: AppColors.muted2,
                    tooltip: AppStrings.interviewCopyQuestion,
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
