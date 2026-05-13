import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_severity_chip.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AtsCheckerScreen extends ConsumerStatefulWidget {
  const AtsCheckerScreen({super.key});

  @override
  ConsumerState<AtsCheckerScreen> createState() => _AtsCheckerScreenState();
}

class _AtsCheckerScreenState extends ConsumerState<AtsCheckerScreen> {
  final TextEditingController _jobPostController = TextEditingController();
  final TextEditingController _aiSuggestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jobPostController.addListener(_handleJobPostChanged);
    _aiSuggestionController.addListener(_handleAiSuggestionChanged);
    Future.microtask(
      () => ref.read(atsCheckerControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _jobPostController
      ..removeListener(_handleJobPostChanged)
      ..dispose();
    _aiSuggestionController
      ..removeListener(_handleAiSuggestionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(atsCheckerControllerProvider);
    _syncController(_jobPostController, state.jobPostText);
    _syncController(_aiSuggestionController, state.aiSuggestionText);

    return Scaffold(
      appBar: const CustomAppBar(title: 'ATS Checker'),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, AtsCheckerState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(
        message: 'Loading your saved CVs and ATS-friendly checks...',
      );
    }

    if (state.errorMessage != null &&
        !state.hasSavedCvs &&
        state.hasInitialized) {
      return CustomErrorView(
        title: 'Could not load ATS Checker',
        message: state.errorMessage!,
        onRetry: () => ref.read(atsCheckerControllerProvider.notifier).reload(),
      );
    }

    if (!state.hasSavedCvs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CustomEmptyState(
            title: 'No CV available yet',
            message:
                'Create your first CV before checking ATS-friendly quality and job-post match.',
            icon: Icons.fact_check_outlined,
            actionLabel: 'Create CV',
            onAction: () => _createCvFirst(context),
          ),
        ),
      );
    }

    final report = state.report;
    final selectedCv = state.selectedCv;
    if (report == null || selectedCv == null) {
      return CustomErrorView(
        title: 'No CV selected',
        message: 'Please reload the screen and select a saved CV.',
        onRetry: () => ref.read(atsCheckerControllerProvider.notifier).reload(),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding +
            MediaQuery.of(context).viewInsets.bottom +
            24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                state: state,
                report: report,
                onCvChanged: (cvId) => ref
                    .read(atsCheckerControllerProvider.notifier)
                    .selectCv(cvId),
                onGoToBuilder: () => _openCvBuilder(context, selectedCv),
                onOpenAiImprove: () => _openAiImprove(context, selectedCv),
              ),
              const SizedBox(height: 20),
              _JobPostMatchCard(
                state: state,
                jobPostController: _jobPostController,
                onCheckMatch: () => ref
                    .read(atsCheckerControllerProvider.notifier)
                    .checkJobMatch(),
                onCopySuggestions: state.jobMatchReport == null
                    ? null
                    : () => _showActionMessage(
                        ref
                            .read(atsCheckerControllerProvider.notifier)
                            .copyJobMatchSuggestions(),
                      ),
                onApplyDetectedSkills:
                    state.jobMatchReport == null ||
                        state.jobMatchReport!.suggestedSkillsToAdd.isEmpty
                    ? null
                    : () => _showActionMessage(
                        ref
                            .read(atsCheckerControllerProvider.notifier)
                            .applyDetectedSkillsToCv(),
                      ),
              ),
              const SizedBox(height: 20),
              _AiSuggestionCard(
                state: state,
                aiSuggestionController: _aiSuggestionController,
                onTargetChanged: (target) => ref
                    .read(atsCheckerControllerProvider.notifier)
                    .selectAiTarget(target),
                onGenerate: () => ref
                    .read(atsCheckerControllerProvider.notifier)
                    .generateAiSuggestion(),
                onApply: () => _showActionMessage(
                  ref
                      .read(atsCheckerControllerProvider.notifier)
                      .applyAiSuggestionToCv(),
                ),
                onCopy: () => _showActionMessage(
                  ref
                      .read(atsCheckerControllerProvider.notifier)
                      .copySuggestion(),
                ),
                onGoToBuilder: () => _openCvBuilder(context, selectedCv),
                onOpenAiImprove: () => _openAiImprove(context, selectedCv),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                _InlineErrorCard(message: state.errorMessage!),
              ],
              const SizedBox(height: 20),
              _CategorySection(
                report: report,
                jobMatchReport: state.jobMatchReport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleJobPostChanged() {
    ref
        .read(atsCheckerControllerProvider.notifier)
        .updateJobPostText(_jobPostController.text);
  }

  void _handleAiSuggestionChanged() {
    ref
        .read(atsCheckerControllerProvider.notifier)
        .updateAiSuggestionText(_aiSuggestionController.text);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _createCvFirst(BuildContext context) async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
    if (!context.mounted) {
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  Future<void> _openCvBuilder(BuildContext context, CvProfile profile) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(profile.id);
    if (!context.mounted) {
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  Future<void> _openAiImprove(BuildContext context, CvProfile profile) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(profile.id);
    if (!context.mounted) {
      return;
    }
    await context.push(RouteNames.aiImprovePath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  Future<void> _showActionMessage(Future<String?> action) async {
    final message = await action;
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.state,
    required this.report,
    required this.onCvChanged,
    required this.onGoToBuilder,
    required this.onOpenAiImprove,
  });

  final AtsCheckerState state;
  final AtsCheckReport report;
  final ValueChanged<String?> onCvChanged;
  final VoidCallback onGoToBuilder;
  final VoidCallback onOpenAiImprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(theme.colorScheme, report.score);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ATS-friendly CV improvement score',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Text(
                '${report.score}/100',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: report.score / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            color: scoreColor,
          ),
          const SizedBox(height: 12),
          Text(
            'This is a rule-based CV improvement score, not a guarantee of ATS approval or shortlist outcome.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: state.selectedCvId,
            onChanged: onCvChanged,
            decoration: const InputDecoration(labelText: 'Select CV'),
            items: [
              for (final cv in state.availableCvs)
                DropdownMenuItem(
                  value: cv.id,
                  child: Text('${cv.displayTitle} • ${cv.displayRole}'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton.secondary(
                label: 'Go to CV Builder',
                onPressed: onGoToBuilder,
                icon: Icons.description_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Open AI Improve',
                onPressed: onOpenAiImprove,
                icon: Icons.auto_fix_high_outlined,
                isExpanded: false,
              ),
              Chip(label: Text('${report.wordCount} words estimated')),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(ColorScheme scheme, int score) {
    if (score >= 80) {
      return const Color(0xFF0D6B44);
    }
    if (score >= 60) {
      return const Color(0xFF946200);
    }
    return scheme.error;
  }
}

class _JobPostMatchCard extends StatelessWidget {
  const _JobPostMatchCard({
    required this.state,
    required this.jobPostController,
    required this.onCheckMatch,
    required this.onCopySuggestions,
    required this.onApplyDetectedSkills,
  });

  final AtsCheckerState state;
  final TextEditingController jobPostController;
  final VoidCallback onCheckMatch;
  final VoidCallback? onCopySuggestions;
  final VoidCallback? onApplyDetectedSkills;

  @override
  Widget build(BuildContext context) {
    final match = state.jobMatchReport;
    final theme = Theme.of(context);
    final scoreTone = _scoreTone(
      theme.colorScheme,
      match?.matchPercentage ?? 0,
    );
    final scoreLabel = _scoreLabel(match?.matchPercentage ?? 0);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Post Match', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Paste a job post to compare important keywords with your CV content and uncover ATS-friendly suggestions.',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobPostController,
            label: 'Job post',
            hintText:
                'Paste responsibilities, required skills, tools, and keywords from the job post.',
            minLines: 6,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton(
                label: state.isCheckingJobMatch
                    ? 'Checking match...'
                    : state.hasCheckedJobMatch
                    ? 'Re-check match'
                    : 'Check match',
                onPressed: state.isCheckingJobMatch ? null : onCheckMatch,
                icon: Icons.fact_check_outlined,
                isExpanded: false,
              ),
              if (onCopySuggestions != null)
                CustomButton.secondary(
                  label: 'Copy suggestions',
                  onPressed: onCopySuggestions,
                  icon: Icons.copy_all_outlined,
                  isExpanded: false,
                ),
            ],
          ),
          if (state.isCheckingJobMatch) ...[
            const SizedBox(height: 18),
            const CustomLoadingView(
              message: 'Checking ATS-friendly job match...',
            ),
          ] else if (!state.hasJobPost) ...[
            const SizedBox(height: 18),
            Text(
              'Paste a full job post, then tap Check match to compare your CV against the role requirements.',
              style: theme.textTheme.bodySmall,
            ),
          ] else if (!state.hasCheckedJobMatch) ...[
            const SizedBox(height: 18),
            Text(
              'Ready to audit this job post. Tap Check match to extract keywords, calculate fit, and review honest improvement suggestions.',
              style: theme.textTheme.bodySmall,
            ),
          ] else if (match != null) ...[
            const SizedBox(height: 18),
            Text('Job match score', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${match.matchPercentage}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scoreTone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    scoreLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scoreTone,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: match.matchPercentage / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              color: scoreTone,
            ),
            const SizedBox(height: 14),
            Text(
              'Only add skills, tools, projects, or achievements that are true in your real background.',
              style: theme.textTheme.bodySmall,
            ),
            if (match.suggestedSectionsToImprove.isNotEmpty) ...[
              const SizedBox(height: 16),
              _KeywordWrap(
                title: 'Suggested sections to improve',
                keywords: match.suggestedSectionsToImprove,
                emptyLabel: 'No priority sections suggested.',
              ),
            ],
            const SizedBox(height: 16),
            _KeywordWrap(
              title: 'Extracted keywords',
              keywords: match.extractedKeywords,
            ),
            const SizedBox(height: 12),
            _KeywordWrap(
              title: 'Matched keywords',
              keywords: match.matchedKeywords,
              emptyLabel: 'No matched keywords yet.',
            ),
            const SizedBox(height: 12),
            _KeywordWrap(
              title: 'Missing keywords',
              keywords: match.missingKeywords,
              emptyLabel: 'No missing keywords detected.',
            ),
            const SizedBox(height: 12),
            _KeywordWrap(
              title: 'Detected skills you can add honestly',
              keywords: match.suggestedSkillsToAdd,
              emptyLabel: 'No additional already-supported skills detected.',
            ),
            if (onApplyDetectedSkills != null) ...[
              const SizedBox(height: 14),
              CustomButton.secondary(
                label: 'Apply detected skills to CV',
                onPressed: onApplyDetectedSkills,
                icon: Icons.playlist_add_check_outlined,
                isExpanded: false,
              ),
            ],
            if (match.issues.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final issue in match.issues) ...[
                _JobMatchInsightTile(issue: issue),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Color _scoreTone(ColorScheme scheme, int score) {
    if (score >= 75) {
      return const Color(0xFF0D6B44);
    }
    if (score >= 50) {
      return const Color(0xFF946200);
    }
    return scheme.error;
  }

  String _scoreLabel(int score) {
    if (score >= 75) {
      return 'Strong base. Fine-tune wording for a tighter role match.';
    }
    if (score >= 50) {
      return 'Moderate match. Update your strongest relevant sections before applying.';
    }
    return 'Low match. Rework your role-focused wording before sending this CV.';
  }
}

class _KeywordWrap extends StatelessWidget {
  const _KeywordWrap({
    required this.title,
    required this.keywords,
    this.emptyLabel = 'No items.',
  });

  final String title;
  final List<String> keywords;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (keywords.isEmpty)
          Text(emptyLabel, style: theme.textTheme.bodySmall)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final keyword in keywords) Chip(label: Text(keyword)),
            ],
          ),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({
    required this.state,
    required this.aiSuggestionController,
    required this.onTargetChanged,
    required this.onGenerate,
    required this.onApply,
    required this.onCopy,
    required this.onGoToBuilder,
    required this.onOpenAiImprove,
  });

  final AtsCheckerState state;
  final TextEditingController aiSuggestionController;
  final ValueChanged<AtsAiTarget> onTargetChanged;
  final VoidCallback onGenerate;
  final VoidCallback onApply;
  final VoidCallback onCopy;
  final VoidCallback onGoToBuilder;
  final VoidCallback onOpenAiImprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Optional AI improvement', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Use the existing mock AI service to generate an editable ATS-friendly summary or objective. Review before applying.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final target in AtsAiTarget.values)
                ChoiceChip(
                  label: Text(target.label),
                  selected: state.aiTarget == target,
                  onSelected: (_) => onTargetChanged(target),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton.secondary(
            label: state.isGeneratingAiSuggestion
                ? 'Generating...'
                : 'Improve with AI',
            onPressed: state.isGeneratingAiSuggestion ? null : onGenerate,
            icon: Icons.auto_awesome_outlined,
            isExpanded: false,
          ),
          if (state.hasAiSuggestion) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: aiSuggestionController,
              label: 'AI suggestion',
              minLines: 5,
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CustomButton.secondary(
                  label: 'Apply suggestion to CV',
                  onPressed: onApply,
                  icon: Icons.save_as_outlined,
                  isExpanded: false,
                ),
                CustomButton.secondary(
                  label: 'Copy suggestion',
                  onPressed: onCopy,
                  icon: Icons.copy_outlined,
                  isExpanded: false,
                ),
                CustomButton.secondary(
                  label: 'Go to CV Builder',
                  onPressed: onGoToBuilder,
                  icon: Icons.description_outlined,
                  isExpanded: false,
                ),
                CustomButton.secondary(
                  label: 'Open AI Improve',
                  onPressed: onOpenAiImprove,
                  icon: Icons.auto_fix_high_outlined,
                  isExpanded: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JobMatchInsightTile extends StatelessWidget {
  const _JobMatchInsightTile({required this.issue});

  final AtsCheckIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(issue.problem, style: theme.textTheme.titleSmall),
              ),
              AtsSeverityChip(severity: issue.severity),
            ],
          ),
          const SizedBox(height: 8),
          Text(issue.suggestion, style: theme.textTheme.bodyMedium),
          if (issue.exampleImprovement != null &&
              issue.exampleImprovement!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(issue.exampleImprovement!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.report, required this.jobMatchReport});

  final AtsCheckReport report;
  final AtsJobMatchReport? jobMatchReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      for (final category in AtsCheckCategory.values)
        (
          category,
          category == AtsCheckCategory.jobMatch
              ? (jobMatchReport?.issues ?? const <AtsCheckIssue>[])
              : report.issuesFor(category),
          category == AtsCheckCategory.jobMatch
              ? jobMatchReport?.matchPercentage
              : (report.categoryScores[category] ?? 100),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Results by category', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final entry in categories) ...[
          _CategoryCard(category: entry.$1, issues: entry.$2, score: entry.$3),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.issues,
    required this.score,
  });

  final AtsCheckCategory category;
  final List<AtsCheckIssue> issues;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasIssues = issues.isNotEmpty;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.label, style: theme.textTheme.titleMedium),
              ),
              Chip(
                label: Text(score == null ? 'Not checked' : '${score!}/100'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasIssues)
            Text(
              category == AtsCheckCategory.jobMatch
                  ? 'Paste a job post above to see job-match issues and keyword suggestions.'
                  : 'No major ATS-friendly issues found in this category right now.',
            )
          else
            Column(
              children: [
                for (final issue in issues) ...[
                  _IssueTile(issue: issue),
                  const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final AtsCheckIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(issue.problem, style: theme.textTheme.titleSmall),
            ),
            AtsSeverityChip(severity: issue.severity),
          ],
        ),
        const SizedBox(height: 8),
        Text(issue.suggestion, style: theme.textTheme.bodyMedium),
        if (issue.exampleImprovement != null &&
            issue.exampleImprovement!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              issue.exampleImprovement!,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
