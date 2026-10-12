import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/overflow_menu_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_practice_sheet.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_questions_view.dart';
import 'package:careermatebd/features/interview_prep/presentation/widgets/interview_setup_view.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Interview prep: set up a practice set (CV, role, type, language, style),
/// then work through the generated questions. All state and generation live in
/// [InterviewPrepController]; this screen only presents them.
class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(interviewPrepControllerProvider.notifier).initialize(),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.homePath);
    }
  }

  void _snack(String? message) {
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyQuickQuestion(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _snack(AppStrings.interviewQuestionCopied);
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
    await ref.read(interviewPrepControllerProvider.notifier).reload();
  }

  /// "বাংলায় দেখো" / "Show in English": regenerates the set in the other
  /// language through the controller's existing language option.
  Future<void> _toggleLanguage() async {
    final controller = ref.read(interviewPrepControllerProvider.notifier);
    if (controller.hasEditedAnswers && !await _confirmReplaceAnswers()) {
      return;
    }
    final toBangla =
        ref.read(interviewPrepControllerProvider).language ==
        AiOutputLanguage.english;
    controller.selectLanguage(
      toBangla ? AiOutputLanguage.bangla : AiOutputLanguage.english,
    );
    await controller.generateQuestions();
    if (ref.read(interviewPrepControllerProvider).errorMessage == null) {
      _snack(
        toBangla
            ? AppStrings.interviewRegeneratedBangla
            : AppStrings.interviewRegeneratedEnglish,
      );
    }
  }

  /// Regenerating replaces every answer; ask first when some were edited.
  Future<bool> _confirmReplaceAnswers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.interviewReplaceEditedTitle),
        content: const Text(AppStrings.interviewReplaceEditedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.interviewReplaceEditedCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.interviewReplaceEditedContinue),
          ),
        ],
      ),
    );
    return confirmed == true && mounted;
  }

  Future<void> _generateMore() async {
    final controller = ref.read(interviewPrepControllerProvider.notifier);
    final added = await controller.generateMoreQuestions();
    final error = ref.read(interviewPrepControllerProvider).errorMessage;
    _snack(
      error ??
          (added == 0
              ? AppStrings.interviewNoNewQuestions
              : AppStrings.interviewMoreAdded(added)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewPrepControllerProvider);
    final controller = ref.read(interviewPrepControllerProvider.notifier);
    final hasQuestions = state.hasGeneratedQuestions;

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
                    child: AppTopBar(
                      title: AppStrings.interviewTitle,
                      onBack: _back,
                    ),
                  ),
                  if (hasQuestions)
                    OverflowMenuButton(
                      tooltip: AppStrings.interviewMoreOptions,
                      items: [
                        OverflowMenuItem(
                          label: AppStrings.interviewSaveSession,
                          icon: Icons.save_outlined,
                          onSelected: () =>
                              controller.saveSession().then(_snack),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.interviewCopyAllQuestions,
                          icon: Icons.list_alt_outlined,
                          onSelected: () =>
                              controller.copyAllQuestions().then(_snack),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.interviewCopyAllAnswers,
                          icon: Icons.copy_all_outlined,
                          onSelected: () =>
                              controller.copyAllAnswers().then(_snack),
                        ),
                        OverflowMenuItem(
                          label: AppStrings.interviewStartOver,
                          icon: Icons.restart_alt_rounded,
                          onSelected: controller.startOver,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody(state)),
            _buildFooter(state),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InterviewPrepState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: AppStrings.interviewLoading);
    }

    if (state.errorMessage != null &&
        !state.hasInitialized &&
        !state.hasSavedCvs) {
      return CustomErrorView(
        title: AppStrings.interviewLoadErrorTitle,
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(interviewPrepControllerProvider.notifier).reload(),
      );
    }

    if (state.hasGeneratedQuestions) {
      return InterviewQuestionsView(
        contextLabel: AppStrings.interviewContext(
          fromCv: state.selectedCv != null,
          role: state.targetJobTitle.trim(),
          company: state.companyName.trim(),
        ),
        questions: state.questions,
        showBanglaAction: state.language == AiOutputLanguage.english,
        busy: state.isGenerating,
        errorMessage: state.errorMessage,
        onPractice: (question) =>
            showInterviewPracticeSheet(context, questionId: question.id),
        onToggleLanguage: _toggleLanguage,
      );
    }

    if (state.isGenerating) {
      return const CustomLoadingView(message: AppStrings.interviewGenerating);
    }

    return InterviewSetupView(
      state: state,
      onCreateCv: _createCvFirst,
      onCopyQuickQuestion: _copyQuickQuestion,
    );
  }

  Widget _buildFooter(InterviewPrepState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const SizedBox.shrink();
    }

    final hasQuestions = state.hasGeneratedQuestions;
    final controller = ref.read(interviewPrepControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      child: PrimaryButton(
        label: state.isGenerating
            ? AppStrings.interviewGenerating
            : hasQuestions
            ? AppStrings.interviewGenerateMore
            : AppStrings.interviewGenerate,
        leadingIcon: Icons.auto_awesome_outlined,
        onPressed: state.isGenerating || (!hasQuestions && !state.canGenerate)
            ? null
            : hasQuestions
            ? _generateMore
            : controller.generateQuestions,
      ),
    );
  }
}
