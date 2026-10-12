import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/main_tabs.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_application_card.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_filter_chips.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_stat_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Tracker tab: status counts, filter chips and one card per application,
/// with add / details / edit flows reached from here.
class JobTrackerScreen extends ConsumerStatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  ConsumerState<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends ConsumerState<JobTrackerScreen> {
  bool _searching = false;

  void _clearFilters() {
    ref.read(jobTrackerSearchQueryProvider.notifier).clear();
    ref.read(jobTrackerStatusFilterProvider.notifier).clear();
  }

  Future<void> _openForm() => _pushForResult(RouteNames.jobApplicationFormPath);

  Future<void> _openDetails(String id) =>
      _pushForResult(RouteNames.jobApplicationDetailsPath, id: id);

  Future<void> _pushForResult(String path, {String? id}) async {
    final location = Uri(
      path: path,
      queryParameters: id == null ? null : {'id': id},
    ).toString();
    final message = await context.push<String>(location);
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(jobTrackerControllerProvider);
    final query = ref.watch(jobTrackerSearchQueryProvider);
    final showSearch = _searching || query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s16,
                AppSpacing.screen,
                AppSpacing.s12,
              ),
              child: _Header(
                searching: showSearch,
                onToggleSearch: () {
                  if (showSearch) {
                    ref.read(jobTrackerSearchQueryProvider.notifier).clear();
                  }
                  setState(() => _searching = !showSearch);
                },
                onAdd: _openForm,
              ),
            ),
            Expanded(
              child: applications.when(
                loading: () =>
                    const CustomLoadingView(message: AppStrings.trackerLoading),
                error: (error, stackTrace) => CustomErrorView(
                  title: AppStrings.trackerLoadErrorTitle,
                  message: AppStrings.trackerLoadErrorBody,
                  onRetry: () =>
                      ref.read(jobTrackerControllerProvider.notifier).reload(),
                ),
                data: (all) => _Content(
                  hasApplications: all.isNotEmpty,
                  showSearch: showSearch,
                  onAdd: _openForm,
                  onOpen: _openDetails,
                  onClearFilters: _clearFilters,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: MainTabs.tracker,
        onTap: (index) =>
            MainTabs.open(context, index, current: MainTabs.tracker),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searching,
    required this.onToggleSearch,
    required this.onAdd,
  });

  final bool searching;
  final VoidCallback onToggleSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(AppStrings.trackerTitle, style: AppTextStyles.h1)),
        IconButton(
          onPressed: onToggleSearch,
          tooltip: AppStrings.trackerSearch,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          icon: Icon(
            searching ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.ink,
          ),
        ),
        Tooltip(
          message: AppStrings.trackerAdd,
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.button - 1),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadii.button - 1),
              child: const SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: Icon(Icons.add_rounded, color: AppColors.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.hasApplications,
    required this.showSearch,
    required this.onAdd,
    required this.onOpen,
    required this.onClearFilters,
  });

  final bool hasApplications;
  final bool showSearch;
  final VoidCallback onAdd;
  final ValueChanged<String> onOpen;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasApplications) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s22),
        child: CustomEmptyState(
          title: AppStrings.trackerEmptyTitle,
          message: AppStrings.trackerEmptyBody,
          icon: Icons.work_outline_rounded,
          actionLabel: AppStrings.trackerAdd,
          onAction: onAdd,
        ),
      );
    }

    final summary = ref.watch(jobTrackerSummaryProvider);
    final filtered = ref.watch(filteredJobApplicationsProvider);
    final filter = ref.watch(jobTrackerStatusFilterProvider);
    final query = ref.watch(jobTrackerSearchQueryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      children: [
        JobStatTiles(summary: summary),
        if (showSearch) ...[
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            key: const ValueKey('tracker-search'),
            initialValue: query,
            hintText: AppStrings.trackerSearchHint,
            fillColor: AppColors.surface,
            autofocus: true,
            onChanged: ref
                .read(jobTrackerSearchQueryProvider.notifier)
                .setQuery,
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        JobFilterChips(
          selected: filter,
          onSelected: ref
              .read(jobTrackerStatusFilterProvider.notifier)
              .setFilter,
        ),
        const SizedBox(height: AppSpacing.s14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s22),
            child: CustomEmptyState(
              title: AppStrings.trackerNoMatchTitle,
              message: AppStrings.trackerNoMatchBody,
              icon: Icons.search_off_rounded,
              actionLabel: AppStrings.trackerClearFilters,
              onAction: onClearFilters,
            ),
          )
        else
          for (final JobApplication application in filtered) ...[
            JobApplicationCard(
              application: application,
              onTap: () => onOpen(application.id),
              onPrep: () => context.push(RouteNames.interviewPrepPath),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
      ],
    );
  }
}
