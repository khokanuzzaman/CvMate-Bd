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
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const String _manualInterviewCvSelectionValue = '__manual_interview_cv__';

class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  final TextEditingController _targetJobTitleController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _jobPostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetJobTitleController.addListener(_handleTargetJobTitleChanged);
    _companyNameController.addListener(_handleCompanyNameChanged);
    _jobPostController.addListener(_handleJobPostChanged);
    Future.microtask(
      () => ref.read(interviewPrepControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _targetJobTitleController
      ..removeListener(_handleTargetJobTitleChanged)
      ..dispose();
    _companyNameController
      ..removeListener(_handleCompanyNameChanged)
      ..dispose();
    _jobPostController
      ..removeListener(_handleJobPostChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewPrepControllerProvider);
    _syncController(_targetJobTitleController, state.targetJobTitle);
    _syncController(_companyNameController, state.companyName);
    _syncController(_jobPostController, state.jobPostText);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Interview Prep',
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(interviewPrepControllerProvider.notifier).startOver(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Start over',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, InterviewPrepState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(
        message: 'Loading interview prep tools and saved sessions...',
      );
    }

    if (state.errorMessage != null &&
        !state.hasInitialized &&
        !state.hasSavedCvs) {
      return CustomErrorView(
        title: 'Could not load Interview Prep',
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(interviewPrepControllerProvider.notifier).reload(),
      );
    }

    final selectedCv = state.selectedCv;
    final quickPractice = _quickPracticePrompts(state.language);

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
              if (!state.hasSavedCvs)
                CustomCard(
                  child: CustomEmptyState(
                    title: 'No saved CV yet',
                    message:
                        'You can still practice manually with a target role and job post, but creating a CV will make interview prep more personalized.',
                    icon: Icons.record_voice_over_outlined,
                    actionLabel: 'Create CV',
                    onAction: () => _createCvFirst(context),
                  ),
                )
              else
                _HeaderCard(
                  state: state,
                  onOpenCvBuilder: selectedCv == null
                      ? null
                      : () => _openCvBuilder(context, selectedCv),
                  onOpenAiImprove: selectedCv == null
                      ? null
                      : () => _openAiImprove(context, selectedCv),
                ),
              const SizedBox(height: 20),
              if (state.hasRecentSessions) ...[
                _RecentSessionsCard(
                  sessions: state.recentSessions,
                  onOpenSession: (sessionId) => ref
                      .read(interviewPrepControllerProvider.notifier)
                      .loadSession(sessionId),
                ),
                const SizedBox(height: 20),
              ],
              _InputCard(
                state: state,
                targetJobTitleController: _targetJobTitleController,
                companyNameController: _companyNameController,
                jobPostController: _jobPostController,
                onCvChanged: (value) {
                  ref
                      .read(interviewPrepControllerProvider.notifier)
                      .selectCv(
                        value == null ||
                                value == _manualInterviewCvSelectionValue
                            ? null
                            : value,
                      );
                },
                onInterviewTypeChanged: (value) => ref
                    .read(interviewPrepControllerProvider.notifier)
                    .selectInterviewType(value),
                onLanguageChanged: (value) => ref
                    .read(interviewPrepControllerProvider.notifier)
                    .selectLanguage(value),
                onAnswerStyleChanged: (value) => ref
                    .read(interviewPrepControllerProvider.notifier)
                    .selectAnswerStyle(value),
                onGenerate: () => ref
                    .read(interviewPrepControllerProvider.notifier)
                    .generateQuestions(),
                onGoToBuilder: () => _openBuilderRoute(context, state),
                onOpenAiImprove: selectedCv == null
                    ? null
                    : () => _openAiImprove(context, selectedCv),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                _InlineErrorCard(message: state.errorMessage!),
              ],
              const SizedBox(height: 20),
              _QuickPracticeCard(
                prompts: quickPractice,
                onCopy: (text) => _showActionMessage(_copyPlainText(text)),
              ),
              const SizedBox(height: 20),
              if (state.isGenerating)
                const CustomCard(
                  child: CustomLoadingView(
                    message: 'Generating interview questions...',
                  ),
                )
              else if (!state.hasGeneratedQuestions)
                const CustomCard(
                  child: CustomEmptyState(
                    title: 'No interview set generated yet',
                    message:
                        'Select a CV or enter a target role, then generate an interview prep set to start practicing.',
                    icon: Icons.quiz_outlined,
                  ),
                )
              else
                _ResultsCard(
                  state: state,
                  onCopyAllQuestions: () => _showActionMessage(
                    ref
                        .read(interviewPrepControllerProvider.notifier)
                        .copyAllQuestions(),
                  ),
                  onCopyAllAnswers: () => _showActionMessage(
                    ref
                        .read(interviewPrepControllerProvider.notifier)
                        .copyAllAnswers(),
                  ),
                  onSaveSession: () => _showActionMessage(
                    ref
                        .read(interviewPrepControllerProvider.notifier)
                        .saveSession(),
                  ),
                  onStartOver: () => ref
                      .read(interviewPrepControllerProvider.notifier)
                      .startOver(),
                  onCopyQuestion: (questionId) => _showActionMessage(
                    ref
                        .read(interviewPrepControllerProvider.notifier)
                        .copyQuestion(questionId),
                  ),
                  onCopyAnswer: (questionId) => _showActionMessage(
                    ref
                        .read(interviewPrepControllerProvider.notifier)
                        .copyAnswer(questionId),
                  ),
                  onToggleFavorite: (questionId) => ref
                      .read(interviewPrepControllerProvider.notifier)
                      .toggleFavorite(questionId),
                  onAnswerChanged: (questionId, value) => ref
                      .read(interviewPrepControllerProvider.notifier)
                      .updateAnswer(questionId, value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTargetJobTitleChanged() {
    ref
        .read(interviewPrepControllerProvider.notifier)
        .updateTargetJobTitle(_targetJobTitleController.text);
  }

  void _handleCompanyNameChanged() {
    ref
        .read(interviewPrepControllerProvider.notifier)
        .updateCompanyName(_companyNameController.text);
  }

  void _handleJobPostChanged() {
    ref
        .read(interviewPrepControllerProvider.notifier)
        .updateJobPostText(_jobPostController.text);
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
    await ref.read(interviewPrepControllerProvider.notifier).reload();
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
    await ref.read(interviewPrepControllerProvider.notifier).reload();
  }

  Future<void> _openBuilderRoute(
    BuildContext context,
    InterviewPrepState state,
  ) async {
    final selectedCv = state.selectedCv;
    if (selectedCv != null) {
      await _openCvBuilder(context, selectedCv);
      return;
    }

    if (state.hasSavedCvs) {
      await context.push(RouteNames.cvListPath);
      if (!mounted) {
        return;
      }
      await ref.read(interviewPrepControllerProvider.notifier).reload();
      return;
    }

    await _createCvFirst(context);
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
    await ref.read(interviewPrepControllerProvider.notifier).reload();
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

  Future<String?> _copyPlainText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return 'Question copied.';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.state,
    required this.onOpenCvBuilder,
    required this.onOpenAiImprove,
  });

  final InterviewPrepState state;
  final VoidCallback? onOpenCvBuilder;
  final VoidCallback? onOpenAiImprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized interview practice',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Use a saved CV or manual role details to prepare HR, technical, behavioral, and company-based interview questions in English or Bangla.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (onOpenCvBuilder != null)
                CustomButton.secondary(
                  label: 'Go to CV Builder',
                  onPressed: onOpenCvBuilder,
                  icon: Icons.description_outlined,
                  isExpanded: false,
                ),
              if (onOpenAiImprove != null)
                CustomButton.secondary(
                  label: 'Open AI Improve',
                  onPressed: onOpenAiImprove,
                  icon: Icons.auto_fix_high_outlined,
                  isExpanded: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({
    required this.sessions,
    required this.onOpenSession,
  });

  final List<InterviewPrepSession> sessions;
  final ValueChanged<String> onOpenSession;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (
            var index = 0;
            index < sessions.length && index < 4;
            index++
          ) ...[
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(sessions[index].displayTitle),
              subtitle: Text(
                '${sessions[index].displaySubtitle}\nUpdated ${DateFormatter.shortDateTime(sessions[index].updatedAt)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpenSession(sessions[index].id),
            ),
            if (index < sessions.length - 1 && index < 3)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.state,
    required this.targetJobTitleController,
    required this.companyNameController,
    required this.jobPostController,
    required this.onCvChanged,
    required this.onInterviewTypeChanged,
    required this.onLanguageChanged,
    required this.onAnswerStyleChanged,
    required this.onGenerate,
    required this.onGoToBuilder,
    required this.onOpenAiImprove,
  });

  final InterviewPrepState state;
  final TextEditingController targetJobTitleController;
  final TextEditingController companyNameController;
  final TextEditingController jobPostController;
  final ValueChanged<String?> onCvChanged;
  final ValueChanged<InterviewType> onInterviewTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<InterviewAnswerStyle> onAnswerStyleChanged;
  final VoidCallback onGenerate;
  final VoidCallback onGoToBuilder;
  final VoidCallback? onOpenAiImprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interview setup', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Choose a saved CV for personalized questions, or continue manually with your target role and job details.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue:
                state.selectedCvId ?? _manualInterviewCvSelectionValue,
            onChanged: onCvChanged,
            decoration: const InputDecoration(labelText: 'Select CV'),
            items: [
              const DropdownMenuItem(
                value: _manualInterviewCvSelectionValue,
                child: Text('Continue without CV'),
              ),
              for (final cv in state.availableCvs)
                DropdownMenuItem(
                  value: cv.id,
                  child: Text('${cv.displayTitle} • ${cv.displayRole}'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: targetJobTitleController,
            label: 'Target job title',
            hintText: 'Example: Flutter Developer',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: companyNameController,
            label: 'Company name, optional',
            hintText: 'Example: CareerMate BD',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobPostController,
            label: 'Job post/details, optional',
            hintText:
                'Paste responsibilities, required skills, interview expectations, or role context.',
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 18),
          Text('Interview type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final type in InterviewType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: state.interviewType == type,
                  onSelected: (_) => onInterviewTypeChanged(type),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Language', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final language in AiOutputLanguage.values)
                ChoiceChip(
                  label: Text(
                    language == AiOutputLanguage.english ? 'English' : 'Bangla',
                  ),
                  selected: state.language == language,
                  onSelected: (_) => onLanguageChanged(language),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Answer style', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final style in InterviewAnswerStyle.values)
                ChoiceChip(
                  label: Text(style.label),
                  selected: state.answerStyle == style,
                  onSelected: (_) => onAnswerStyleChanged(style),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton(
                label: state.isGenerating
                    ? 'Generating...'
                    : 'Generate interview questions',
                onPressed: state.isGenerating ? null : onGenerate,
                icon: Icons.auto_awesome_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: !state.hasSavedCvs
                    ? 'Create CV'
                    : state.selectedCv == null
                    ? 'Open CV List'
                    : 'Go to CV Builder',
                onPressed: onGoToBuilder,
                icon: Icons.description_outlined,
                isExpanded: false,
              ),
              if (onOpenAiImprove != null)
                CustomButton.secondary(
                  label: 'Go to AI Improve',
                  onPressed: onOpenAiImprove,
                  icon: Icons.auto_fix_high_outlined,
                  isExpanded: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickPracticeCard extends StatelessWidget {
  const _QuickPracticeCard({required this.prompts, required this.onCopy});

  final List<_QuickPracticePrompt> prompts;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common quick practice', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Use these built-in questions anytime, even before generating a personalized interview set.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < prompts.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompts[index].question,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prompts[index].tip,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onCopy(prompts[index].question),
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy question',
                ),
              ],
            ),
            if (index < prompts.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.state,
    required this.onCopyAllQuestions,
    required this.onCopyAllAnswers,
    required this.onSaveSession,
    required this.onStartOver,
    required this.onCopyQuestion,
    required this.onCopyAnswer,
    required this.onToggleFavorite,
    required this.onAnswerChanged,
  });

  final InterviewPrepState state;
  final VoidCallback onCopyAllQuestions;
  final VoidCallback onCopyAllAnswers;
  final VoidCallback onSaveSession;
  final VoidCallback onStartOver;
  final ValueChanged<String> onCopyQuestion;
  final ValueChanged<String> onCopyAnswer;
  final ValueChanged<String> onToggleFavorite;
  final void Function(String questionId, String value) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated interview set', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Answers are editable. Review everything before using it in a real interview, and do not claim false skills or experience.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton.secondary(
                label: 'Copy all questions',
                onPressed: onCopyAllQuestions,
                icon: Icons.list_alt_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Copy all answers',
                onPressed: onCopyAllAnswers,
                icon: Icons.copy_all_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: state.isSavingSession ? 'Saving...' : 'Save session',
                onPressed: state.isSavingSession ? null : onSaveSession,
                icon: Icons.save_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Start over',
                onPressed: onStartOver,
                icon: Icons.refresh_rounded,
                isExpanded: false,
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final category in InterviewQuestionCategory.values) ...[
            if (_questionsForCategory(
              state.questions,
              category,
            ).isNotEmpty) ...[
              Text(category.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final question in _questionsForCategory(
                state.questions,
                category,
              )) ...[
                _InterviewQuestionTile(
                  question: question,
                  onCopyQuestion: () => onCopyQuestion(question.id),
                  onCopyAnswer: () => onCopyAnswer(question.id),
                  onToggleFavorite: () => onToggleFavorite(question.id),
                  onAnswerChanged: (value) =>
                      onAnswerChanged(question.id, value),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  List<InterviewPrepQuestion> _questionsForCategory(
    List<InterviewPrepQuestion> questions,
    InterviewQuestionCategory category,
  ) {
    return questions.where((item) => item.category == category).toList();
  }
}

class _InterviewQuestionTile extends StatefulWidget {
  const _InterviewQuestionTile({
    required this.question,
    required this.onCopyQuestion,
    required this.onCopyAnswer,
    required this.onToggleFavorite,
    required this.onAnswerChanged,
  });

  final InterviewPrepQuestion question;
  final VoidCallback onCopyQuestion;
  final VoidCallback onCopyAnswer;
  final VoidCallback onToggleFavorite;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<_InterviewQuestionTile> createState() => _InterviewQuestionTileState();
}

class _InterviewQuestionTileState extends State<_InterviewQuestionTile> {
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(text: widget.question.answerText)
      ..addListener(_handleAnswerChanged);
  }

  @override
  void didUpdateWidget(covariant _InterviewQuestionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_answerController.text == widget.question.answerText) {
      return;
    }
    _answerController.value = TextEditingValue(
      text: widget.question.answerText,
      selection: TextSelection.collapsed(
        offset: widget.question.answerText.length,
      ),
    );
  }

  @override
  void dispose() {
    _answerController
      ..removeListener(_handleAnswerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            if (widget.question.isFavorite) ...[
              Icon(
                Icons.star_rounded,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.question.question,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        subtitle: Text(widget.question.whyItMatters),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer tip: ${widget.question.answerTip}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _answerController,
            label: 'Editable sample answer',
            minLines: 4,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton.secondary(
                label: 'Copy question',
                onPressed: widget.onCopyQuestion,
                icon: Icons.copy_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Copy answer',
                onPressed: widget.onCopyAnswer,
                icon: Icons.copy_all_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: widget.question.isFavorite
                    ? 'Unfavorite'
                    : 'Save favorite',
                onPressed: widget.onToggleFavorite,
                icon: widget.question.isFavorite
                    ? Icons.star_outline_rounded
                    : Icons.star_border_rounded,
                isExpanded: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAnswerChanged() {
    widget.onAnswerChanged(_answerController.text);
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _QuickPracticePrompt {
  const _QuickPracticePrompt({required this.question, required this.tip});

  final String question;
  final String tip;
}

List<_QuickPracticePrompt> _quickPracticePrompts(AiOutputLanguage language) {
  if (language == AiOutputLanguage.bangla) {
    return const [
      _QuickPracticePrompt(
        question: 'নিজের সম্পর্কে বলুন।',
        tip: 'বর্তমান ফোকাস, স্কিল, এবং প্রাসঙ্গিক প্রজেক্ট দিয়ে শুরু করুন।',
      ),
      _QuickPracticePrompt(
        question: 'আমরা আপনাকে কেন নিয়োগ দেব?',
        tip: 'একটি নির্দিষ্ট শক্তি এবং role-fit স্পষ্টভাবে বলুন।',
      ),
      _QuickPracticePrompt(
        question: 'আপনার strengths কী?',
        tip: 'একটি strength বেছে নিয়ে উদাহরণ দিন।',
      ),
      _QuickPracticePrompt(
        question: 'আপনার weaknesses কী?',
        tip: 'Honest থাকুন এবং improvement plan বলুন।',
      ),
      _QuickPracticePrompt(
        question: 'আপনি এই চাকরি কেন চান?',
        tip: 'Role, company, এবং শেখার লক্ষ্যকে যুক্ত করুন।',
      ),
      _QuickPracticePrompt(
        question: 'আপনার CV-এর একটি project ব্যাখ্যা করুন।',
        tip: 'Problem, role, tools, result format ব্যবহার করুন।',
      ),
      _QuickPracticePrompt(
        question: 'আপনার expected salary কী?',
        tip: 'Range দিলে context-সহ দিন, rigid না শোনায় এমনভাবে।',
      ),
      _QuickPracticePrompt(
        question: 'আপনার কি আমাদের জন্য কোনো প্রশ্ন আছে?',
        tip: 'Team, role expectations, বা success measure নিয়ে প্রশ্ন করুন।',
      ),
    ];
  }

  return const [
    _QuickPracticePrompt(
      question: 'Tell me about yourself.',
      tip:
          'Start with your current focus, skills, and one relevant project or responsibility.',
    ),
    _QuickPracticePrompt(
      question: 'Why should we hire you?',
      tip: 'Show one clear strength and how it fits the role.',
    ),
    _QuickPracticePrompt(
      question: 'What are your strengths?',
      tip: 'Choose one strength and support it with a practical example.',
    ),
    _QuickPracticePrompt(
      question: 'What are your weaknesses?',
      tip: 'Be honest and explain how you are improving it.',
    ),
    _QuickPracticePrompt(
      question: 'Why do you want this job?',
      tip: 'Connect the role to your skills, learning path, and motivation.',
    ),
    _QuickPracticePrompt(
      question: 'Explain one project from your CV.',
      tip: 'Use a simple problem, role, tools, result structure.',
    ),
    _QuickPracticePrompt(
      question: 'What is your expected salary?',
      tip: 'Give a realistic range if needed and stay flexible.',
    ),
    _QuickPracticePrompt(
      question: 'Do you have any questions for us?',
      tip: 'Ask about team expectations, success metrics, or growth.',
    ),
  ];
}
