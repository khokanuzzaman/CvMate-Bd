import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Training / certifications. Not in the design, so it follows the same
/// inline-card pattern as the other repeatable sections.
class TrainingStep extends ConsumerWidget {
  const TrainingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainings = ref.watch(cvBuilderControllerProvider).draft.trainings;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < trainings.length; i++) ...[
          _TrainingCard(
            key: ValueKey(trainings[i].id),
            index: i + 1,
            item: trainings[i],
            onChanged: notifier.updateTraining,
            onRemove: () => notifier.removeTraining(trainings[i].id),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        BuilderAddButton(
          label: trainings.isEmpty
              ? AppStrings.builderAddFirstTraining
              : AppStrings.builderAddAnotherTraining,
          onPressed: () => notifier.addTraining(TrainingInfo.empty()),
        ),
      ],
    );
  }
}

class _TrainingCard extends StatefulWidget {
  const _TrainingCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final TrainingInfo item;
  final ValueChanged<TrainingInfo> onChanged;
  final VoidCallback onRemove;

  @override
  State<_TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<_TrainingCard> {
  late final TextEditingController _title;
  late final TextEditingController _organization;
  late final TextEditingController _year;
  late final TextEditingController _details;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item.title);
    _organization = TextEditingController(text: item.organization);
    _year = TextEditingController(text: item.completionYear);
    _details = TextEditingController(text: item.details);
  }

  @override
  void dispose() {
    _title.dispose();
    _organization.dispose();
    _year.dispose();
    _details.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        title: _title.text.trim(),
        organization: _organization.text.trim(),
        completionYear: _year.text.trim(),
        details: _details.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BuilderItemCard(
      title: AppStrings.builderTrainingCardTitle(widget.index),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _title,
            label: AppStrings.builderTrainingName,
            hintText: AppStrings.builderTrainingNameHint,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 62,
                child: AppTextField(
                  controller: _organization,
                  label: AppStrings.builderOrganization,
                  hintText: AppStrings.builderOrganizationHint,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                flex: 38,
                child: AppTextField(
                  controller: _year,
                  label: AppStrings.builderYear,
                  hintText: AppStrings.builderYearHint,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: _details,
            label: AppStrings.builderDetailsOpt,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
