import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/overflow_menu_button.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_state.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_tone_options.dart';
import 'package:careermatebd/features/cover_letter/presentation/widgets/cover_letter_paper.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

/// The cover-letter design: aligned-to chip, tone control, the letter as paper,
/// and Regenerate / Export.
class CoverLetterLetterView extends StatefulWidget {
  const CoverLetterLetterView({
    super.key,
    required this.state,
    required this.contentController,
    required this.subjectController,
    required this.onBack,
    required this.onShare,
    required this.onCopy,
    required this.onChangeDetails,
    required this.onToneChanged,
    required this.onRegenerate,
    required this.onExport,
  });

  final CoverLetterState state;
  final TextEditingController contentController;
  final TextEditingController subjectController;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onChangeDetails;
  final ValueChanged<AiTone> onToneChanged;
  final VoidCallback onRegenerate;
  final VoidCallback onExport;

  @override
  State<CoverLetterLetterView> createState() => _CoverLetterLetterViewState();
}

class _CoverLetterLetterViewState extends State<CoverLetterLetterView> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final target = [
      state.jobTitle.trim(),
      state.targetCompany.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    final hasContent = state.hasGeneratedContent;

    return Scaffold(
      backgroundColor: AppColors.bg,
      // Regenerate / Export are the Scaffold's bottom bar so snackbars are laid
      // out above them instead of covering them.
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s8,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: AppStrings.coverLetterRegenerate,
                      leadingIcon: Icons.refresh_rounded,
                      onPressed: state.isGenerating
                          ? null
                          : widget.onRegenerate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: PrimaryButton(
                      label: AppStrings.coverLetterExport,
                      leadingIcon: Icons.download_rounded,
                      onPressed: state.isGenerating || !hasContent
                          ? null
                          : widget.onExport,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTopBar(
                      title: AppStrings.coverLetterTitle,
                      onBack: widget.onBack,
                      trailingIcon: Icons.share_outlined,
                      trailingTooltip: AppStrings.coverLetterShare,
                      onTrailingTap: hasContent ? widget.onShare : null,
                    ),
                  ),
                  OverflowMenuButton(
                    tooltip: AppStrings.coverLetterMoreOptions,
                    items: [
                      OverflowMenuItem(
                        label: AppStrings.coverLetterCopyToClipboard,
                        icon: Icons.copy_outlined,
                        enabled: hasContent && !state.isGenerating,
                        onSelected: widget.onCopy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s4,
                  AppSpacing.screen,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (target.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _AlignedChip(
                          label: AppStrings.coverLetterAlignedTo(target),
                          onTap: widget.onChangeDetails,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SectionLabel(AppStrings.coverLetterTone),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedToggle<AiTone>(
                      options: coverLetterToneOptions,
                      value: state.tone,
                      onChanged: widget.onToneChanged,
                    ),
                    const SizedBox(height: AppSpacing.s14),
                    if (state.errorMessage != null) ...[
                      _ErrorNote(message: state.errorMessage!),
                      const SizedBox(height: AppSpacing.s14),
                    ],
                    CoverLetterPaper(
                      content: state.generatedContent,
                      subject: state.subjectLine,
                      showSubject:
                          state.outputType.showsSubjectLine ||
                          state.subjectLine.trim().isNotEmpty,
                      isGenerating: state.isGenerating,
                      editing: _editing,
                      onToggleEdit: () => setState(() => _editing = !_editing),
                      contentController: widget.contentController,
                      subjectController: widget.subjectController,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignedChip extends StatelessWidget {
  const _AlignedChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: AppStrings.coverLetterChangeDetails,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s14,
                vertical: AppSpacing.s10,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.pillRadius,
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.track_changes_rounded,
                      size: 16,
                      color: AppColors.primaryDeep,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

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
