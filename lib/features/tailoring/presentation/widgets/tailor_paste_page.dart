import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/cv_picker.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 1/3 — pick the CV, paste the job post, optionally name the role and
/// company, then analyze the match.
class TailorPastePage extends ConsumerStatefulWidget {
  const TailorPastePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<TailorPastePage> createState() => _TailorPastePageState();
}

class _TailorPastePageState extends ConsumerState<TailorPastePage> {
  late final TextEditingController _jobPost;
  late final TextEditingController _jobTitle;
  late final TextEditingController _company;

  @override
  void initState() {
    super.initState();
    // Start from what the controller already holds (e.g. coming back from a
    // later page) so the fields and the state never disagree.
    final state = ref.read(tailoringControllerProvider);
    _jobPost = TextEditingController(text: state.jobPostText);
    _jobTitle = TextEditingController(text: state.jobTitle);
    _company = TextEditingController(text: state.company);
  }

  @override
  void dispose() {
    _jobPost.dispose();
    _jobTitle.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final state = ref.read(tailoringControllerProvider);
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.cvId,
    );
    if (id != null && mounted) {
      ref.read(tailoringControllerProvider.notifier).selectCv(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tailoringControllerProvider);
    final notifier = ref.read(tailoringControllerProvider.notifier);
    final analyzing = state.stage == TailoringStage.analyzing;

    return TailorPageScaffold(
      page: TailoringPage.paste,
      title: AppStrings.tailorTitle,
      onBack: widget.onBack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s16,
          AppSpacing.screen,
          AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel(AppStrings.tailorWhichCv),
            ),
            const SizedBox(height: AppSpacing.s8),
            CvPickerCard(
              cv: state.selectedCv,
              onTap: state.isBusy ? null : _pickCv,
            ),
            const SizedBox(height: AppSpacing.s20),
            const Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel(AppStrings.tailorPasteLabel),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppTextArea(
              controller: _jobPost,
              hintText: AppStrings.tailorPasteHint,
              fillColor: AppColors.surface,
              minLines: 14,
              maxLines: 30,
              onChanged: (value) => notifier.updateJobPost(jobPostText: value),
            ),
            const SizedBox(height: AppSpacing.s10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.muted2,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    AppStrings.tailorWorksForAnyRole,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _OptionalField(
                    label: AppStrings.tailorJobTitleLabel,
                    hint: AppStrings.tailorJobTitleHint,
                    controller: _jobTitle,
                    onChanged: (value) =>
                        notifier.updateJobPost(jobTitle: value),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _OptionalField(
                    label: AppStrings.tailorCompanyLabel,
                    hint: AppStrings.tailorCompanyHint,
                    controller: _company,
                    onChanged: (value) =>
                        notifier.updateJobPost(company: value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s16,
        ),
        child: PrimaryButton(
          label: analyzing
              ? AppStrings.tailorAnalyzing
              : AppStrings.tailorAnalyze,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: state.canAnalyze
              ? () => ref.read(tailoringFlowProvider.notifier).analyze()
              : null,
        ),
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One wrapping line (not a Row) so the label never overflows at large
        // text sizes.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label.toUpperCase(), style: AppTextStyles.label),
              TextSpan(
                text: ' ${AppStrings.tailorOptional}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppTextField(
          controller: controller,
          hintText: hint,
          fillColor: AppColors.surface,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
