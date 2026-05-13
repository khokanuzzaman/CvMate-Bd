import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SummaryObjectiveStep extends ConsumerWidget {
  const SummaryObjectiveStep({super.key, required this.showValidationErrors});

  final bool showValidationErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);
    final draft = state.draft;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final autoValidate = showValidationErrors
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;

    return CvStepSection(
      title: 'Summary and objective',
      description:
          'Keep both sections concise, honest, and aligned with the role you want.',
      helper:
          'For freshers, summary can focus on strengths, projects, tools, and learning attitude.',
      child: Column(
        children: [
          CustomTextField(
            initialValue: draft.professionalSummary,
            label: 'Professional summary',
            hintText:
                'Write a short 2-3 line summary about your strengths, tools, and relevant experience.',
            minLines: 4,
            maxLines: 5,
            autovalidateMode: autoValidate,
            validator: (value) {
              final text = value?.trim() ?? '';
              final objective = draft.careerObjective.trim();
              if (text.isEmpty && objective.isEmpty) {
                return 'Add either a summary or an objective.';
              }

              if (text.isNotEmpty && text.length < 40) {
                return 'Make the summary a bit more detailed.';
              }

              return null;
            },
            onChanged: (value) => notifier.updateSummary(
              professionalSummary: value,
              careerObjective: draft.careerObjective,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: draft.careerObjective,
            label: 'Career objective',
            hintText:
                'State the type of role you want and how you plan to contribute.',
            minLines: 3,
            maxLines: 4,
            autovalidateMode: autoValidate,
            validator: (value) {
              final text = value?.trim() ?? '';
              final summary = draft.professionalSummary.trim();
              if (text.isEmpty && summary.isEmpty) {
                return 'Add either a summary or an objective.';
              }

              if (text.isNotEmpty && text.length < 20) {
                return 'Make the objective more specific.';
              }

              return null;
            },
            onChanged: (value) => notifier.updateSummary(
              professionalSummary: draft.professionalSummary,
              careerObjective: value,
            ),
          ),
        ],
      ),
    );
  }
}
