import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/cv_field_codec.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/ai_action_pill.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_item_card.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < experiences.length; i++) ...[
          _ExperienceCard(
            key: ValueKey(experiences[i].id),
            index: i + 1,
            item: experiences[i],
            onChanged: notifier.updateExperience,
            onRemove: () => notifier.removeExperience(experiences[i].id),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        BuilderAddButton(
          label: experiences.isEmpty
              ? AppStrings.builderAddFirstRole
              : AppStrings.builderAddAnotherRole,
          onPressed: () => notifier.addExperience(ExperienceInfo.empty()),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatefulWidget {
  const _ExperienceCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ExperienceInfo item;
  final ValueChanged<ExperienceInfo> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<_ExperienceCard> {
  late final TextEditingController _jobTitle;
  late final TextEditingController _company;
  late final TextEditingController _dates;
  late final TextEditingController _highlights;
  late final TextEditingController _location;
  late final String _initialDates;
  late final String _initialHighlights;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _jobTitle = TextEditingController(text: item.jobTitle);
    _company = TextEditingController(text: item.companyName);
    _initialDates = DateRangeCodec.format(
      start: item.startDate,
      end: item.endDate,
      ongoing: item.isCurrentRole,
    );
    _dates = TextEditingController(text: _initialDates);
    _initialHighlights = BulletsCodec.format(item.highlights);
    _highlights = TextEditingController(text: _initialHighlights);
    _location = TextEditingController(text: item.location);
  }

  @override
  void dispose() {
    _jobTitle.dispose();
    _company.dispose();
    _dates.dispose();
    _highlights.dispose();
    _location.dispose();
    super.dispose();
  }

  void _emit() {
    var next = widget.item.copyWith(
      jobTitle: _jobTitle.text.trim(),
      companyName: _company.text.trim(),
      location: _location.text.trim(),
    );

    // Only re-parse the combined boxes if the user edited them.
    if (_dates.text != _initialDates) {
      final range = DateRangeCodec.parse(_dates.text);
      next = next.copyWith(
        startDate: range.start,
        endDate: range.end,
        isCurrentRole: range.ongoing,
      );
    }
    if (_highlights.text != _initialHighlights) {
      next = next.copyWith(highlights: BulletsCodec.parse(_highlights.text));
    }

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return BuilderItemCard(
      title: AppStrings.builderRoleTitle(widget.index),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _jobTitle,
            label: AppStrings.builderJobTitle,
            hintText: AppStrings.builderJobTitleHint,
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
                  controller: _company,
                  label: AppStrings.builderCompany,
                  hintText: AppStrings.builderCompanyHint,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppTextField(
                  controller: _dates,
                  label: AppStrings.builderDates,
                  hintText: AppStrings.builderExperienceDatesHint,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: _highlights,
            label: AppStrings.builderWhatYouDid,
            hintText: AppStrings.builderBulletsHint,
            labelTrailing: const AiActionPill(
              type: AiImproveType.experienceBullet,
              label: AppStrings.builderImproveWithAi,
            ),
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: _location,
            label: AppStrings.builderLocationOpt,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
