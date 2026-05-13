import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EducationStep extends ConsumerWidget {
  const EducationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final education = ref.watch(cvBuilderControllerProvider).draft.education;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Education',
      description:
          'Add your strongest academic history first. Fresh graduates should keep this section complete and clear.',
      child: Column(
        children: [
          if (education.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No education added yet',
                message:
                    'Start with your most recent education so your CV already has a strong foundation.',
                icon: Icons.school_outlined,
                actionLabel: 'Add education',
                onAction: () =>
                    _openEducationSheet(context, onSave: notifier.addEducation),
              ),
            )
          else ...[
            for (final item in education) ...[
              CvCollectionItemCard(
                title: item.degree,
                subtitle: item.institution,
                details: [
                  if (item.fieldOfStudy.trim().isNotEmpty) item.fieldOfStudy,
                  [
                    item.location.trim(),
                    item.isOngoing
                        ? '${item.startYear} - Present'
                        : [
                            item.startYear.trim(),
                            item.endYear.trim(),
                          ].where((value) => value.isNotEmpty).join(' - '),
                  ].where((value) => value.isNotEmpty).join(' • '),
                  if (item.result.trim().isNotEmpty) item.result,
                ],
                onEdit: () => _openEducationSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateEducation,
                ),
                onDelete: () => notifier.removeEducation(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: education.isEmpty
                ? 'Add education'
                : 'Add another education',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openEducationSheet(context, onSave: notifier.addEducation),
          ),
        ],
      ),
    );
  }

  Future<void> _openEducationSheet(
    BuildContext context, {
    EducationInfo? initialValue,
    required ValueChanged<EducationInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _EducationEditorSheet(
          initialValue: initialValue,
          onSave: onSave,
        );
      },
    );
  }
}

class _EducationEditorSheet extends StatefulWidget {
  const _EducationEditorSheet({this.initialValue, required this.onSave});

  final EducationInfo? initialValue;
  final ValueChanged<EducationInfo> onSave;

  @override
  State<_EducationEditorSheet> createState() => _EducationEditorSheetState();
}

class _EducationEditorSheetState extends State<_EducationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _institutionController;
  late final TextEditingController _degreeController;
  late final TextEditingController _fieldController;
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;
  late final TextEditingController _resultController;
  late final TextEditingController _locationController;
  late bool _isOngoing;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    _institutionController = TextEditingController(
      text: item?.institution ?? '',
    );
    _degreeController = TextEditingController(text: item?.degree ?? '');
    _fieldController = TextEditingController(text: item?.fieldOfStudy ?? '');
    _startYearController = TextEditingController(text: item?.startYear ?? '');
    _endYearController = TextEditingController(text: item?.endYear ?? '');
    _resultController = TextEditingController(text: item?.result ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _isOngoing = item?.isOngoing ?? false;
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _resultController.dispose();
    _locationController.dispose();
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
                isEditing ? 'Edit education' : 'Add education',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _institutionController,
                label: 'Institution',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Institution is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _degreeController,
                label: 'Degree',
                hintText: 'BSc in Computer Science',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Degree is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _fieldController,
                label: 'Field of study',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _startYearController,
                      label: 'Start year',
                      keyboardType: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _endYearController,
                      label: 'End year',
                      keyboardType: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                      readOnly: _isOngoing,
                    ),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isOngoing,
                title: const Text('I am still studying here'),
                onChanged: (value) {
                  setState(() {
                    _isOngoing = value;
                    if (value) {
                      _endYearController.clear();
                    }
                  });
                },
              ),
              CustomTextField(
                controller: _resultController,
                label: 'Result / CGPA',
                hintText: 'CGPA 3.75 / 4.00',
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _locationController,
                label: 'Location',
                hintText: 'Dhaka',
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update education' : 'Save education',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue =
                      (widget.initialValue ?? EducationInfo.empty()).copyWith(
                        institution: _institutionController.text.trim(),
                        degree: _degreeController.text.trim(),
                        fieldOfStudy: _fieldController.text.trim(),
                        startYear: _startYearController.text.trim(),
                        endYear: _isOngoing
                            ? ''
                            : _endYearController.text.trim(),
                        result: _resultController.text.trim(),
                        location: _locationController.text.trim(),
                        isOngoing: _isOngoing,
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
