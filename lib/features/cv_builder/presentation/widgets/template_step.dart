import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_template_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateStep extends ConsumerWidget {
  const TemplateStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cvBuilderControllerProvider).draft;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Choose a template',
      description:
          'All template options are ATS-friendly and text-focused for the MVP.',
      child: CvTemplateSelector(
        selectedTemplate: draft.template,
        onSelected: notifier.selectTemplate,
      ),
    );
  }
}
