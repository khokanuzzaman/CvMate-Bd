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
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AiImproveScreen extends ConsumerStatefulWidget {
  const AiImproveScreen({super.key});

  @override
  ConsumerState<AiImproveScreen> createState() => _AiImproveScreenState();
}

class _AiImproveScreenState extends ConsumerState<AiImproveScreen> {
  final TextEditingController _currentInputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentInputController.addListener(_handleCurrentInputChanged);
    _outputController.addListener(_handleOutputChanged);
    Future.microtask(
      () => ref.read(aiImproveControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _currentInputController
      ..removeListener(_handleCurrentInputChanged)
      ..dispose();
    _outputController
      ..removeListener(_handleOutputChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiImproveControllerProvider);
    _syncController(_currentInputController, state.currentInput);
    _syncController(_outputController, state.generatedOutput);

    return Scaffold(
      appBar: const CustomAppBar(title: 'AI Improve'),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, AiImproveState state) {
    final selectedCv = state.selectedCv;

    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(
        message: 'Loading saved CVs and AI tools...',
      );
    }

    if (state.errorMessage != null &&
        !state.hasSavedCvs &&
        state.hasInitialized) {
      return CustomErrorView(
        title: 'Could not load AI Improve data',
        message: state.errorMessage!,
        onRetry: () => ref.read(aiImproveControllerProvider.notifier).reload(),
      );
    }

    if (!state.hasSavedCvs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CustomEmptyState(
            title: 'No CV available yet',
            message:
                'Create your first CV before using AI Improve. Saved CVs will appear here for summary, objective, project, and skill improvements.',
            icon: Icons.auto_awesome_outlined,
            actionLabel: 'Create CV',
            onAction: () => _createCvFirst(context),
          ),
        ),
      );
    }

    if (selectedCv == null) {
      return CustomErrorView(
        title: 'No CV selected',
        message: 'Please reload the screen and select a saved CV.',
        onRetry: () => ref.read(aiImproveControllerProvider.notifier).reload(),
      );
    }

    final requiresExperience = state.improvementType.needsExperienceSelection;
    final requiresProject = state.improvementType.needsProjectSelection;
    final missingExperience =
        requiresExperience && selectedCv.experiences.isEmpty;
    final missingProject = requiresProject && selectedCv.projects.isEmpty;
    final generationBlocked = missingExperience || missingProject;

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
              _CvSelectionCard(
                state: state,
                onCvChanged: (cvId) {
                  if (cvId != null) {
                    ref
                        .read(aiImproveControllerProvider.notifier)
                        .selectCv(cvId);
                  }
                },
                onOpenBuilder: () => _openBuilder(context, selectedCv.id),
                onOpenPreview: () => _openPreview(context, selectedCv.id),
              ),
              const SizedBox(height: 20),
              _ImprovementSetupCard(
                state: state,
                onTypeChanged: (type) {
                  if (type != null) {
                    ref
                        .read(aiImproveControllerProvider.notifier)
                        .selectImprovementType(type);
                  }
                },
                onLanguageChanged: (language) => ref
                    .read(aiImproveControllerProvider.notifier)
                    .selectOutputLanguage(language),
                onToneChanged: (tone) => ref
                    .read(aiImproveControllerProvider.notifier)
                    .selectTone(tone),
              ),
              const SizedBox(height: 20),
              if (requiresExperience)
                _ExperienceSelectorCard(
                  state: state,
                  onExperienceChanged: (experienceId) {
                    if (experienceId != null) {
                      ref
                          .read(aiImproveControllerProvider.notifier)
                          .selectExperience(experienceId);
                    }
                  },
                  onBulletChanged: (index) {
                    if (index != null) {
                      ref
                          .read(aiImproveControllerProvider.notifier)
                          .selectExperienceBulletIndex(index);
                    }
                  },
                ),
              if (requiresExperience) const SizedBox(height: 20),
              if (requiresProject)
                _ProjectSelectorCard(
                  state: state,
                  onProjectChanged: (projectId) {
                    if (projectId != null) {
                      ref
                          .read(aiImproveControllerProvider.notifier)
                          .selectProject(projectId);
                    }
                  },
                ),
              if (requiresProject) const SizedBox(height: 20),
              if (generationBlocked)
                CustomCard(
                  child: CustomEmptyState(
                    title: 'This section needs more CV content',
                    message: state.improvementType.emptyRequirementMessage,
                    icon: Icons.note_add_outlined,
                    actionLabel: 'Open CV Builder',
                    onAction: () => _openBuilder(context, selectedCv.id),
                  ),
                )
              else
                _InputCard(
                  state: state,
                  currentInputController: _currentInputController,
                  onGenerate: () => ref
                      .read(aiImproveControllerProvider.notifier)
                      .generateSuggestion(),
                ),
              const SizedBox(height: 20),
              if (state.errorMessage != null)
                _InlineErrorCard(message: state.errorMessage!),
              if (state.errorMessage != null) const SizedBox(height: 20),
              if (state.isGenerating)
                const CustomCard(
                  child: CustomLoadingView(
                    message: 'Generating AI suggestion...',
                  ),
                )
              else if (state.hasGeneratedOutput)
                _OutputCard(
                  state: state,
                  outputController: _outputController,
                  onToggleSkillSelection: (skillName) => ref
                      .read(aiImproveControllerProvider.notifier)
                      .toggleSkillSelection(skillName),
                  onCopy: () => _showActionMessage(
                    ref.read(aiImproveControllerProvider.notifier).copyOutput(),
                  ),
                  onApply: () => _showActionMessage(
                    ref
                        .read(aiImproveControllerProvider.notifier)
                        .applySuggestion(),
                  ),
                  onSaveDraft: () => _showActionMessage(
                    ref
                        .read(aiImproveControllerProvider.notifier)
                        .saveAsDraft(),
                  ),
                  onRegenerate: () => ref
                      .read(aiImproveControllerProvider.notifier)
                      .generateSuggestion(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCurrentInputChanged() {
    ref
        .read(aiImproveControllerProvider.notifier)
        .updateCurrentInput(_currentInputController.text);
  }

  void _handleOutputChanged() {
    ref
        .read(aiImproveControllerProvider.notifier)
        .updateGeneratedOutput(_outputController.text);
  }

  void _syncController(TextEditingController controller, String nextValue) {
    if (controller.text == nextValue) {
      return;
    }

    controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  Future<void> _createCvFirst(BuildContext context) async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
    await ref.read(aiImproveControllerProvider.notifier).reload();

    if (!context.mounted) {
      return;
    }

    final builderState = ref.read(cvBuilderControllerProvider);
    if (builderState.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(builderState.errorMessage!)));
      return;
    }

    context.push(RouteNames.cvBuilderPath);
  }

  Future<void> _openBuilder(BuildContext context, String cvId) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cvId);
    if (!context.mounted) {
      return;
    }

    context.push(RouteNames.cvBuilderPath);
  }

  Future<void> _openPreview(BuildContext context, String cvId) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cvId);
    if (!context.mounted) {
      return;
    }

    context.push(RouteNames.cvPreviewPath);
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

class _CvSelectionCard extends StatelessWidget {
  const _CvSelectionCard({
    required this.state,
    required this.onCvChanged,
    required this.onOpenBuilder,
    required this.onOpenPreview,
  });

  final AiImproveState state;
  final ValueChanged<String?> onCvChanged;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenPreview;

  @override
  Widget build(BuildContext context) {
    final selectedCv = state.selectedCv!;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected CV', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedCv.id,
            decoration: const InputDecoration(labelText: 'Choose saved CV'),
            items: [
              for (final cv in state.availableCvs)
                DropdownMenuItem(value: cv.id, child: Text(cv.displayTitle)),
            ],
            onChanged: onCvChanged,
          ),
          const SizedBox(height: 16),
          Text(
            '${selectedCv.displayName} • ${selectedCv.displayRole}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Updated ${DateFormatter.shortDateTime(selectedCv.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton.secondary(
                  label: 'Open CV Builder',
                  icon: Icons.edit_outlined,
                  onPressed: onOpenBuilder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton.text(
                  label: 'Open Preview',
                  icon: Icons.preview_outlined,
                  onPressed: onOpenPreview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImprovementSetupCard extends StatelessWidget {
  const _ImprovementSetupCard({
    required this.state,
    required this.onTypeChanged,
    required this.onLanguageChanged,
    required this.onToneChanged,
  });

  final AiImproveState state;
  final ValueChanged<AiImproveType?> onTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<AiTone> onToneChanged;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Improvement setup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AiImproveType>(
            initialValue: state.improvementType,
            decoration: const InputDecoration(labelText: 'Improvement type'),
            items: [
              for (final type in AiImproveType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 12),
          Text(
            state.improvementType.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Output language',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in AiOutputLanguage.values)
                ChoiceChip(
                  label: Text(
                    language == AiOutputLanguage.english ? 'English' : 'Bangla',
                  ),
                  selected: state.outputLanguage == language,
                  onSelected: (_) => onLanguageChanged(language),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Tone', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tone in const [
                AiTone.professional,
                AiTone.simple,
                AiTone.confident,
              ])
                ChoiceChip(
                  label: Text(_toneLabel(tone)),
                  selected: state.tone == tone,
                  onSelected: (_) => onToneChanged(tone),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _toneLabel(AiTone tone) {
    return switch (tone) {
      AiTone.professional => 'Professional',
      AiTone.simple => 'Simple',
      AiTone.confident => 'Confident',
      AiTone.formal => 'Formal',
    };
  }
}

class _ExperienceSelectorCard extends StatelessWidget {
  const _ExperienceSelectorCard({
    required this.state,
    required this.onExperienceChanged,
    required this.onBulletChanged,
  });

  final AiImproveState state;
  final ValueChanged<String?> onExperienceChanged;
  final ValueChanged<int?> onBulletChanged;

  @override
  Widget build(BuildContext context) {
    final experiences = state.selectedCv?.experiences ?? const [];
    final selectedExperience = state.selectedExperience;

    if (experiences.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience selection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: state.selectedExperienceId,
            decoration: const InputDecoration(labelText: 'Experience entry'),
            items: [
              for (final experience in experiences)
                DropdownMenuItem(
                  value: experience.id,
                  child: Text(
                    '${experience.jobTitle.ifEmpty('Untitled role')} • ${experience.companyName.ifEmpty('Unknown company')}',
                  ),
                ),
            ],
            onChanged: onExperienceChanged,
          ),
          if (selectedExperience != null &&
              selectedExperience.highlights.length > 1) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: state.selectedExperienceBulletIndex,
              decoration: const InputDecoration(labelText: 'Bullet item'),
              items: [
                for (
                  var index = 0;
                  index < selectedExperience.highlights.length;
                  index++
                )
                  DropdownMenuItem(
                    value: index,
                    child: Text('Bullet ${index + 1}'),
                  ),
              ],
              onChanged: onBulletChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectSelectorCard extends StatelessWidget {
  const _ProjectSelectorCard({
    required this.state,
    required this.onProjectChanged,
  });

  final AiImproveState state;
  final ValueChanged<String?> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    final projects = state.selectedCv?.projects ?? const [];
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project selection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: state.selectedProjectId,
            decoration: const InputDecoration(labelText: 'Project'),
            items: [
              for (final project in projects)
                DropdownMenuItem(
                  value: project.id,
                  child: Text(project.title.ifEmpty('Untitled project')),
                ),
            ],
            onChanged: onProjectChanged,
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.state,
    required this.currentInputController,
    required this.onGenerate,
  });

  final AiImproveState state;
  final TextEditingController currentInputController;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Input', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            _helperText(state.improvementType),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: currentInputController,
            label: state.improvementType.inputLabel,
            hintText: _hintText(state.improvementType),
            helperText: _fieldHelperText(state.improvementType),
            minLines: state.improvementType.isSkillsSuggestion ? 2 : 4,
            maxLines: state.improvementType.isSkillsSuggestion ? 4 : 8,
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Generate',
            icon: Icons.auto_awesome_outlined,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }

  String _helperText(AiImproveType type) {
    return switch (type) {
      AiImproveType.professionalSummary =>
        'Edit the current summary if needed, then generate a stronger version.',
      AiImproveType.careerObjective =>
        'Provide the current career objective or leave the field short for a fresher-friendly rewrite.',
      AiImproveType.experienceBullet =>
        'Use the selected experience bullet or edit it before generating a stronger version.',
      AiImproveType.projectDescription =>
        'Use the selected project description or refine it before generating a clearer draft.',
      AiImproveType.skillsSuggestion =>
        'Add a job title, job post excerpt, or extra role context to get more relevant skill ideas.',
    };
  }

  String _hintText(AiImproveType type) {
    return switch (type) {
      AiImproveType.professionalSummary =>
        'Summarize your background, strengths, and target role.',
      AiImproveType.careerObjective =>
        'State what role you want and how you want to contribute.',
      AiImproveType.experienceBullet =>
        'Worked on Flutter app and fixed user issues.',
      AiImproveType.projectDescription =>
        'Built a project to solve a real user problem.',
      AiImproveType.skillsSuggestion =>
        'Flutter developer role with Firebase, API integration, and Git.',
    };
  }

  String _fieldHelperText(AiImproveType type) {
    return switch (type) {
      AiImproveType.skillsSuggestion =>
        'This context helps the mock AI suggest more targeted skills.',
      _ => 'You can edit this input before generating.',
    };
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.state,
    required this.outputController,
    required this.onToggleSkillSelection,
    required this.onCopy,
    required this.onApply,
    required this.onSaveDraft,
    required this.onRegenerate,
  });

  final AiImproveState state;
  final TextEditingController outputController;
  final ValueChanged<String> onToggleSkillSelection;
  final VoidCallback onCopy;
  final VoidCallback onApply;
  final VoidCallback onSaveDraft;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI output', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Review and edit the suggestion before applying it back to your CV.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (state.improvementType.isSkillsSuggestion &&
              state.skillSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Select skills to include',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in state.skillSuggestions)
                  FilterChip(
                    label: Text(suggestion.name),
                    selected: state.selectedSuggestedSkills.contains(
                      suggestion.name,
                    ),
                    onSelected: (_) => onToggleSkillSelection(suggestion.name),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final suggestion in state.skillSuggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${suggestion.name}: ${suggestion.reason}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 16),
          CustomTextField(
            controller: outputController,
            label: state.improvementType.outputLabel,
            hintText: 'AI-generated content will appear here.',
            helperText: state.improvementType.isSkillsSuggestion
                ? 'Edit this list if you want to add or remove skill names before applying.'
                : 'Edit the wording if needed before applying it to the CV.',
            minLines: state.improvementType.isSkillsSuggestion ? 4 : 6,
            maxLines: state.improvementType.isSkillsSuggestion ? 8 : 12,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;
              final buttonWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton.secondary(
                      label: 'Copy output',
                      icon: Icons.copy_outlined,
                      onPressed: onCopy,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton(
                      label: 'Apply to selected CV',
                      icon: Icons.check_circle_outline,
                      onPressed: onApply,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton.secondary(
                      label: 'Save as draft',
                      icon: Icons.save_outlined,
                      onPressed: onSaveDraft,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton.text(
                      label: 'Regenerate',
                      icon: Icons.refresh_rounded,
                      onPressed: onRegenerate,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
