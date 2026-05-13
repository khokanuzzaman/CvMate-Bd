import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_builder_stepper.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/education_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/experience_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/languages_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/personal_info_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/preview_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/projects_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/skills_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/summary_objective_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/template_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/training_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CvBuilderScreen extends ConsumerStatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  ConsumerState<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends ConsumerState<CvBuilderScreen> {
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cvBuilderControllerProvider.notifier).ensureDraftReady(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvBuilderControllerProvider);
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final currentStep = state.currentStep;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop) {
          return;
        }

        await notifier.flushAutosave();
        if (!context.mounted) {
          return;
        }

        final nextState = ref.read(cvBuilderControllerProvider);
        if (nextState.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(nextState.errorMessage!)));
          return;
        }

        setState(() => _allowPop = true);
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'CV Builder',
          actions: [
            IconButton(
              onPressed: state.isLoading
                  ? null
                  : () => _saveDraft(context, ref, showSuccess: true),
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save draft',
            ),
            IconButton(
              onPressed: state.isLoading ? null : () => _openAiImprove(context),
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'AI Improve',
            ),
            IconButton(
              onPressed: state.isLoading
                  ? null
                  : () => _openPreview(context, ref),
              icon: const Icon(Icons.preview_outlined),
              tooltip: 'Preview',
            ),
          ],
        ),
        body: SafeArea(child: _buildBody(context, state, currentStep)),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CvBuilderState state,
    CvBuilderStep currentStep,
  ) {
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    if (state.isLoading && !state.hasActiveDraft) {
      return const CustomLoadingView(message: 'Preparing your CV draft...');
    }

    if (!state.hasActiveDraft) {
      return CustomErrorView(
        title: 'No CV draft ready',
        message:
            state.errorMessage ??
            'Create a new CV or open a saved one from your CV list.',
        onRetry: notifier.ensureDraftReady,
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
              CustomCard(child: _BuilderStatusCard(state: state)),
              const SizedBox(height: 20),
              CustomCard(
                child: CvBuilderStepper(
                  currentStep: currentStep,
                  onStepSelected: notifier.goToStep,
                ),
              ),
              const SizedBox(height: 20),
              CustomCard(
                child: KeyedSubtree(
                  key: ValueKey('${state.draft.id}_${currentStep.name}'),
                  child: _stepWidget(
                    currentStep,
                    showValidationErrors: state.showValidationErrors,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!state.isFirstStep)
                    Expanded(
                      child: CustomButton.secondary(
                        label: 'Back',
                        icon: Icons.arrow_back_rounded,
                        onPressed: notifier.previousStep,
                      ),
                    ),
                  if (!state.isFirstStep) const SizedBox(width: 12),
                  Expanded(
                    child: currentStep.isPreview
                        ? CustomButton(
                            label: 'Open preview screen',
                            icon: Icons.open_in_full_rounded,
                            onPressed: () => _openPreview(context, ref),
                          )
                        : CustomButton(
                            label: 'Continue',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () {
                              final error = notifier.nextStep();
                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              }
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepWidget(CvBuilderStep step, {required bool showValidationErrors}) {
    return switch (step) {
      CvBuilderStep.personalInfo => PersonalInfoStep(
        showValidationErrors: showValidationErrors,
      ),
      CvBuilderStep.summaryObjective => SummaryObjectiveStep(
        showValidationErrors: showValidationErrors,
      ),
      CvBuilderStep.education => const EducationStep(),
      CvBuilderStep.experience => const ExperienceStep(),
      CvBuilderStep.skills => const SkillsStep(),
      CvBuilderStep.projects => const ProjectsStep(),
      CvBuilderStep.training => const TrainingStep(),
      CvBuilderStep.languages => const LanguagesStep(),
      CvBuilderStep.template => const TemplateStep(),
      CvBuilderStep.preview => const PreviewStep(),
    };
  }

  Future<void> _saveDraft(
    BuildContext context,
    WidgetRef ref, {
    bool showSuccess = false,
  }) async {
    await ref.read(cvBuilderControllerProvider.notifier).saveNow();
    final state = ref.read(cvBuilderControllerProvider);

    if (!context.mounted) {
      return;
    }

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }

    if (showSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV updated.')));
    }
  }

  Future<void> _openPreview(BuildContext context, WidgetRef ref) async {
    await _saveDraft(context, ref);
    final state = ref.read(cvBuilderControllerProvider);
    if (!context.mounted || state.errorMessage != null) {
      return;
    }

    context.push(RouteNames.cvPreviewPath);
  }

  Future<void> _openAiImprove(BuildContext context) async {
    await ref.read(cvBuilderControllerProvider.notifier).flushAutosave();
    final state = ref.read(cvBuilderControllerProvider);
    if (!context.mounted || state.errorMessage != null) {
      return;
    }

    context.push(RouteNames.aiImprovePath);
  }
}

class _BuilderStatusCard extends StatelessWidget {
  const _BuilderStatusCard({required this.state});

  final CvBuilderState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = _statusText(state);
    final statusColor = state.errorMessage != null
        ? theme.colorScheme.error
        : theme.textTheme.bodySmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(state.draft.displayTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(state.draft.displayRole, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
        ),
        if (state.isSaving) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  String _statusText(CvBuilderState state) {
    if (state.errorMessage != null) {
      return state.errorMessage!;
    }

    if (state.isSaving) {
      return 'Saving draft...';
    }

    if (state.hasUnsavedChanges) {
      return 'Unsaved changes. Autosave will run shortly.';
    }

    if (state.lastSavedAt != null) {
      return 'Draft saved at ${DateFormatter.shortTime(state.lastSavedAt!)}';
    }

    return 'Draft not saved yet.';
  }
}
