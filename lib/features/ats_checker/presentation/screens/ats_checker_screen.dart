import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/overflow_menu_button.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_fix_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_ai_sheet.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_issue_list.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_score_card.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_section_scores.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/cv_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// ATS check: the selected CV's rule-engine score, its per-section scores and
/// the issues to fix. Everything shown comes from [AtsCheckerController]; "Fix"
/// opens the matching builder step and "Check against a job post" continues in
/// the Tailor flow with this CV selected.
class AtsCheckerScreen extends ConsumerStatefulWidget {
  const AtsCheckerScreen({super.key});

  @override
  ConsumerState<AtsCheckerScreen> createState() => _AtsCheckerScreenState();
}

class _AtsCheckerScreenState extends ConsumerState<AtsCheckerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(atsCheckerControllerProvider.notifier).initialize(),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.homePath);
    }
  }

  Future<void> _pickCv(AtsCheckerState state) async {
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.selectedCvId,
    );
    if (id != null && mounted) {
      ref.read(atsCheckerControllerProvider.notifier).selectCv(id);
    }
  }

  /// Opens the builder on the step that resolves [issue], then re-checks.
  Future<void> _fix(CvProfile cv, AtsCheckIssue issue) async {
    await ref
        .read(cvBuilderControllerProvider.notifier)
        .loadDraft(cv.id, stepIndex: atsFixStep(issue.category).index);
    if (!mounted) {
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  Future<void> _openAiImprove(CvProfile cv) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cv.id);
    if (!mounted) {
      return;
    }
    await context.push(RouteNames.aiImprovePath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  Future<void> _createCvFirst() async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
    if (!mounted) {
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(atsCheckerControllerProvider.notifier).reload();
  }

  /// Job-match actions need a match report. The screen has no job-post field
  /// any more, so reuse the post pasted in Tailor; false when there is none.
  Future<bool> _ensureJobMatch() async {
    final ats = ref.read(atsCheckerControllerProvider.notifier);
    if (ref.read(atsCheckerControllerProvider).jobMatchReport != null) {
      return true;
    }
    final post = ref.read(tailoringControllerProvider).jobPostText.trim();
    if (post.isNotEmpty) {
      ats.updateJobPostText(post);
      await ats.checkJobMatch();
    }
    return ref.read(atsCheckerControllerProvider).jobMatchReport != null;
  }

  Future<void> _runJobMatchAction(
    Future<String?> Function(AtsCheckerController ats) action,
  ) async {
    final message = await _ensureJobMatch()
        ? await action(ref.read(atsCheckerControllerProvider.notifier))
        : AppStrings.atsNeedsJobPost;
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _checkAgainstJob(CvProfile cv) {
    ref.read(tailoringControllerProvider.notifier).selectCv(cv.id);
    context.push(RouteNames.tailoringPath);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(atsCheckerControllerProvider);
    final cv = state.selectedCv;
    final ready = state.report != null && cv != null;

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
              child: Row(
                children: [
                  Expanded(
                    child: AppTopBar(title: AppStrings.atsTitle, onBack: _back),
                  ),
                  if (ready)
                    OverflowMenuButton(
                      tooltip: AppStrings.tailorMoreOptions,
                      items: [
                        OverflowMenuItem(
                          label: AppStrings.atsMenuImproveWithAi,
                          icon: Icons.auto_awesome_outlined,
                          onSelected: () => showAtsAiSheet(context),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.atsMenuApplySkills,
                          icon: Icons.playlist_add_check_outlined,
                          onSelected: () => _runJobMatchAction(
                            (ats) => ats.applyDetectedSkillsToCv(),
                          ),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.atsMenuCopySuggestions,
                          icon: Icons.copy_all_outlined,
                          onSelected: () => _runJobMatchAction(
                            (ats) => ats.copyJobMatchSuggestions(),
                          ),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.atsMenuOpenAiImprove,
                          icon: Icons.auto_fix_high_outlined,
                          onSelected: () => _openAiImprove(cv),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody(state)),
            if (ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s8,
                  AppSpacing.screen,
                  AppSpacing.s16,
                ),
                child: PrimaryButton(
                  label: AppStrings.atsCheckAgainstJob,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => _checkAgainstJob(cv),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AtsCheckerState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: AppStrings.atsLoading);
    }

    if (state.errorMessage != null &&
        !state.hasSavedCvs &&
        state.hasInitialized) {
      return CustomErrorView(
        title: AppStrings.atsLoadErrorTitle,
        message: state.errorMessage!,
        onRetry: () => ref.read(atsCheckerControllerProvider.notifier).reload(),
      );
    }

    if (!state.hasSavedCvs) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s22),
        child: CustomEmptyState(
          title: AppStrings.atsNoCvTitle,
          message: AppStrings.atsNoCvBody,
          icon: Icons.fact_check_outlined,
          actionLabel: AppStrings.atsCreateCv,
          onAction: _createCvFirst,
        ),
      );
    }

    final report = state.report;
    final cv = state.selectedCv;
    if (report == null || cv == null) {
      return CustomErrorView(
        title: AppStrings.atsNoSelectionTitle,
        message: AppStrings.atsNoSelectionBody,
        onRetry: () => ref.read(atsCheckerControllerProvider.notifier).reload(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CvPickerCard(
            cv: cv,
            subtitle: AppStrings.atsCheckedNow,
            onTap: () => _pickCv(state),
          ),
          const SizedBox(height: AppSpacing.s14),
          AtsScoreCard(score: report.score, fixes: report.issues.length),
          const SizedBox(height: AppSpacing.s14),
          AtsSectionScores(scores: report.categoryScores),
          const SizedBox(height: AppSpacing.s20),
          const SectionLabel(AppStrings.atsWhatToFix),
          const SizedBox(height: AppSpacing.s8),
          AtsIssueList(
            issues: report.issues,
            onFix: (issue) => _fix(cv, issue),
          ),
          const SizedBox(height: AppSpacing.s14),
          Text(
            AppStrings.atsDisclaimer,
            style: AppTextStyles.hint,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
