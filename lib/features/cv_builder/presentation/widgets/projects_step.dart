import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectsStep extends ConsumerWidget {
  const ProjectsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(cvBuilderControllerProvider).draft.projects;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Projects',
      description:
          'Projects are especially valuable for students, fresh graduates, and career switchers.',
      helper:
          'Describe what you built, what tools you used, and what impact or purpose it had.',
      child: Column(
        children: [
          if (projects.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No projects added yet',
                message:
                    'Projects can prove hands-on ability even without formal work experience.',
                icon: Icons.folder_special_outlined,
                actionLabel: 'Add project',
                onAction: () =>
                    _openProjectSheet(context, onSave: notifier.addProject),
              ),
            )
          else ...[
            for (final item in projects) ...[
              CvCollectionItemCard(
                title: item.title,
                subtitle: item.role.trim().isEmpty ? 'Project' : item.role,
                details: [
                  item.description,
                  if (item.technologies.isNotEmpty)
                    'Technologies: ${item.technologies.join(', ')}',
                  if (item.link.trim().isNotEmpty) item.link,
                ],
                onEdit: () => _openProjectSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateProject,
                ),
                onDelete: () => notifier.removeProject(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: projects.isEmpty ? 'Add project' : 'Add another project',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openProjectSheet(context, onSave: notifier.addProject),
          ),
        ],
      ),
    );
  }

  Future<void> _openProjectSheet(
    BuildContext context, {
    ProjectInfo? initialValue,
    required ValueChanged<ProjectInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _ProjectEditorSheet(initialValue: initialValue, onSave: onSave);
      },
    );
  }
}

class _ProjectEditorSheet extends StatefulWidget {
  const _ProjectEditorSheet({this.initialValue, required this.onSave});

  final ProjectInfo? initialValue;
  final ValueChanged<ProjectInfo> onSave;

  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _roleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _technologiesController;
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    _titleController = TextEditingController(text: item?.title ?? '');
    _roleController = TextEditingController(text: item?.role ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _technologiesController = TextEditingController(
      text: item?.technologies.join(', ') ?? '',
    );
    _linkController = TextEditingController(text: item?.link ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    _technologiesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialValue != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Edit project' : 'Add project',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Project title',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Project title is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _roleController,
                label: 'Your role',
                hintText: 'Developer, team lead, designer',
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hintText:
                    'Explain what the project does and what you contributed.',
                minLines: 4,
                maxLines: 5,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Project description is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _technologiesController,
                label: 'Technologies',
                hintText: 'Flutter, Firebase, REST API',
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _linkController,
                label: 'Project link',
                hintText: 'https://github.com/...',
                keyboardType: TextInputType.url,
                textCapitalization: TextCapitalization.none,
                validator: Validators.optionalUrl,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update project' : 'Save project',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue = (widget.initialValue ?? ProjectInfo.empty())
                      .copyWith(
                        title: _titleController.text.trim(),
                        role: _roleController.text.trim(),
                        description: _descriptionController.text.trim(),
                        technologies: _splitCommaValues(
                          _technologiesController.text,
                        ),
                        link: _linkController.text.trim(),
                      );

                  widget.onSave(nextValue);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _splitCommaValues(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
