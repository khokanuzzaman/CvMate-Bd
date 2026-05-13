import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActions = <_QuickAction>[
      const _QuickAction(
        label: 'Create CV',
        description: 'Start a new CV or manage saved versions.',
        icon: Icons.description_outlined,
        routePath: RouteNames.cvListPath,
      ),
      const _QuickAction(
        label: 'Improve CV',
        description: 'Rewrite summaries and experience bullets with AI.',
        icon: Icons.auto_fix_high_outlined,
        routePath: RouteNames.aiImprovePath,
      ),
      const _QuickAction(
        label: 'Cover Letter',
        description: 'Generate tailored letters and email drafts.',
        icon: Icons.mail_outline_rounded,
        routePath: RouteNames.coverLetterPath,
      ),
      const _QuickAction(
        label: 'Track Job',
        description: 'Follow application stages and interview dates.',
        icon: Icons.track_changes_outlined,
        routePath: RouteNames.jobTrackerPath,
      ),
      const _QuickAction(
        label: 'Interview Prep',
        description: 'Practice role-based and CV-based questions.',
        icon: Icons.record_voice_over_outlined,
        routePath: RouteNames.interviewPrepPath,
      ),
      const _QuickAction(
        label: 'ATS Check',
        description: 'Review structure, keywords, and missing sections.',
        icon: Icons.fact_check_outlined,
        routePath: RouteNames.atsCheckerPath,
      ),
    ];

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appName,
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.profilePath),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: () => context.push(RouteNames.settingsPath),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, const Color(0xFF144B7D)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.homeGreeting,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.homeHeroTitle,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.homeHeroBody,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.homeQuickActions,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 640 ? 3 : 2;
                      final spacing = 16.0;
                      final itemWidth =
                          (constraints.maxWidth - ((columns - 1) * spacing)) /
                          columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final action in quickActions)
                            SizedBox(
                              width: itemWidth,
                              child: _QuickActionCard(action: action),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.homeProgress,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth,
                            child: const _StatusCard(
                              value: 'Foundation',
                              label: 'Project milestone',
                              note:
                                  'Theme, routing, reusable widgets, and initial screens are in place.',
                            ),
                          ),
                          SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth,
                            child: const _StatusCard(
                              value: '6',
                              label: 'Career actions',
                              note:
                                  'Quick paths for CV building, AI writing, ATS review, and job tracking.',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.homeAiTools,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planned AI prompt categories',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            Chip(label: Text('Professional summary')),
                            Chip(label: Text('Career objective')),
                            Chip(label: Text('Experience bullet rewrite')),
                            Chip(label: Text('Cover letter')),
                            Chip(label: Text('Job application email')),
                            Chip(label: Text('Interview questions')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.homeRecentActivity,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _RecentActivityCard(
                    icon: Icons.note_alt_outlined,
                    title: 'Recent CVs',
                    message: AppStrings.homeRecentCvEmpty,
                  ),
                  const SizedBox(height: 16),
                  const _RecentActivityCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Recent applications',
                    message: AppStrings.homeRecentJobsEmpty,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.routePath,
  });

  final String label;
  final String description;
  final IconData icon;
  final String routePath;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      onTap: () => context.push(action.routePath),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: colorScheme.primary,
            child: Icon(action.icon),
          ),
          const SizedBox(height: 16),
          Text(action.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(action.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.value,
    required this.label,
    required this.note,
  });

  final String value;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(note, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
