import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter/material.dart';

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});

  final JobApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _colorsForStatus(scheme, status);

    return Chip(
      label: Text(status.label),
      backgroundColor: colors.$1,
      labelStyle: TextStyle(color: colors.$2),
      side: BorderSide(color: colors.$2.withValues(alpha: 0.22)),
    );
  }

  (Color, Color) _colorsForStatus(
    ColorScheme scheme,
    JobApplicationStatus status,
  ) {
    return switch (status) {
      JobApplicationStatus.draft => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      JobApplicationStatus.applied => (
        scheme.primary.withValues(alpha: 0.14),
        scheme.primary,
      ),
      JobApplicationStatus.shortlisted => (
        const Color(0xFFE7F3E8),
        const Color(0xFF1E6B34),
      ),
      JobApplicationStatus.interview => (
        const Color(0xFFFFF4DB),
        const Color(0xFF946200),
      ),
      JobApplicationStatus.offered => (
        const Color(0xFFDFF6EA),
        const Color(0xFF0D6B44),
      ),
      JobApplicationStatus.rejected => (
        scheme.error.withValues(alpha: 0.12),
        scheme.error,
      ),
      JobApplicationStatus.archived => (
        const Color(0xFFECECEC),
        const Color(0xFF5B5B5B),
      ),
    };
  }
}
