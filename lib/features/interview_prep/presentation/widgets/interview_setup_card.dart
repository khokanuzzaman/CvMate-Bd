import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/choice_chips.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

/// Text controllers for the setup form, owned by the screen.
class InterviewFormControllers {
  const InterviewFormControllers({
    required this.jobTitle,
    required this.company,
    required this.jobPost,
  });

  final TextEditingController jobTitle;
  final TextEditingController company;
  final TextEditingController jobPost;
}

/// The setup: CV, role, company, job post, interview type, language and answer
/// style, then Generate and shortcuts to the builder / AI Improve.
class InterviewSetupCard extends StatelessWidget {
  const InterviewSetupCard({
    super.key,
    required this.state,
    required this.form,
    required this.onPickCv,
    required this.onInterviewTypeChanged,
    required this.onLanguageChanged,
    required this.onAnswerStyleChanged,
    required this.onGenerate,
    required this.onOpenBuilder,
    required this.onOpenAiImprove,
  });

  final InterviewPrepState state;
  final InterviewFormControllers form;
  final VoidCallback onPickCv;
  final ValueChanged<InterviewType> onInterviewTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<InterviewAnswerStyle> onAnswerStyleChanged;
  final VoidCallback onGenerate;
  final VoidCallback onOpenBuilder;
  final VoidCallback? onOpenAiImprove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.interviewSetupTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.interviewSetupBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s14),
          CvPickerCard(
            cv: state.selectedCv,
            emptyLabel: AppStrings.interviewNoCv,
            onTap: onPickCv,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: form.jobTitle,
            label: AppStrings.interviewJobTitleLabel,
            hintText: AppStrings.interviewJobTitleHint,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: form.company,
            label:
                '${AppStrings.interviewCompanyLabel} '
                '${AppStrings.interviewOptional}',
            hintText: AppStrings.interviewCompanyHint,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: form.jobPost,
            label:
                '${AppStrings.interviewJobPostLabel} '
                '${AppStrings.interviewOptional}',
            hintText: AppStrings.interviewJobPostHint,
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.s16),
          const SectionLabel(AppStrings.interviewTypeLabel),
          const SizedBox(height: AppSpacing.s4),
          ChoiceChips<InterviewType>(
            options: InterviewType.values,
            value: state.interviewType,
            labelOf: (type) => type.label,
            onChanged: onInterviewTypeChanged,
          ),
          const SizedBox(height: AppSpacing.s8),
          const SectionLabel(AppStrings.interviewLanguageLabel),
          const SizedBox(height: AppSpacing.s4),
          ChoiceChips<AiOutputLanguage>(
            options: AiOutputLanguage.values,
            value: state.language,
            labelOf: (language) => language == AiOutputLanguage.english
                ? AppStrings.commonEnglish
                : AppStrings.commonBangla,
            onChanged: onLanguageChanged,
          ),
          const SizedBox(height: AppSpacing.s8),
          const SectionLabel(AppStrings.interviewStyleLabel),
          const SizedBox(height: AppSpacing.s4),
          ChoiceChips<InterviewAnswerStyle>(
            options: InterviewAnswerStyle.values,
            value: state.answerStyle,
            labelOf: (style) => style.label,
            onChanged: onAnswerStyleChanged,
          ),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: state.isGenerating
                ? AppStrings.interviewGenerating
                : AppStrings.interviewGenerate,
            leadingIcon: Icons.auto_awesome_outlined,
            onPressed: state.isGenerating ? null : onGenerate,
          ),
          const SizedBox(height: AppSpacing.s10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: !state.hasSavedCvs
                      ? AppStrings.interviewCreateCv
                      : state.selectedCv == null
                      ? AppStrings.interviewOpenCvList
                      : AppStrings.interviewOpenBuilder,
                  leadingIcon: Icons.description_outlined,
                  outlineColor: AppColors.lineStrong,
                  onPressed: onOpenBuilder,
                ),
              ),
              if (onOpenAiImprove != null) ...[
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.interviewOpenAiImprove,
                    leadingIcon: Icons.auto_fix_high_outlined,
                    outlineColor: AppColors.lineStrong,
                    onPressed: onOpenAiImprove,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
