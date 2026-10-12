import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_page.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/inline_error_card.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_quick_prompts.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_quick_practice_card.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_results_card.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_sessions_card.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_setup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Interview Prep: setup, recent sessions, quick practice and the generated
/// set with editable answers. All work happens in [InterviewPrepController].
class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  final _jobPost = TextEditingController();

  InterviewPrepController get _controller =>
      ref.read(interviewPrepControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _jobTitle.addListener(
      () => _controller.updateTargetJobTitle(_jobTitle.text),
    );
    _company.addListener(() => _controller.updateCompanyName(_company.text));
    _jobPost.addListener(() => _controller.updateJobPostText(_jobPost.text));
    Future.microtask(() => _controller.initialize());
  }

  @override
  void dispose() {
    _jobTitle.dispose();
    _company.dispose();
    _jobPost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewPrepControllerProvider);
    _sync(_jobTitle, state.targetJobTitle);
    _sync(_company, state.companyName);
    _sync(_jobPost, state.jobPostText);

    return AppPage(
      title: AppStrings.interviewTitle,
      onBack: () => context.pop(),
      trailingIcon: Icons.restart_alt_rounded,
      trailingTooltip: AppStrings.commonStartOver,
      onTrailingTap: _controller.startOver,
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, InterviewPrepState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: AppStrings.interviewLoading);
    }

    if (state.errorMessage != null &&
        !state.hasInitialized &&
        !state.hasSavedCvs) {
      return CustomErrorView(
        title: AppStrings.interviewLoadErrorTitle,
        message: state.errorMessage!,
        onRetry: _controller.reload,
      );
    }

    final cv = state.selectedCv;
    return AppPageScroll(
      children: [
        if (!state.hasSavedCvs) ...[
          AppCard(
            child: CustomEmptyState(
              title: AppStrings.interviewNoCvTitle,
              message: AppStrings.interviewNoCvBody,
              icon: Icons.record_voice_over_outlined,
              actionLabel: AppStrings.interviewCreateCv,
              onAction: () => _createCvFirst(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        if (state.hasRecentSessions) ...[
          InterviewSessionsCard(
            sessions: state.recentSessions,
            onOpen: _controller.loadSession,
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        InterviewSetupCard(
          state: state,
          form: InterviewFormControllers(
            jobTitle: _jobTitle,
            company: _company,
            jobPost: _jobPost,
          ),
          onPickCv: () => _pickCv(state),
          onInterviewTypeChanged: _controller.selectInterviewType,
          onLanguageChanged: _controller.selectLanguage,
          onAnswerStyleChanged: _controller.selectAnswerStyle,
          onGenerate: _controller.generateQuestions,
          onOpenBuilder: () => _openBuilder(context, state),
          onOpenAiImprove: cv == null
              ? null
              : () => _openAiImprove(context, cv),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s16),
          InlineErrorCard(message: state.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.s16),
        InterviewQuickPracticeCard(
          prompts: quickPracticePrompts(state.language),
          onCopy: _copyQuestionText,
        ),
        const SizedBox(height: AppSpacing.s20),
        if (state.isGenerating)
          const AppCard(
            child: CustomLoadingView(
              message: AppStrings.interviewGeneratingMessage,
            ),
          )
        else if (!state.hasGeneratedQuestions)
          const AppCard(
            child: CustomEmptyState(
              title: AppStrings.interviewEmptyTitle,
              message: AppStrings.interviewEmptyBody,
              icon: Icons.quiz_outlined,
            ),
          )
        else
          InterviewResultsCard(
            state: state,
            onCopyAllQuestions: () => _message(_controller.copyAllQuestions()),
            onCopyAllAnswers: () => _message(_controller.copyAllAnswers()),
            onSaveSession: () => _message(_controller.saveSession()),
            onStartOver: _controller.startOver,
            onCopyQuestion: (id) => _message(_controller.copyQuestion(id)),
            onCopyAnswer: (id) => _message(_controller.copyAnswer(id)),
            onToggleFavorite: _controller.toggleFavorite,
            onAnswerChanged: _controller.updateAnswer,
          ),
      ],
    );
  }

  Future<void> _pickCv(InterviewPrepState state) async {
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.selectedCvId,
      noneLabel: AppStrings.interviewNoCv,
    );
    if (id != null && mounted) {
      _controller.selectCv(id == kNoCvChoice ? null : id);
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

  /// The builder for the selected CV; the CV list when none is selected; the
  /// new-CV flow when there are no CVs at all.
  Future<void> _openBuilder(
    BuildContext context,
    InterviewPrepState state,
  ) async {
    final cv = state.selectedCv;
    if (cv != null) {
      await _openRoute(context, cv, RouteNames.cvBuilderPath);
    } else if (state.hasSavedCvs) {
      await context.push(RouteNames.cvListPath);
      if (mounted) {
        await _controller.reload();
      }
    } else {
      await _createCvFirst(context);
    }
  }

  Future<void> _openAiImprove(BuildContext context, CvProfile cv) =>
      _openRoute(context, cv, RouteNames.aiImprovePath);

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

  Future<void> _copyQuestionText(String text) {
    return _message(_copyPlain(text));
  }

  Future<String?> _copyPlain(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return AppStrings.interviewQuestionCopied;
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
