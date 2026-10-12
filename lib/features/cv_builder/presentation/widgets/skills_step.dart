import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/suggested_skills.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/skill_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skills section: add input, removable skill chips and suggested skills.
class SkillsStep extends ConsumerStatefulWidget {
  const SkillsStep({super.key});

  @override
  ConsumerState<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends ConsumerState<SkillsStep> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final name = raw.trim();
    if (name.isNotEmpty) {
      final skills = ref.read(cvBuilderControllerProvider).draft.skills;
      final exists = skills.any(
        (skill) => skill.name.trim().toLowerCase() == name.toLowerCase(),
      );
      if (!exists) {
        ref
            .read(cvBuilderControllerProvider.notifier)
            .addSkill(SkillInfo.empty().copyWith(name: name));
      }
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(cvBuilderControllerProvider).draft;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final skills = draft.skills;
    final suggestions = SuggestedSkills.forRole(
      draft.personalInfo.desiredRole,
      existing: skills.map((skill) => skill.name),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: SectionLabel(AppStrings.builderSkillsLabel),
        ),
        const SizedBox(height: AppSpacing.s10),
        _SkillInput(
          controller: _controller,
          focusNode: _focusNode,
          onSubmit: _add,
        ),
        const SizedBox(height: AppSpacing.s4),
        Wrap(
          spacing: AppSpacing.s8,
          children: [
            for (final skill in skills)
              SkillChip(
                key: ValueKey(skill.id),
                name: skill.name,
                onRemove: () => notifier.removeSkill(skill.id),
              ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(AppStrings.builderSuggested, style: AppTextStyles.caption),
          Wrap(
            spacing: AppSpacing.s8,
            children: [
              for (final name in suggestions)
                SuggestedSkillChip(name: name, onAdd: () => _add(name)),
            ],
          ),
        ],
      ],
    );
  }
}

class _SkillInput extends StatelessWidget {
  const _SkillInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              onSubmitted: onSubmit,
              style: AppTextStyles.bodySm,
              decoration: const InputDecoration(
                hintText: AppStrings.builderSkillInputHint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: AppStrings.builderAddSkill,
            child: InkWell(
              onTap: () => onSubmit(controller.text),
              borderRadius: AppRadii.iconTileRadius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4 + AppSpacing.s4),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadii.iconTileRadius,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
