import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_collection_item_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrainingStep extends ConsumerWidget {
  const TrainingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainings = ref.watch(cvBuilderControllerProvider).draft.trainings;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return CvStepSection(
      title: 'Training and certifications',
      description:
          'Add short courses, bootcamps, certifications, or workshops if they support your target role.',
      child: Column(
        children: [
          if (trainings.isEmpty)
            CustomCard(
              child: CustomEmptyState(
                title: 'No training added',
                message:
                    'This step is optional, but relevant certifications can strengthen junior and fresher CVs.',
                icon: Icons.workspace_premium_outlined,
                actionLabel: 'Add training',
                onAction: () =>
                    _openTrainingSheet(context, onSave: notifier.addTraining),
              ),
            )
          else ...[
            for (final item in trainings) ...[
              CvCollectionItemCard(
                title: item.title,
                subtitle: item.organization,
                details: [
                  if (item.completionYear.trim().isNotEmpty)
                    item.completionYear,
                  if (item.details.trim().isNotEmpty) item.details,
                ],
                onEdit: () => _openTrainingSheet(
                  context,
                  initialValue: item,
                  onSave: notifier.updateTraining,
                ),
                onDelete: () => notifier.removeTraining(item.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
          CustomButton.secondary(
            label: trainings.isEmpty ? 'Add training' : 'Add another training',
            icon: Icons.add_rounded,
            onPressed: () =>
                _openTrainingSheet(context, onSave: notifier.addTraining),
          ),
        ],
      ),
    );
  }

  Future<void> _openTrainingSheet(
    BuildContext context, {
    TrainingInfo? initialValue,
    required ValueChanged<TrainingInfo> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _TrainingEditorSheet(initialValue: initialValue, onSave: onSave);
      },
    );
  }
}

class _TrainingEditorSheet extends StatefulWidget {
  const _TrainingEditorSheet({this.initialValue, required this.onSave});

  final TrainingInfo? initialValue;
  final ValueChanged<TrainingInfo> onSave;

  @override
  State<_TrainingEditorSheet> createState() => _TrainingEditorSheetState();
}

class _TrainingEditorSheetState extends State<_TrainingEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _organizationController;
  late final TextEditingController _completionYearController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    _titleController = TextEditingController(text: item?.title ?? '');
    _organizationController = TextEditingController(
      text: item?.organization ?? '',
    );
    _completionYearController = TextEditingController(
      text: item?.completionYear ?? '',
    );
    _detailsController = TextEditingController(text: item?.details ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _completionYearController.dispose();
    _detailsController.dispose();
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
                isEditing ? 'Edit training' : 'Add training',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Course or certification title',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Training title is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _organizationController,
                label: 'Organization',
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _completionYearController,
                label: 'Completion year',
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _detailsController,
                label: 'Details',
                hintText: 'Short note about what the training covered.',
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isEditing ? 'Update training' : 'Save training',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final nextValue =
                      (widget.initialValue ?? TrainingInfo.empty()).copyWith(
                        title: _titleController.text.trim(),
                        organization: _organizationController.text.trim(),
                        completionYear: _completionYearController.text.trim(),
                        details: _detailsController.text.trim(),
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
