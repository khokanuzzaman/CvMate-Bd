import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/cv_field_codec.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EducationStep extends ConsumerWidget {
  const EducationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final education = ref.watch(cvBuilderControllerProvider).draft.education;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < education.length; i++) ...[
          _EducationCard(
            key: ValueKey(education[i].id),
            index: i + 1,
            item: education[i],
            onChanged: notifier.updateEducation,
            onRemove: () => notifier.removeEducation(education[i].id),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        BuilderAddButton(
          label: education.isEmpty
              ? AppStrings.builderAddFirstDegree
              : AppStrings.builderAddAnotherDegree,
          onPressed: () => notifier.addEducation(EducationInfo.empty()),
        ),
      ],
    );
  }
}

class _EducationCard extends StatefulWidget {
  const _EducationCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final EducationInfo item;
  final ValueChanged<EducationInfo> onChanged;
  final VoidCallback onRemove;

  @override
  State<_EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<_EducationCard> {
  late final TextEditingController _degree;
  late final TextEditingController _institution;
  late final TextEditingController _dates;
  late final TextEditingController _grade;
  late final TextEditingController _field;
  late final TextEditingController _location;
  late final String _initialDates;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _degree = TextEditingController(text: item.degree);
    _institution = TextEditingController(text: item.institution);
    _initialDates = DateRangeCodec.format(
      start: item.startYear,
      end: item.endYear,
      ongoing: item.isOngoing,
    );
    _dates = TextEditingController(text: _initialDates);
    _grade = TextEditingController(text: item.result);
    _field = TextEditingController(text: item.fieldOfStudy);
    _location = TextEditingController(text: item.location);
  }

  @override
  void dispose() {
    _degree.dispose();
    _institution.dispose();
    _dates.dispose();
    _grade.dispose();
    _field.dispose();
    _location.dispose();
    super.dispose();
  }

  void _emit() {
    var next = widget.item.copyWith(
      degree: _degree.text.trim(),
      institution: _institution.text.trim(),
      result: _grade.text.trim(),
      fieldOfStudy: _field.text.trim(),
      location: _location.text.trim(),
    );

    // Only re-parse the combined "Dates" box if the user edited it.
    if (_dates.text != _initialDates) {
      final range = DateRangeCodec.parse(_dates.text);
      next = next.copyWith(
        startYear: range.start,
        endYear: range.end,
        isOngoing: range.ongoing,
      );
    }

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return BuilderItemCard(
      title: AppStrings.builderDegreeTitle(widget.index),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _degree,
            label: AppStrings.builderDegree,
            hintText: AppStrings.builderDegreeHint,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: _institution,
            label: AppStrings.builderInstitution,
            hintText: AppStrings.builderInstitutionHint,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 58,
                child: AppTextField(
                  controller: _dates,
                  label: AppStrings.builderDates,
                  hintText: AppStrings.builderEducationDatesHint,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                flex: 42,
                child: AppTextField(
                  controller: _grade,
                  label: AppStrings.builderGrade,
                  hintText: AppStrings.builderGradeHint,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _field,
                  label: AppStrings.builderFieldOfStudy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppTextField(
                  controller: _location,
                  label: AppStrings.builderLocationOpt,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
