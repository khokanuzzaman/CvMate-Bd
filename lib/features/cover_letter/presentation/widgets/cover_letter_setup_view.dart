import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_state.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_tone_options.dart';
import 'package:careermatebd/features/cover_letter/presentation/widgets/cover_letter_drafts.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

/// Value of the "no CV" entry in the CV dropdown.
const String manualCvSelectionValue = '__manual_cv__';

/// Text controllers for the setup form, owned by the screen.
class CoverLetterFormControllers {
  const CoverLetterFormControllers({
    required this.company,
    required this.jobTitle,
    required this.jobDetails,
    required this.hiringManager,
    required this.candidateSummary,
  });

  final TextEditingController company;
  final TextEditingController jobTitle;
  final TextEditingController jobDetails;
  final TextEditingController hiringManager;
  final TextEditingController candidateSummary;
}

/// Everything the user sets before generating: CV, output type, language, tone,
/// job details and optional extras. Also lists recent drafts.
class CoverLetterSetupView extends StatelessWidget {
  const CoverLetterSetupView({
    super.key,
    required this.state,
    required this.form,
    required this.onBack,
    required this.onNewDraft,
    required this.onViewLetter,
    required this.onCreateCv,
    required this.onOpenSelectedCv,
    required this.onCvChanged,
    required this.onOutputTypeChanged,
    required this.onLanguageChanged,
    required this.onToneChanged,
    required this.onOpenDraft,
    required this.onDeleteDraft,
    required this.onGenerate,
  });

  final CoverLetterState state;
  final CoverLetterFormControllers form;
  final VoidCallback onBack;
  final VoidCallback onNewDraft;
  final VoidCallback? onViewLetter;
  final VoidCallback onCreateCv;
  final VoidCallback? onOpenSelectedCv;
  final ValueChanged<String?> onCvChanged;
  final ValueChanged<CoverLetterOutputType> onOutputTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<AiTone> onToneChanged;
  final ValueChanged<String> onOpenDraft;
  final ValueChanged<CoverLetterDraft> onDeleteDraft;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: AppTopBar(
                title: AppStrings.coverLetterTitle,
                onBack: onBack,
                trailingIcon: Icons.add_rounded,
                trailingTooltip: AppStrings.coverLetterNewDraft,
                onTrailingTap: onNewDraft,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s8,
                  AppSpacing.screen,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      state: state,
                      onViewLetter: onViewLetter,
                      onCreateCv: onCreateCv,
                      onOpenSelectedCv: onOpenSelectedCv,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    if (state.recentDrafts.isNotEmpty) ...[
                      CoverLetterDrafts(
                        drafts: state.recentDrafts,
                        cvs: state.availableCvs,
                        activeDraftId: state.activeDraftId,
                        onOpen: onOpenDraft,
                        onDelete: onDeleteDraft,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                    ],
                    _CvCard(state: state, onChanged: onCvChanged),
                    const SizedBox(height: AppSpacing.s16),
                    _GeneratorCard(
                      state: state,
                      onOutputTypeChanged: onOutputTypeChanged,
                      onLanguageChanged: onLanguageChanged,
                      onToneChanged: onToneChanged,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _DetailsCard(state: state, form: form),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.s16),
                      _ErrorCard(message: state.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s8,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: PrimaryButton(
                label: AppStrings.coverLetterGenerate,
                leadingIcon: Icons.auto_awesome_outlined,
                onPressed: state.isGenerating ? null : onGenerate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.state,
    required this.onViewLetter,
    required this.onCreateCv,
    required this.onOpenSelectedCv,
  });

  final CoverLetterState state;
  final VoidCallback? onViewLetter;
  final VoidCallback onCreateCv;
  final VoidCallback? onOpenSelectedCv;

  @override
  Widget build(BuildContext context) {
    final cv = state.selectedCv;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.coverLetterSetupTitle,
                  style: AppTextStyles.title,
                ),
              ),
              if (state.isEditingSavedDraft)
                const AppChip(label: AppStrings.coverLetterEditingDraft),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            AppStrings.coverLetterSetupBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (!state.hasSavedCvs)
            Text(AppStrings.coverLetterNoCvs, style: AppTextStyles.bodySm)
          else if (cv != null)
            Text(
              AppStrings.coverLetterSelectedCv(cv.displayTitle, cv.displayRole),
              style: AppTextStyles.bodySm,
            ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s8,
            children: [
              SecondaryButton(
                label: state.hasSavedCvs
                    ? AppStrings.coverLetterCreateAnotherCv
                    : AppStrings.coverLetterCreateCv,
                leadingIcon: Icons.add_rounded,
                expanded: false,
                onPressed: onCreateCv,
              ),
              if (onOpenSelectedCv != null)
                SecondaryButton(
                  label: AppStrings.coverLetterOpenSelectedCv,
                  leadingIcon: Icons.description_outlined,
                  expanded: false,
                  outlineColor: AppColors.lineStrong,
                  onPressed: onOpenSelectedCv,
                ),
              if (onViewLetter != null)
                SecondaryButton(
                  label: AppStrings.coverLetterViewLetter,
                  leadingIcon: Icons.article_outlined,
                  expanded: false,
                  onPressed: onViewLetter,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({required this.state, required this.onChanged});

  final CoverLetterState state;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(AppStrings.coverLetterCandidate),
          const SizedBox(height: AppSpacing.s10),
          DropdownButtonFormField<String>(
            key: ValueKey(state.selectedCvId),
            initialValue: state.selectedCvId ?? manualCvSelectionValue,
            isExpanded: true,
            onChanged: onChanged,
            decoration: const InputDecoration(
              labelText: AppStrings.coverLetterSelectCv,
            ),
            items: [
              const DropdownMenuItem(
                value: manualCvSelectionValue,
                child: Text(AppStrings.coverLetterManualCv),
              ),
              for (final cv in state.availableCvs)
                DropdownMenuItem(
                  value: cv.id,
                  child: Text(
                    '${cv.displayTitle} • ${cv.displayRole}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  const _GeneratorCard({
    required this.state,
    required this.onOutputTypeChanged,
    required this.onLanguageChanged,
    required this.onToneChanged,
  });

  final CoverLetterState state;
  final ValueChanged<CoverLetterOutputType> onOutputTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<AiTone> onToneChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<CoverLetterOutputType>(
            key: ValueKey(state.outputType),
            initialValue: state.outputType,
            isExpanded: true,
            onChanged: (value) {
              if (value != null) {
                onOutputTypeChanged(value);
              }
            },
            decoration: const InputDecoration(
              labelText: AppStrings.coverLetterOutputType,
            ),
            items: [
              for (final type in CoverLetterOutputType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            state.outputType.description,
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s16),
          const SectionLabel(AppStrings.coverLetterLanguage),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s10,
            runSpacing: AppSpacing.s8,
            children: [
              AppChip(
                label: AppStrings.coverLetterEnglish,
                variant: state.language == AiOutputLanguage.english
                    ? AppChipVariant.selected
                    : AppChipVariant.neutral,
                onTap: () => onLanguageChanged(AiOutputLanguage.english),
              ),
              AppChip(
                label: AppStrings.coverLetterBangla,
                variant: state.language == AiOutputLanguage.bangla
                    ? AppChipVariant.selected
                    : AppChipVariant.neutral,
                onTap: () => onLanguageChanged(AiOutputLanguage.bangla),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          const SectionLabel(AppStrings.coverLetterTone),
          const SizedBox(height: AppSpacing.s8),
          SegmentedToggle<AiTone>(
            options: coverLetterToneOptions,
            value: state.tone,
            onChanged: onToneChanged,
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.state, required this.form});

  final CoverLetterState state;
  final CoverLetterFormControllers form;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel(AppStrings.coverLetterJobDetails),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            controller: form.company,
            label: AppStrings.coverLetterCompanyLabel,
            hintText: AppStrings.coverLetterCompanyHint,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: form.jobTitle,
            label: AppStrings.coverLetterJobTitleLabel,
            hintText: AppStrings.coverLetterJobTitleHint,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: form.jobDetails,
            label: AppStrings.coverLetterJobPostLabel,
            hintText: AppStrings.coverLetterJobPostHint,
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: form.hiringManager,
            label: AppStrings.coverLetterManagerLabel,
            hintText: AppStrings.coverLetterManagerHint,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: form.candidateSummary,
            label: AppStrings.coverLetterSummaryLabel,
            hintText: AppStrings.coverLetterSummaryHint,
            minLines: 4,
            maxLines: 6,
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            state.selectedCv == null
                ? AppStrings.coverLetterSummaryNeeded
                : AppStrings.coverLetterSummaryReuse,
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
