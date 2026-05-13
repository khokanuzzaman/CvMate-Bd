import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExperienceStep extends ConsumerWidget {
  const ExperienceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiences = ref
        .watch(cvBuilderControllerProvider)
        .draft
        .experiences;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Experience',
      description:
          'Add internships, part-time work, or full-time experience. Freshers can skip this step.',
      helper:
          'If you do not have formal experience yet, make sure the projects step is strong.',
      child: Column(
        children: [
          if (experiences.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No experience added',
                message:
                    'This is optional. Skip if you are a fresher, or add internship and freelance work if relevant.',
                icon: Icons.work_outline_rounded,
                actionLabel: 'Add experience',
                onAction: () => _openExperienceSheet(
                  context,
                  onSave: notifier.addExperience,
                ),
              ),
            )
          else ...[
            for (final item in experiences) ...[
              CvCollectionItemCard(
                title: item.jobTitle,
                subtitle: item.companyName,
                details: [
                  [
                    item.location.trim(),
                    item.isCurrentRole
                        ? '${item.startDate} - Present'
                        : [
                            item.startDate.trim(),
                            item.endDate.trim(),
                          ].where((value) => value.isNotEmpty).join(' - '),
                  ].where((value) => value.isNotEmpty).join(' • '),
                  if (item.highlights.isNotEmpty) item.highlights.first,
                  if (item.highlights.length > 1)
                    '${item.highlights.length - 1} more highlight(s)',
                ],
                onEdit: () => _openExperienceSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateExperience,
                ),
                onDelete: () => notifier.removeExperience(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: experiences.isEmpty
                ? 'Add experience'
                : 'Add another experience',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openExperienceSheet(context, onSave: notifier.addExperience),
          ),
        ],
      ),
    );
  }

  Future<void> _openExperienceSheet(
    BuildContext context, {
    ExperienceInfo? initialValue,
    required ValueChanged<ExperienceInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _ExperienceEditorSheet(
          initialValue: initialValue,
          onSave: onSave,
        );
      },
    );
  }
}

class _ExperienceEditorSheet extends StatefulWidget {
  const _ExperienceEditorSheet({this.initialValue, required this.onSave});

  final ExperienceInfo? initialValue;
  final ValueChanged<ExperienceInfo> onSave;

  @override
  State<_ExperienceEditorSheet> createState() => _ExperienceEditorSheetState();
}

class _ExperienceEditorSheetState extends State<_ExperienceEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _locationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _highlightsController;
  late bool _isCurrentRole;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    _companyController = TextEditingController(text: item?.companyName ?? '');
    _jobTitleController = TextEditingController(text: item?.jobTitle ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _startDateController = TextEditingController(text: item?.startDate ?? '');
    _endDateController = TextEditingController(text: item?.endDate ?? '');
    _highlightsController = TextEditingController(
      text: item?.highlights.join('\n') ?? '',
    );
    _isCurrentRole = item?.isCurrentRole ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _highlightsController.dispose();
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
                isEditing ? 'Edit experience' : 'Add experience',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _companyController,
                label: 'Company',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Company name is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _jobTitleController,
                label: 'Job title',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Job title is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _locationController,
                label: 'Location',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _startDateController,
                      label: 'Start date',
                      hintText: 'Jan 2024',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _endDateController,
                      label: 'End date',
                      hintText: 'Dec 2024',
                      readOnly: _isCurrentRole,
                    ),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isCurrentRole,
                title: const Text('I currently work here'),
                onChanged: (value) {
                  setState(() {
                    _isCurrentRole = value;
                    if (value) {
                      _endDateController.clear();
                    }
                  });
                },
              ),
              CustomTextField(
                controller: _highlightsController,
                label: 'Highlights',
                hintText: 'Write one responsibility or achievement per line.',
                minLines: 4,
                maxLines: 6,
                validator: (value) => _splitLines(value).isEmpty
                    ? 'Add at least one highlight.'
                    : null,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update experience' : 'Save experience',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue =
                      (widget.initialValue ?? ExperienceInfo.empty()).copyWith(
                        companyName: _companyController.text.trim(),
                        jobTitle: _jobTitleController.text.trim(),
                        location: _locationController.text.trim(),
                        startDate: _startDateController.text.trim(),
                        endDate: _isCurrentRole
                            ? ''
                            : _endDateController.text.trim(),
                        isCurrentRole: _isCurrentRole,
                        highlights: _splitLines(_highlightsController.text),
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

  List<String> _splitLines(String? value) {
    return (value ?? '')
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
