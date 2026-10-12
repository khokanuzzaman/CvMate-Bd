import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/cv_field_codec.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/ai_action_pill.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectsStep extends ConsumerWidget {
  const ProjectsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(cvBuilderControllerProvider).draft.projects;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < projects.length; i++) ...[
          _ProjectCard(
            key: ValueKey(projects[i].id),
            index: i + 1,
            item: projects[i],
            onChanged: notifier.updateProject,
            onRemove: () => notifier.removeProject(projects[i].id),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        BuilderAddButton(
          label: projects.isEmpty
              ? AppStrings.builderAddFirstProject
              : AppStrings.builderAddAnotherProject,
          onPressed: () => notifier.addProject(ProjectInfo.empty()),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ProjectInfo item;
  final ValueChanged<ProjectInfo> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  late final TextEditingController _name;
  late final TextEditingController _tech;
  late final TextEditingController _link;
  late final TextEditingController _description;
  late final TextEditingController _role;
  late final String _initialTech;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item.title);
    _initialTech = CommaListCodec.format(item.technologies);
    _tech = TextEditingController(text: _initialTech);
    _link = TextEditingController(text: item.link);
    _description = TextEditingController(text: item.description);
    _role = TextEditingController(text: item.role);
  }

  @override
  void dispose() {
    _name.dispose();
    _tech.dispose();
    _link.dispose();
    _description.dispose();
    _role.dispose();
    super.dispose();
  }

  void _emit() {
    var next = widget.item.copyWith(
      title: _name.text.trim(),
      link: _link.text.trim(),
      description: _description.text.trim(),
      role: _role.text.trim(),
    );

    if (_tech.text != _initialTech) {
      next = next.copyWith(technologies: CommaListCodec.parse(_tech.text));
    }

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return BuilderItemCard(
      title: AppStrings.builderProjectTitle(widget.index),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: AppStrings.builderProjectName,
            hintText: AppStrings.builderProjectNameHint,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _tech,
                  label: AppStrings.builderTechRole,
                  hintText: AppStrings.builderTechHint,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppTextField(
                  controller: _link,
                  label: AppStrings.builderLink,
                  hintText: AppStrings.builderLinkHint,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: _description,
            label: AppStrings.builderWhatItDoes,
            hintText: AppStrings.builderBulletsHint,
            labelTrailing: const AiActionPill(
              type: AiImproveType.projectDescription,
              label: AppStrings.builderImproveWithAi,
            ),
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: _role,
            label: AppStrings.builderRoleOpt,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
