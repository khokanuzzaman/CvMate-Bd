import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JobTrackerScreen extends ConsumerWidget {
  const JobTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsState = ref.watch(jobTrackerControllerProvider);
    final filteredApplications = ref.watch(filteredJobApplicationsProvider);
    final summary = ref.watch(jobTrackerSummaryProvider);
    final statusFilter = ref.watch(jobTrackerStatusFilterProvider);
    final query = ref.watch(jobTrackerSearchQueryProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Job Tracker'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Job'),
      ),
      body: SafeArea(
        child: applicationsState.when(
          loading: () => const CustomLoadingView(
            message: 'Loading your job applications...',
          ),
          error: (error, stackTrace) => CustomErrorView(
            title: 'Could not load applications',
            message: 'Something went wrong. Please try again.',
            onRetry: () =>
                ref.read(jobTrackerControllerProvider.notifier).reload(),
          ),
          data: (applications) {
            final hasFilters = statusFilter != null || query.trim().isNotEmpty;
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
                      _SummarySection(summary: summary),
                      const SizedBox(height: 20),
                      _FilterCard(
                        query: query,
                        statusFilter: statusFilter,
                        onSearchChanged: (value) => ref
                            .read(jobTrackerSearchQueryProvider.notifier)
                            .setQuery(value),
                        onStatusChanged: (value) => ref
                            .read(jobTrackerStatusFilterProvider.notifier)
                            .setFilter(value),
                        onClear: () {
                          ref
                              .read(jobTrackerSearchQueryProvider.notifier)
                              .clear();
                          ref
                              .read(jobTrackerStatusFilterProvider.notifier)
                              .clear();
                        },
                      ),
                      const SizedBox(height: 20),
                      if (applications.isEmpty)
                        CustomCard(
                          child: CustomEmptyState(
                            title: 'No job applications yet',
                            message:
                                'Track your first job application to monitor follow-ups, interviews, and linked CV versions.',
                            icon: Icons.track_changes_outlined,
                            actionLabel: 'Add application',
                            onAction: () => _openForm(context),
                          ),
                        )
                      else if (filteredApplications.isEmpty && hasFilters)
                        CustomCard(
                          child: CustomEmptyState(
                            title: 'No matching applications',
                            message:
                                'Try another company name, job title, or status filter.',
                            icon: Icons.search_off_rounded,
                            actionLabel: 'Clear filters',
                            onAction: () {
                              ref
                                  .read(jobTrackerSearchQueryProvider.notifier)
                                  .clear();
                              ref
                                  .read(jobTrackerStatusFilterProvider.notifier)
                                  .clear();
                            },
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (final application in filteredApplications) ...[
                              _ApplicationCard(
                                application: application,
                                onTap: () =>
                                    _openDetails(context, application.id),
                              ),
                              const SizedBox(height: 14),
                            ],
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

  Future<void> _openForm(BuildContext context, {String? applicationId}) async {
    final path = Uri(
      path: RouteNames.jobApplicationFormPath,
      queryParameters: applicationId == null ? null : {'id': applicationId},
    ).toString();
    final message = await context.push<String>(path);
    if (!context.mounted || message == null || message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetails(BuildContext context, String applicationId) async {
    final path = Uri(
      path: RouteNames.jobApplicationDetailsPath,
      queryParameters: {'id': applicationId},
    ).toString();
    final message = await context.push<String>(path);
    if (!context.mounted || message == null || message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final JobTrackerSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final itemWidth = isWide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: itemWidth,
              title: 'Total',
              value: summary.total.toString(),
              note: 'Tracked applications',
            ),
            _SummaryCard(
              width: itemWidth,
              title: 'Follow-up',
              value: summary.pendingFollowUp.toString(),
              note: 'Due or overdue',
            ),
            _SummaryCard(
              width: itemWidth,
              title: 'Interview',
              value: summary.interviews.toString(),
              note: 'Scheduled now',
            ),
            _SummaryCard(
              width: itemWidth,
              title: 'Offers',
              value: summary.offers.toString(),
              note: 'Positive outcomes',
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.note,
  });

  final double width;
  final String title;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(note, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.query,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final String query;
  final JobApplicationStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<JobApplicationStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find and filter', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          CustomTextField(
            key: ValueKey(query),
            initialValue: query,
            label: 'Search by company or job title',
            hintText: 'BRAC Bank, Flutter Developer',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<JobApplicationStatus?>(
            initialValue: statusFilter,
            decoration: const InputDecoration(labelText: 'Status filter'),
            onChanged: onStatusChanged,
            items: [
              const DropdownMenuItem<JobApplicationStatus?>(
                value: null,
                child: Text('All statuses'),
              ),
              for (final status in JobApplicationStatus.values)
                DropdownMenuItem<JobApplicationStatus?>(
                  value: status,
                  child: Text(status.label),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton.text(
            label: 'Clear filters',
            onPressed: onClear,
            icon: Icons.filter_alt_off_outlined,
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final JobApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      onTap: onTap,
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
                      application.jobTitle.trim().isEmpty
                          ? 'Untitled role'
                          : application.jobTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.companyName.trim().isEmpty
                          ? 'Unknown company'
                          : application.companyName,
                    ),
                  ],
                ),
              ),
              JobStatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(label: Text(application.jobSource.label)),
              Chip(
                label: Text(
                  'Applied ${DateFormatter.shortDate(application.appliedDate)}',
                ),
              ),
              if (application.interviewDate != null)
                Chip(
                  label: Text(
                    'Interview ${DateFormatter.shortDate(application.interviewDate!)}',
                  ),
                ),
              if (application.hasLinkedCv) const Chip(label: Text('Linked CV')),
              if (application.hasLinkedCoverLetter)
                const Chip(label: Text('Linked cover letter')),
              if (application.needsFollowUp)
                const Chip(label: Text('Follow-up due')),
            ],
          ),
          if (application.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              application.notes.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
