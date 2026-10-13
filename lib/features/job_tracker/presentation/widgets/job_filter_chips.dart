import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter/material.dart';

/// "All" plus one chip per status; the row scrolls sideways.
class JobFilterChips extends StatelessWidget {
  const JobFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Pipeline order, with drafts (not yet applied) last.
  static const List<JobApplicationStatus> order = [
    JobApplicationStatus.applied,
    JobApplicationStatus.shortlisted,
    JobApplicationStatus.interview,
    JobApplicationStatus.offered,
    JobApplicationStatus.rejected,
    JobApplicationStatus.archived,
    JobApplicationStatus.draft,
  ];

  final JobApplicationStatus? selected;
  final ValueChanged<JobApplicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(
            label: AppStrings.trackerFilterAll,
            variant: selected == null
                ? AppChipVariant.selected
                : AppChipVariant.neutral,
            onTap: () => onSelected(null),
          ),
          for (final status in order) ...[
            const SizedBox(width: AppSpacing.s8),
            AppChip(
              label: status.label,
              variant: selected == status
                  ? AppChipVariant.selected
                  : AppChipVariant.neutral,
              onTap: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }
}
