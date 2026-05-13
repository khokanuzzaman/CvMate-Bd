import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_message_templates.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_details_provider.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
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
      return const Scaffold(
        appBar: CustomAppBar(title: 'Application Details'),
        body: SafeArea(
          child: CustomErrorView(
            title: 'Application not found',
            message: 'A valid application ID was not provided.',
          ),
        ),
      );
    }

    final detailsState = ref.watch(
      jobApplicationDetailsProvider(applicationId!),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Application Details',
        actions: [
          IconButton(
            onPressed: () => _openEditForm(context, ref),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit application',
          ),
        ],
      ),
      body: SafeArea(
        child: detailsState.when(
          loading: () => const CustomLoadingView(
            message: 'Loading application details...',
          ),
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
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderCard(application: application),
                      const SizedBox(height: 20),
                      _StatusUpdateCard(
                        application: application,
                        onStatusChanged: (status) =>
                            _updateStatus(context, ref, status),
                      ),
                      const SizedBox(height: 20),
                      _KeyInfoCard(application: application),
                      const SizedBox(height: 20),
                      _LinkedAssetsCard(
                        application: application,
                        linkedCvTitle: data.cv?.displayTitle,
                        linkedCoverLetterTitle: data.coverLetter?.displayTitle,
                      ),
                      const SizedBox(height: 20),
                      _NotesCard(application: application),
                      const SizedBox(height: 20),
                      _QuickTemplatesCard(
                        application: application,
                        onCopyTemplate: (type) =>
                            _copyTemplate(context, application, type),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomButton.secondary(
                            label: 'Edit application',
                            onPressed: () => _openEditForm(context, ref),
                            icon: Icons.edit_outlined,
                            isExpanded: false,
                          ),
                          CustomButton.secondary(
                            label:
                                application.status ==
                                    JobApplicationStatus.archived
                                ? 'Mark as Applied'
                                : 'Archive',
                            onPressed: () =>
                                _archiveOrRestore(context, ref, application),
                            icon: Icons.archive_outlined,
                            isExpanded: false,
                          ),
                          CustomButton.secondary(
                            label: 'Delete',
                            onPressed: () => _delete(context, ref, application),
                            icon: Icons.delete_outline_rounded,
                            isExpanded: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
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
                    Text(
                      application.jobTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(application.companyName),
                  ],
                ),
              ),
              JobStatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(label: Text(application.jobSource.label)),
              Chip(
                label: Text(
                  'Created ${DateFormatter.shortDate(application.createdAt)}',
                ),
              ),
              if (application.needsFollowUp)
                const Chip(label: Text('Follow-up due')),
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
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<JobApplicationStatus>(
            initialValue: application.status,
            decoration: const InputDecoration(labelText: 'Current status'),
            onChanged: (value) {
              if (value != null) {
                onStatusChanged(value);
              }
            },
            items: [
              for (final status in JobApplicationStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
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
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Applied date',
            value: DateFormatter.shortDate(application.appliedDate),
          ),
          _InfoRow(
            label: 'Deadline',
            value: application.deadlineDate == null
                ? 'Not added'
                : DateFormatter.shortDate(application.deadlineDate!),
          ),
          _InfoRow(
            label: 'Interview date',
            value: application.interviewDate == null
                ? 'Not added'
                : DateFormatter.shortDate(application.interviewDate!),
          ),
          _InfoRow(
            label: 'Follow-up reminder',
            value: application.followUpDate == null
                ? 'Not added'
                : DateFormatter.shortDate(application.followUpDate!),
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
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    if (application.notes.trim().isEmpty) {
      return const CustomCard(
        child: CustomEmptyState(
          title: 'No notes yet',
          message:
              'Add recruiter messages, interview instructions, salary notes, or follow-up reminders in the application form.',
          icon: Icons.note_alt_outlined,
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(application.notes),
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
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick copy templates', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Use these local templates for follow-up, interview confirmation, and polite status checks.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final type in JobApplicationMessageTemplateType.values)
                CustomButton.secondary(
                  label: type.label,
                  onPressed: () => onCopyTemplate(type),
                  icon: Icons.copy_outlined,
                  isExpanded: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
