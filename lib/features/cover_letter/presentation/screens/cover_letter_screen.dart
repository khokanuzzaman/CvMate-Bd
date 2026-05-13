import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_state.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const String _manualCvSelectionValue = '__manual_cv__';

class CoverLetterScreen extends ConsumerStatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  ConsumerState<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends ConsumerState<CoverLetterScreen> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDetailsController = TextEditingController();
  final TextEditingController _hiringManagerController =
      TextEditingController();
  final TextEditingController _candidateSummaryController =
      TextEditingController();
  final TextEditingController _subjectLineController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _companyController.addListener(_handleCompanyChanged);
    _jobTitleController.addListener(_handleJobTitleChanged);
    _jobDetailsController.addListener(_handleJobDetailsChanged);
    _hiringManagerController.addListener(_handleHiringManagerChanged);
    _candidateSummaryController.addListener(_handleCandidateSummaryChanged);
    _subjectLineController.addListener(_handleSubjectChanged);
    _contentController.addListener(_handleContentChanged);
    Future.microtask(
      () => ref.read(coverLetterControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _companyController
      ..removeListener(_handleCompanyChanged)
      ..dispose();
    _jobTitleController
      ..removeListener(_handleJobTitleChanged)
      ..dispose();
    _jobDetailsController
      ..removeListener(_handleJobDetailsChanged)
      ..dispose();
    _hiringManagerController
      ..removeListener(_handleHiringManagerChanged)
      ..dispose();
    _candidateSummaryController
      ..removeListener(_handleCandidateSummaryChanged)
      ..dispose();
    _subjectLineController
      ..removeListener(_handleSubjectChanged)
      ..dispose();
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coverLetterControllerProvider);
    _syncController(_companyController, state.targetCompany);
    _syncController(_jobTitleController, state.jobTitle);
    _syncController(_jobDetailsController, state.jobDetails);
    _syncController(_hiringManagerController, state.hiringManagerName);
    _syncController(_candidateSummaryController, state.candidateSummary);
    _syncController(_subjectLineController, state.subjectLine);
    _syncController(_contentController, state.generatedContent);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cover Letter',
        actions: [
          IconButton(
            onPressed: () => ref
                .read(coverLetterControllerProvider.notifier)
                .startNewDraft(),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New draft',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, CoverLetterState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(
        message: 'Loading CVs and cover letter drafts...',
      );
    }

    final hasOutput =
        state.generatedContent.trim().isNotEmpty ||
        state.subjectLine.trim().isNotEmpty;

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
                onCreateCv: () => _createCv(context),
                onOpenSelectedCv: state.selectedCv == null
                    ? null
                    : () => _openSelectedCvBuilder(context, state.selectedCv!),
              ),
              const SizedBox(height: 20),
              if (state.hasRecentDrafts) ...[
                _RecentDraftsSection(
                  state: state,
                  onOpenDraft: (draftId) {
                    ref
                        .read(coverLetterControllerProvider.notifier)
                        .loadDraft(draftId);
                  },
                  onDeleteDraft: (draft) => _confirmDeleteDraft(context, draft),
                ),
                const SizedBox(height: 20),
              ],
              _CvSelectionCard(
                state: state,
                onCvChanged: (value) {
                  ref
                      .read(coverLetterControllerProvider.notifier)
                      .selectCv(
                        value == null || value == _manualCvSelectionValue
                            ? null
                            : value,
                      );
                },
              ),
              const SizedBox(height: 20),
              _GeneratorSetupCard(
                state: state,
                onOutputTypeChanged: (value) {
                  if (value != null) {
                    ref
                        .read(coverLetterControllerProvider.notifier)
                        .selectOutputType(value);
                  }
                },
                onLanguageChanged: (value) => ref
                    .read(coverLetterControllerProvider.notifier)
                    .selectLanguage(value),
                onToneChanged: (value) => ref
                    .read(coverLetterControllerProvider.notifier)
                    .selectTone(value),
              ),
              const SizedBox(height: 20),
              _DetailsCard(
                state: state,
                companyController: _companyController,
                jobTitleController: _jobTitleController,
                jobDetailsController: _jobDetailsController,
                hiringManagerController: _hiringManagerController,
                candidateSummaryController: _candidateSummaryController,
                onGenerate: () => ref
                    .read(coverLetterControllerProvider.notifier)
                    .generateContent(),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                _InlineErrorCard(message: state.errorMessage!),
              ],
              const SizedBox(height: 20),
              if (state.isGenerating)
                const CustomCard(
                  child: CustomLoadingView(
                    message: 'Generating cover letter content...',
                  ),
                )
              else if (hasOutput)
                _OutputCard(
                  state: state,
                  subjectLineController: _subjectLineController,
                  contentController: _contentController,
                  onCopy: () => _showActionMessage(
                    ref
                        .read(coverLetterControllerProvider.notifier)
                        .copyOutput(),
                  ),
                  onSave: () => _showActionMessage(
                    ref
                        .read(coverLetterControllerProvider.notifier)
                        .saveDraft(),
                  ),
                  onRegenerate: () => ref
                      .read(coverLetterControllerProvider.notifier)
                      .generateContent(),
                  onShare: () => _showActionMessage(
                    ref
                        .read(coverLetterControllerProvider.notifier)
                        .shareOutput(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCompanyChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateTargetCompany(_companyController.text);
  }

  void _handleJobTitleChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateJobTitle(_jobTitleController.text);
  }

  void _handleJobDetailsChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateJobDetails(_jobDetailsController.text);
  }

  void _handleHiringManagerChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateHiringManagerName(_hiringManagerController.text);
  }

  void _handleCandidateSummaryChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateCandidateSummary(_candidateSummaryController.text);
  }

  void _handleSubjectChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateSubjectLine(_subjectLineController.text);
  }

  void _handleContentChanged() {
    ref
        .read(coverLetterControllerProvider.notifier)
        .updateGeneratedContent(_contentController.text);
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

  Future<void> _createCv(BuildContext context) async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
    final builderState = ref.read(cvBuilderControllerProvider);

    if (!context.mounted) {
      return;
    }

    if (builderState.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(builderState.errorMessage!)));
      return;
    }

    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(coverLetterControllerProvider.notifier).reload();
  }

  Future<void> _openSelectedCvBuilder(
    BuildContext context,
    CvProfile profile,
  ) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(profile.id);
    if (!context.mounted) {
      return;
    }

    await context.push(RouteNames.cvBuilderPath);
    if (!mounted) {
      return;
    }
    await ref.read(coverLetterControllerProvider.notifier).reload();
  }

  Future<void> _confirmDeleteDraft(
    BuildContext context,
    CoverLetterDraft draft,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete draft'),
          content: Text(
            'Delete "${draft.displayTitle}" from local storage? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _showActionMessage(
      ref.read(coverLetterControllerProvider.notifier).deleteDraft(draft.id),
    );
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
    required this.onCreateCv,
    required this.onOpenSelectedCv,
  });

  final CoverLetterState state;
  final VoidCallback onCreateCv;
  final VoidCallback? onOpenSelectedCv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCv = state.selectedCv;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cover Letter Generator',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (state.isEditingSavedDraft)
                const Chip(label: Text('Editing saved draft')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Generate editable cover letters, job application emails, and LinkedIn messages using your saved CV or a manual candidate summary.',
          ),
          const SizedBox(height: 16),
          if (!state.hasSavedCvs)
            Text(
              'No saved CV found yet. You can still generate content manually, or create a CV first for stronger role-based results.',
            )
          else if (selectedCv != null)
            Text(
              'Selected CV: ${selectedCv.displayTitle} • ${selectedCv.displayRole}',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton.secondary(
                label: state.hasSavedCvs ? 'Create another CV' : 'Create CV',
                onPressed: onCreateCv,
                icon: Icons.add_rounded,
                isExpanded: false,
              ),
              if (onOpenSelectedCv != null)
                CustomButton.text(
                  label: 'Open selected CV',
                  onPressed: onOpenSelectedCv,
                  icon: Icons.description_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentDraftsSection extends StatelessWidget {
  const _RecentDraftsSection({
    required this.state,
    required this.onOpenDraft,
    required this.onDeleteDraft,
  });

  final CoverLetterState state;
  final ValueChanged<String> onOpenDraft;
  final ValueChanged<CoverLetterDraft> onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent drafts', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final draft in state.recentDrafts) ...[
          _RecentDraftCard(
            draft: draft,
            isActive: draft.id == state.activeDraftId,
            relatedCv: _findRelatedCv(state.availableCvs, draft.cvId),
            onOpen: () => onOpenDraft(draft.id),
            onDelete: () => onDeleteDraft(draft),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  CvProfile? _findRelatedCv(List<CvProfile> cvs, String? cvId) {
    if (cvId == null) {
      return null;
    }

    for (final cv in cvs) {
      if (cv.id == cvId) {
        return cv;
      }
    }

    return null;
  }
}

class _RecentDraftCard extends StatelessWidget {
  const _RecentDraftCard({
    required this.draft,
    required this.isActive,
    required this.relatedCv,
    required this.onOpen,
    required this.onDelete,
  });

  final CoverLetterDraft draft;
  final bool isActive;
  final CvProfile? relatedCv;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            draft.displayTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (isActive)
                          Chip(
                            label: const Text('Open'),
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${draft.outputType.label} • Updated ${DateFormatter.shortDateTime(draft.updatedAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (relatedCv != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Using CV: ${relatedCv!.displayTitle}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete draft',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(draft.previewText),
          const SizedBox(height: 14),
          CustomButton.secondary(
            label: 'Open draft',
            onPressed: onOpen,
            isExpanded: false,
            icon: Icons.edit_outlined,
          ),
        ],
      ),
    );
  }
}

class _CvSelectionCard extends StatelessWidget {
  const _CvSelectionCard({required this.state, required this.onCvChanged});

  final CoverLetterState state;
  final ValueChanged<String?> onCvChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedValue = state.selectedCvId ?? _manualCvSelectionValue;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Candidate source', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Use a saved CV for stronger job-specific content, or continue without a CV and write your own candidate summary.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedValue,
            onChanged: onCvChanged,
            decoration: const InputDecoration(labelText: 'Select CV'),
            items: [
              const DropdownMenuItem(
                value: _manualCvSelectionValue,
                child: Text('No CV selected, use manual summary'),
              ),
              for (final cv in state.availableCvs)
                DropdownMenuItem(
                  value: cv.id,
                  child: Text('${cv.displayTitle} • ${cv.displayRole}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratorSetupCard extends StatelessWidget {
  const _GeneratorSetupCard({
    required this.state,
    required this.onOutputTypeChanged,
    required this.onLanguageChanged,
    required this.onToneChanged,
  });

  final CoverLetterState state;
  final ValueChanged<CoverLetterOutputType?> onOutputTypeChanged;
  final ValueChanged<AiOutputLanguage> onLanguageChanged;
  final ValueChanged<AiTone> onToneChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const toneOptions = [AiTone.formal, AiTone.simple, AiTone.confident];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generator setup', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<CoverLetterOutputType>(
            initialValue: state.outputType,
            onChanged: onOutputTypeChanged,
            decoration: const InputDecoration(labelText: 'Output type'),
            items: [
              for (final type in CoverLetterOutputType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Language', style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('English'),
                selected: state.language == AiOutputLanguage.english,
                onSelected: (_) => onLanguageChanged(AiOutputLanguage.english),
              ),
              ChoiceChip(
                label: const Text('Bangla'),
                selected: state.language == AiOutputLanguage.bangla,
                onSelected: (_) => onLanguageChanged(AiOutputLanguage.bangla),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Tone', style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tone in toneOptions)
                ChoiceChip(
                  label: Text(_toneLabel(tone)),
                  selected: state.tone == tone,
                  onSelected: (_) => onToneChanged(tone),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(state.outputType.description, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _toneLabel(AiTone tone) => switch (tone) {
    AiTone.formal => 'Formal',
    AiTone.simple => 'Simple',
    AiTone.confident => 'Confident',
    AiTone.professional => 'Professional',
  };
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.state,
    required this.companyController,
    required this.jobTitleController,
    required this.jobDetailsController,
    required this.hiringManagerController,
    required this.candidateSummaryController,
    required this.onGenerate,
  });

  final CoverLetterState state;
  final TextEditingController companyController;
  final TextEditingController jobTitleController;
  final TextEditingController jobDetailsController;
  final TextEditingController hiringManagerController;
  final TextEditingController candidateSummaryController;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          CustomTextField(
            controller: companyController,
            label: 'Target company name',
            hintText: 'BRAC Bank, DataPath, Shohoz',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobTitleController,
            label: 'Job title',
            hintText: 'Flutter Developer, Marketing Executive',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobDetailsController,
            label: 'Job post or job details',
            hintText:
                'Paste responsibilities, skills, company expectations, or a short job description.',
            helperText:
                'This helps the generator make the draft more specific.',
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: hiringManagerController,
            label: 'Hiring manager name',
            hintText: 'Optional',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: candidateSummaryController,
            label: 'Candidate summary',
            hintText:
                'Optional if a CV is selected. Add fresher strengths, projects, or a quick profile summary.',
            helperText: state.selectedCv == null
                ? 'Required when you are generating without a selected CV.'
                : 'Leave blank to reuse the selected CV summary or objective.',
            minLines: 4,
            maxLines: 6,
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Generate',
            onPressed: state.isGenerating ? null : onGenerate,
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.state,
    required this.subjectLineController,
    required this.contentController,
    required this.onCopy,
    required this.onSave,
    required this.onRegenerate,
    required this.onShare,
  });

  final CoverLetterState state;
  final TextEditingController subjectLineController;
  final TextEditingController contentController;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onRegenerate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSubjectLine =
        state.outputType.showsSubjectLine ||
        state.subjectLine.trim().isNotEmpty;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated output', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Review and edit the generated content before sending it anywhere.',
          ),
          if (showSubjectLine) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: subjectLineController,
              label: 'Subject line',
              hintText: 'Application for the role',
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 16),
          CustomTextField(
            controller: contentController,
            label: 'Content',
            minLines: 10,
            maxLines: 16,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomButton.secondary(
                label: 'Copy output',
                onPressed: onCopy,
                icon: Icons.copy_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Save draft',
                onPressed: onSave,
                icon: Icons.save_outlined,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Regenerate',
                onPressed: onRegenerate,
                icon: Icons.refresh_rounded,
                isExpanded: false,
              ),
              CustomButton.secondary(
                label: 'Share',
                onPressed: onShare,
                icon: Icons.share_outlined,
                isExpanded: false,
              ),
            ],
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
