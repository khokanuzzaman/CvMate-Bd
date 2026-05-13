import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SkillsStep extends ConsumerWidget {
  const SkillsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(cvBuilderControllerProvider).draft.skills;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Skills',
      description:
          'Add tools, technologies, and practical strengths relevant to the jobs you want.',
      helper:
          'Try to include at least two strong skills. Focus on role-relevant keywords, not generic buzzwords.',
      child: Column(
        children: [
          if (skills.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No skills added yet',
                message:
                    'Add technical and practical skills such as Flutter, Firebase, communication, or problem solving.',
                icon: Icons.psychology_alt_outlined,
                actionLabel: 'Add skill',
                onAction: () =>
                    _openSkillSheet(context, onSave: notifier.addSkill),
              ),
            )
          else ...[
            for (final item in skills) ...[
              CvCollectionItemCard(
                title: item.name,
                subtitle: item.level.trim().isEmpty
                    ? 'Skill'
                    : 'Level: ${item.level}',
                details: const [],
                onEdit: () => _openSkillSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateSkill,
                ),
                onDelete: () => notifier.removeSkill(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: skills.isEmpty ? 'Add skill' : 'Add another skill',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openSkillSheet(context, onSave: notifier.addSkill),
          ),
        ],
      ),
    );
  }

  Future<void> _openSkillSheet(
    BuildContext context, {
    SkillInfo? initialValue,
    required ValueChanged<SkillInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _SkillEditorSheet(initialValue: initialValue, onSave: onSave);
      },
    );
  }
}

class _SkillEditorSheet extends StatefulWidget {
  const _SkillEditorSheet({this.initialValue, required this.onSave});

  final SkillInfo? initialValue;
  final ValueChanged<SkillInfo> onSave;

  @override
  State<_SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends State<_SkillEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _level;

  static const _levels = [
    '',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Comfortable',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValue?.name ?? '',
    );
    _level = widget.initialValue?.level ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                isEditing ? 'Edit skill' : 'Add skill',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Skill name',
                hintText: 'Flutter',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Skill name is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Skill level'),
                items: [
                  for (final level in _levels)
                    DropdownMenuItem<String>(
                      value: level,
                      child: Text(level.isEmpty ? 'Not specified' : level),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _level = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update skill' : 'Save skill',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue = (widget.initialValue ?? SkillInfo.empty())
                      .copyWith(
                        name: _nameController.text.trim(),
                        level: _level,
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
}
