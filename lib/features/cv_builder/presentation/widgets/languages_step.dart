import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguagesStep extends ConsumerWidget {
  const LanguagesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(cvBuilderControllerProvider).draft.languages;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Languages',
      description:
          'Mention languages you can actually use in professional communication.',
      child: Column(
        children: [
          if (languages.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No languages added',
                message:
                    'This is optional, but most users should mention Bangla and English proficiency clearly.',
                icon: Icons.translate_outlined,
                actionLabel: 'Add language',
                onAction: () =>
                    _openLanguageSheet(context, onSave: notifier.addLanguage),
              ),
            )
          else ...[
            for (final item in languages) ...[
              CvCollectionItemCard(
                title: item.name,
                subtitle: item.proficiency,
                details: const [],
                onEdit: () => _openLanguageSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateLanguage,
                ),
                onDelete: () => notifier.removeLanguage(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: languages.isEmpty ? 'Add language' : 'Add another language',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openLanguageSheet(context, onSave: notifier.addLanguage),
          ),
        ],
      ),
    );
  }

  Future<void> _openLanguageSheet(
    BuildContext context, {
    LanguageInfo? initialValue,
    required ValueChanged<LanguageInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _LanguageEditorSheet(initialValue: initialValue, onSave: onSave);
      },
    );
  }
}

class _LanguageEditorSheet extends StatefulWidget {
  const _LanguageEditorSheet({this.initialValue, required this.onSave});

  final LanguageInfo? initialValue;
  final ValueChanged<LanguageInfo> onSave;

  @override
  State<_LanguageEditorSheet> createState() => _LanguageEditorSheetState();
}

class _LanguageEditorSheetState extends State<_LanguageEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _proficiency;

  static const _levels = [
    'Basic',
    'Conversational',
    'Professional',
    'Fluent',
    'Native',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValue?.name ?? '',
    );
    _proficiency = widget.initialValue?.proficiency ?? _levels.first;
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
                isEditing ? 'Edit language' : 'Add language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Language name',
                hintText: 'Bangla',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Language name is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _proficiency,
                decoration: const InputDecoration(labelText: 'Proficiency'),
                items: [
                  for (final level in _levels)
                    DropdownMenuItem<String>(value: level, child: Text(level)),
                ],
                onChanged: (value) {
                  setState(() {
                    _proficiency = value ?? _levels.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update language' : 'Save language',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue =
                      (widget.initialValue ?? LanguageInfo.empty()).copyWith(
                        name: _nameController.text.trim(),
                        proficiency: _proficiency,
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
