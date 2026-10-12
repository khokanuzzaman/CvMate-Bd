import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_page.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_application_card.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_tracker_filters.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_tracker_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Job Tracker: summary tiles, search and status filters, and the applications.
class JobTrackerScreen extends ConsumerStatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  ConsumerState<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends ConsumerState<JobTrackerScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(jobTrackerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    ref.read(jobTrackerSearchQueryProvider.notifier).clear();
    ref.read(jobTrackerStatusFilterProvider.notifier).clear();
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    final applicationsState = ref.watch(jobTrackerControllerProvider);
    final filtered = ref.watch(filteredJobApplicationsProvider);
    final summary = ref.watch(jobTrackerSummaryProvider);
    final statusFilter = ref.watch(jobTrackerStatusFilterProvider);
    final query = ref.watch(jobTrackerSearchQueryProvider);

    return AppPage(
      title: AppStrings.trackerTitle,
      onBack: () => context.pop(),
      footer: AppPageFooter(
        child: PrimaryButton(
          label: AppStrings.trackerAddJob,
          leadingIcon: Icons.add_rounded,
          onPressed: _openForm,
        ),
      ),
      body: applicationsState.when(
        loading: () =>
            const CustomLoadingView(message: AppStrings.trackerLoading),
        error: (error, stackTrace) => CustomErrorView(
          title: AppStrings.trackerLoadErrorTitle,
          message: AppStrings.trackerLoadErrorBody,
          onRetry: ref.read(jobTrackerControllerProvider.notifier).reload,
        ),
        data: (applications) {
          final hasFilters = statusFilter != null || query.trim().isNotEmpty;
          return AppPageScroll(
            children: [
              JobTrackerSummaryTiles(summary: summary),
              const SizedBox(height: AppSpacing.s16),
              JobTrackerFilters(
                searchController: _search,
                statusFilter: statusFilter,
                hasFilters: hasFilters,
                onSearchChanged: ref
                    .read(jobTrackerSearchQueryProvider.notifier)
                    .setQuery,
                onStatusChanged: ref
                    .read(jobTrackerStatusFilterProvider.notifier)
                    .setFilter,
                onClear: _clearFilters,
              ),
              const SizedBox(height: AppSpacing.s12),
              if (applications.isEmpty)
                AppCard(
                  child: CustomEmptyState(
                    title: AppStrings.trackerEmptyTitle,
                    message: AppStrings.trackerEmptyBody,
                    icon: Icons.track_changes_outlined,
                    actionLabel: AppStrings.trackerAddApplication,
                    onAction: _openForm,
                  ),
                )
              else if (filtered.isEmpty && hasFilters)
                AppCard(
                  child: CustomEmptyState(
                    title: AppStrings.trackerNoMatchTitle,
                    message: AppStrings.trackerNoMatchBody,
                    icon: Icons.search_off_rounded,
                    actionLabel: AppStrings.trackerClearFilters,
                    onAction: _clearFilters,
                  ),
                )
              else
                for (final application in filtered) ...[
                  JobApplicationCard(
                    application: application,
                    onTap: () => _openDetails(application.id),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm() => _push(RouteNames.jobApplicationFormPath);

  Future<void> _openDetails(String id) =>
      _push(RouteNames.jobApplicationDetailsPath, {'id': id});

  /// Opens [path]; the form and details pop with a message to show here.
  Future<void> _push(String path, [Map<String, String>? query]) async {
    final location = Uri(path: path, queryParameters: query).toString();
    final message = await context.push<String>(location);
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
