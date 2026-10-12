import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the "Improve with AI" sheet: generate an editable summary or career
/// objective for the selected CV, then apply it or copy it.
Future<void> showAtsAiSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => const _AtsAiSheet(),
  );
}

class _AtsAiSheet extends ConsumerStatefulWidget {
  const _AtsAiSheet();

  @override
  ConsumerState<_AtsAiSheet> createState() => _AtsAiSheetState();
}

class _AtsAiSheetState extends ConsumerState<_AtsAiSheet> {
  late final TextEditingController _suggestion;

  @override
  void initState() {
    super.initState();
    _suggestion = TextEditingController(
      text: ref.read(atsCheckerControllerProvider).aiSuggestionText,
    );
  }

  @override
  void dispose() {
    _suggestion.dispose();
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
    final state = ref.watch(atsCheckerControllerProvider);
    final controller = ref.read(atsCheckerControllerProvider.notifier);
    // The controller owns the text (a new target clears it, a generation
    // fills it); mirror it into the field without fighting the user's typing.
    if (_suggestion.text != state.aiSuggestionText) {
      _suggestion.value = TextEditingValue(
        text: state.aiSuggestionText,
        selection: TextSelection.collapsed(
          offset: state.aiSuggestionText.length,
        ),
      );
    }

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
            Text(AppStrings.atsAiSheetTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.s6),
            Text(
              AppStrings.atsAiSheetBody,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final target in AtsAiTarget.values)
                  AppChip(
                    label: target.label,
                    variant: state.aiTarget == target
                        ? AppChipVariant.selected
                        : AppChipVariant.neutral,
                    onTap: () => controller.selectAiTarget(target),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: state.isGeneratingAiSuggestion
                  ? AppStrings.atsAiGenerating
                  : AppStrings.atsAiGenerate,
              leadingIcon: Icons.auto_awesome_outlined,
              onPressed: state.isGeneratingAiSuggestion
                  ? null
                  : controller.generateAiSuggestion,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                state.errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
              ),
            ],
            if (state.hasAiSuggestion) ...[
              const SizedBox(height: AppSpacing.s16),
              AppTextArea(
                label: AppStrings.atsAiSuggestionLabel,
                controller: _suggestion,
                minLines: 5,
                maxLines: 9,
                onChanged: controller.updateAiSuggestionText,
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: AppStrings.atsAiCopy,
                      onPressed: () => _show(controller.copySuggestion()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: PrimaryButton(
                      label: AppStrings.atsAiApply,
                      onPressed: () =>
                          _show(controller.applyAiSuggestionToCv()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
