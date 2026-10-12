import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter/material.dart';

/// Search box and a scrolling row of status chips ("All" + each status).
class JobTrackerFilters extends StatelessWidget {
  const JobTrackerFilters({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final JobApplicationStatus? statusFilter;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<JobApplicationStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: searchController,
          label: AppStrings.trackerSearchLabel,
          hintText: AppStrings.trackerSearchHint,
          fillColor: AppColors.surface,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.s8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(AppStrings.trackerFilterAll, null),
              for (final status in JobApplicationStatus.values)
                _chip(status.label, status),
            ],
          ),
        ),
        if (hasFilters)
          Align(
            alignment: Alignment.centerLeft,
            child: SecondaryButton(
              label: AppStrings.trackerClearFilters,
              leadingIcon: Icons.filter_alt_off_outlined,
              expanded: false,
              outlineColor: Colors.transparent,
              onPressed: onClear,
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, JobApplicationStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: AppChip(
        label: label,
        variant: statusFilter == status
            ? AppChipVariant.selected
            : AppChipVariant.neutral,
        onTap: () => onStatusChanged(status),
      ),
    );
  }
}
