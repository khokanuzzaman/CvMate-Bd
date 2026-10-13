import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_message_templates.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_details_provider.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_filter_chips.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JobApplicationDetailsScreen extends ConsumerWidget {
  const JobApplicationDetailsScreen({super.key, this.applicationId});

  final String? applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (applicationId == null || applicationId!.trim().isEmpty) {
      return _Frame(
        title: 'Application details',
        onBack: () => context.pop(),
        child: const CustomErrorView(
          title: 'Application not found',
          message: 'A valid application ID was not provided.',
        ),
      );
    }

    final detailsState = ref.watch(
      jobApplicationDetailsProvider(applicationId!),
    );

    return _Frame(
      title: 'Application details',
      onBack: () => context.pop(),
      onEdit: () => _openEditForm(context, ref),
      child: detailsState.when(
        loading: () =>
            const CustomLoadingView(message: 'Loading application details...'),
        error: (error, stackTrace) => CustomErrorView(
          title: 'Could not load application',
          message: 'Something went wrong. Please try again.',
          onRetry: () =>
              ref.invalidate(jobApplicationDetailsProvider(applicationId!)),
        ),
        data: (data) {
          if (data == null) {
            return const CustomErrorView(
              title: 'Application not found',
              message: 'This saved application could not be found.',
            );
          }

          final application = data.application;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.s22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(application: application),
                const SizedBox(height: AppSpacing.s16),
                _StatusUpdateCard(
                  application: application,
                  onStatusChanged: (status) =>
                      _updateStatus(context, ref, status),
                ),
                const SizedBox(height: AppSpacing.s16),
                _KeyInfoCard(application: application),
                const SizedBox(height: AppSpacing.s16),
                _LinkedAssetsCard(
                  application: application,
                  linkedCvTitle: data.cv?.displayTitle,
                  linkedCoverLetterTitle: data.coverLetter?.displayTitle,
                ),
                const SizedBox(height: AppSpacing.s16),
                _NotesCard(application: application),
                const SizedBox(height: AppSpacing.s16),
                _QuickTemplatesCard(
                  application: application,
                  onCopyTemplate: (type) =>
                      _copyTemplate(context, application, type),
                ),
                const SizedBox(height: AppSpacing.s20),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Edit',
                        leadingIcon: Icons.edit_outlined,
                        onPressed: () => _openEditForm(context, ref),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: SecondaryButton(
                        label:
                            application.status == JobApplicationStatus.archived
                            ? 'Mark applied'
                            : 'Archive',
                        leadingIcon: Icons.archive_outlined,
                        onPressed: () =>
                            _archiveOrRestore(context, ref, application),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s10),
                TextButton.icon(
                  onPressed: () => _delete(context, ref, application),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'Delete application',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditForm(BuildContext context, WidgetRef ref) async {
    final path = Uri(
      path: RouteNames.jobApplicationFormPath,
      queryParameters: {'id': applicationId!},
    ).toString();
    final message = await context.push<String>(path);
    if (!context.mounted || message == null || message.trim().isEmpty) {
      return;
    }

    ref.invalidate(jobApplicationDetailsProvider(applicationId!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    JobApplicationStatus status,
  ) async {
    final updated = await ref
        .read(jobTrackerControllerProvider.notifier)
        .updateStatus(applicationId!, status);
    if (!context.mounted || updated == null) {
      return;
    }

    ref.invalidate(jobApplicationDetailsProvider(applicationId!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to ${status.label}.')),
    );
  }

  Future<void> _archiveOrRestore(
    BuildContext context,
    WidgetRef ref,
    JobApplication application,
  ) async {
    final nextStatus = application.status == JobApplicationStatus.archived
        ? JobApplicationStatus.applied
        : JobApplicationStatus.archived;
    await _updateStatus(context, ref, nextStatus);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    JobApplication application,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete application'),
          content: Text(
            'Delete "${application.displayTitle}" from local storage? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref
        .read(jobTrackerControllerProvider.notifier)
        .deleteApplication(application.id);
    if (!context.mounted) {
      return;
    }

    context.pop('Application deleted.');
  }

  Future<void> _copyTemplate(
    BuildContext context,
    JobApplication application,
    JobApplicationMessageTemplateType type,
  ) async {
    final text = JobApplicationMessageTemplates.build(type, application);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${type.label} copied.')));
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.onBack,
    required this.child,
    this.onEdit,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: AppTopBar(
                title: title,
                onBack: onBack,
                trailingIcon: onEdit == null ? null : Icons.edit_outlined,
                trailingTooltip: 'Edit application',
                onTrailingTap: onEdit,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.jobTitle, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      application.companyName,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              JobStatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              AppChip(label: application.jobSource.label),
              AppChip(
                label:
                    'Created ${DateFormatter.shortDate(application.createdAt)}',
              ),
              if (application.needsFollowUp)
                const AppChip(
                  label: 'Follow-up due',
                  variant: AppChipVariant.missing,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusUpdateCard extends StatelessWidget {
  const _StatusUpdateCard({
    required this.application,
    required this.onStatusChanged,
  });

  final JobApplication application;
  final ValueChanged<JobApplicationStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Update status'),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final status in JobFilterChips.order)
                AppChip(
                  label: status.label,
                  variant: status == application.status
                      ? AppChipVariant.selected
                      : AppChipVariant.neutral,
                  onTap: () => onStatusChanged(status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyInfoCard extends StatelessWidget {
  const _KeyInfoCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    String date(DateTime? value) =>
        value == null ? 'Not added' : DateFormatter.shortDate(value);

    return AppCard(
      child: Column(
        children: [
          _InfoRow(
            label: 'Applied date',
            value: DateFormatter.shortDate(application.appliedDate),
          ),
          _InfoRow(label: 'Deadline', value: date(application.deadlineDate)),
          _InfoRow(
            label: 'Interview date',
            value: date(application.interviewDate),
          ),
          _InfoRow(
            label: 'Follow-up reminder',
            value: date(application.followUpDate),
          ),
          _InfoRow(
            label: 'Job post link',
            value: application.jobPostLink ?? 'Not added',
          ),
          _InfoRow(
            label: 'Salary range',
            value: application.salaryRange ?? 'Not added',
          ),
          _InfoRow(
            label: 'Contact person',
            value: application.contactPerson ?? 'Not added',
          ),
          _InfoRow(
            label: 'Contact email',
            value: application.contactEmail ?? 'Not added',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _LinkedAssetsCard extends StatelessWidget {
  const _LinkedAssetsCard({
    required this.application,
    required this.linkedCvTitle,
    required this.linkedCoverLetterTitle,
  });

  final JobApplication application;
  final String? linkedCvTitle;
  final String? linkedCoverLetterTitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _InfoRow(
            label: 'Linked CV',
            value:
                linkedCvTitle ??
                (application.hasLinkedCv
                    ? 'Saved CV not found'
                    : 'No linked CV'),
          ),
          _InfoRow(
            label: 'Linked cover letter',
            value:
                linkedCoverLetterTitle ??
                (application.hasLinkedCoverLetter
                    ? 'Saved cover letter not found'
                    : 'No linked cover letter'),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final hasNotes = application.notes.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Notes'),
          const SizedBox(height: AppSpacing.s10),
          Text(
            hasNotes
                ? application.notes
                : 'No notes yet. Add recruiter messages, interview '
                      'instructions or follow-up reminders in the application '
                      'form.',
            style: AppTextStyles.body.copyWith(
              color: hasNotes ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTemplatesCard extends StatelessWidget {
  const _QuickTemplatesCard({
    required this.application,
    required this.onCopyTemplate,
  });

  final JobApplication application;
  final ValueChanged<JobApplicationMessageTemplateType> onCopyTemplate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Quick copy templates'),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Local templates for follow-up, interview confirmation and '
            'polite status checks.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          for (final type in JobApplicationMessageTemplateType.values) ...[
            SecondaryButton(
              label: type.label,
              leadingIcon: Icons.copy_outlined,
              onPressed: () => onCopyTemplate(type),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
