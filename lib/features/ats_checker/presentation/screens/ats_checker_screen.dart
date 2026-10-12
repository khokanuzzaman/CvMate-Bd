import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_page.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/inline_error_card.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_ai_card.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_category_section.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_job_match_card.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_score_card.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// ATS Checker: the CV's rule-based score, job-post match, optional AI summary
/// and results by category. All work happens in [AtsCheckerController].
class AtsCheckerScreen extends ConsumerStatefulWidget {
  const AtsCheckerScreen({super.key});

  @override
  ConsumerState<AtsCheckerScreen> createState() => _AtsCheckerScreenState();
}

class _AtsCheckerScreenState extends ConsumerState<AtsCheckerScreen> {
  final _jobPost = TextEditingController();
  final _aiSuggestion = TextEditingController();

  AtsCheckerController get _controller =>
      ref.read(atsCheckerControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _jobPost.addListener(() => _controller.updateJobPostText(_jobPost.text));
    _aiSuggestion.addListener(
      () => _controller.updateAiSuggestionText(_aiSuggestion.text),
    );
    Future.microtask(() => _controller.initialize());
  }

  @override
  void dispose() {
    _jobPost.dispose();
    _aiSuggestion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(atsCheckerControllerProvider);
    _sync(_jobPost, state.jobPostText);
    _sync(_aiSuggestion, state.aiSuggestionText);

    return AppPage(
      title: AppStrings.atsTitle,
      onBack: () => context.pop(),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AtsCheckerState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: AppStrings.atsLoading);
    }

    if (state.errorMessage != null &&
        !state.hasSavedCvs &&
        state.hasInitialized) {
      return CustomErrorView(
        title: AppStrings.atsLoadErrorTitle,
        message: state.errorMessage!,
        onRetry: _controller.reload,
      );
    }

    if (!state.hasSavedCvs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s22),
          child: CustomEmptyState(
            title: AppStrings.atsNoCvTitle,
            message: AppStrings.atsNoCvBody,
            icon: Icons.fact_check_outlined,
            actionLabel: AppStrings.atsCreateCv,
            onAction: () => _createCvFirst(context),
          ),
        ),
      );
    }

    final report = state.report;
    final cv = state.selectedCv;
    if (report == null || cv == null) {
      return CustomErrorView(
        title: AppStrings.atsNoSelectionTitle,
        message: AppStrings.atsNoSelectionBody,
        onRetry: _controller.reload,
      );
    }

    final match = state.jobMatchReport;
    return AppPageScroll(
      children: [
        AtsScoreCard(
          report: report,
          cv: cv,
          onPickCv: () => _pickCv(state),
          onOpenBuilder: () =>
              _openRoute(context, cv, RouteNames.cvBuilderPath),
          onOpenAiImprove: () =>
              _openRoute(context, cv, RouteNames.aiImprovePath),
        ),
        const SizedBox(height: AppSpacing.s16),
        AtsJobMatchCard(
          state: state,
          jobPostController: _jobPost,
          onCheckMatch: _controller.checkJobMatch,
          onCopySuggestions: match == null
              ? null
              : () => _message(_controller.copyJobMatchSuggestions()),
          onApplyDetectedSkills:
              match == null || match.suggestedSkillsToAdd.isEmpty
              ? null
              : () => _message(_controller.applyDetectedSkillsToCv()),
        ),
        const SizedBox(height: AppSpacing.s16),
        AtsAiCard(
          state: state,
          suggestionController: _aiSuggestion,
          onTargetChanged: _controller.selectAiTarget,
          onGenerate: _controller.generateAiSuggestion,
          onApply: () => _message(_controller.applyAiSuggestionToCv()),
          onCopy: () => _message(_controller.copySuggestion()),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s16),
          InlineErrorCard(message: state.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.s20),
        AtsCategorySection(report: report, jobMatchReport: match),
      ],
    );
  }

  Future<void> _pickCv(AtsCheckerState state) async {
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.selectedCvId,
    );
    if (id != null && mounted) {
      _controller.selectCv(id);
    }
  }

  void _sync(TextEditingController controller, String value) {
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
    if (mounted) {
      await _controller.reload();
    }
  }

  /// Opens [path] (the builder or AI Improve) on [cv], then reloads, since
  /// either can change the CV.
  Future<void> _openRoute(
    BuildContext context,
    CvProfile cv,
    String path,
  ) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cv.id);
    if (!context.mounted) {
      return;
    }
    await context.push(path);
    if (mounted) {
      await _controller.reload();
    }
  }

  Future<void> _message(Future<String?> action) async {
    final message = await action;
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
