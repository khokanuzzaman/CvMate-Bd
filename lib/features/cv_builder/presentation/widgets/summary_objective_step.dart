import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/ai_action_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Summary page: a Summary / Objective toggle over one large text area, a
/// "Generate with AI" action, and a banner once every section is complete.
class SummaryObjectiveStep extends ConsumerStatefulWidget {
  const SummaryObjectiveStep({super.key, required this.showValidationErrors});

  final bool showValidationErrors;

  @override
  ConsumerState<SummaryObjectiveStep> createState() =>
      _SummaryObjectiveStepState();
}

class _SummaryObjectiveStepState extends ConsumerState<SummaryObjectiveStep> {
  late bool _showObjective;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(cvBuilderControllerProvider).draft;
    // Open on the objective only when that is all the CV has so far.
    _showObjective =
        draft.professionalSummary.trim().isEmpty &&
        draft.careerObjective.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvBuilderControllerProvider);
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final draft = state.draft;
    final autovalidate = widget.showValidationErrors
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;
    final isComplete = notifier.validateStep(CvBuilderStep.preview) == null;

    void update(String value) {
      final current = ref.read(cvBuilderControllerProvider).draft;
      notifier.updateSummary(
        professionalSummary: _showObjective
            ? current.professionalSummary
            : value,
        careerObjective: _showObjective ? value : current.careerObjective,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeToggle(
          showObjective: _showObjective,
          onChanged: (value) => setState(() => _showObjective = value),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              // Shrinks (instead of overflowing) next to the AI action when
              // the text is large or the screen is narrow.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SectionLabel(
                  _showObjective
                      ? AppStrings.builderCareerObjective
                      : AppStrings.builderProfessionalSummary,
                ),
              ),
            ),
            AiActionPill(
              type: _showObjective
                  ? AiImproveType.careerObjective
                  : AiImproveType.professionalSummary,
              label: AppStrings.builderGenerateWithAi,
              solid: true,
            ),
          ],
        ),
        AppTextArea(
          key: ValueKey(_showObjective),
          initialValue: _showObjective
              ? draft.careerObjective
              : draft.professionalSummary,
          hintText: _showObjective
              ? AppStrings.builderObjectiveHint
              : AppStrings.builderSummaryHint,
          fillColor: AppColors.surface,
          minLines: 12,
          maxLines: 20,
          autovalidateMode: autovalidate,
          validator: (_) =>
              notifier.validateStep(CvBuilderStep.summaryObjective),
          onChanged: update,
        ),
        const SizedBox(height: AppSpacing.s12),
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
                AppStrings.builderSummaryTip,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        if (isComplete) ...[
          const SizedBox(height: AppSpacing.s16),
          const _DoneBanner(),
        ],
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.showObjective, required this.onChanged});

  final bool showObjective;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4 + 1),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input + 4),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: AppStrings.builderToggleSummary,
              selected: !showObjective,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
              label: AppStrings.builderToggleObjective,
              selected: showObjective,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadii.input + 4),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Text(
              AppStrings.builderAllDone,
              style: AppTextStyles.body.copyWith(
                color: AppColors.successText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
