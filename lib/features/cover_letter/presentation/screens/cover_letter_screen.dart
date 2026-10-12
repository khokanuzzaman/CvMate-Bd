import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cover_letter/presentation/widgets/cover_letter_letter_view.dart';
import 'package:careermatebd/features/cover_letter/presentation/widgets/cover_letter_setup_view.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cover letter: the letter view (design) once there is a letter or one is being
/// written, otherwise the setup form. All work happens in
/// [CoverLetterController]; this screen only wires fields and pages.
class CoverLetterScreen extends ConsumerStatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  ConsumerState<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends ConsumerState<CoverLetterScreen> {
  final _company = TextEditingController();
  final _jobTitle = TextEditingController();
  final _jobDetails = TextEditingController();
  final _hiringManager = TextEditingController();
  final _candidateSummary = TextEditingController();
  final _subjectLine = TextEditingController();
  final _content = TextEditingController();

  /// UI only: show the form even though a letter exists ("Change details").
  bool _showSetup = false;

  /// UI only: the job arrived filled in but without a company, so the form
  /// opens with the company field focused. Used once.
  late bool _focusCompany;

  CoverLetterController get _controller =>
      ref.read(coverLetterControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    final initial = ref.read(coverLetterControllerProvider);
    _focusCompany =
        initial.targetCompany.trim().isEmpty &&
        initial.jobDetails.trim().isNotEmpty;
    _company.addListener(() => _controller.updateTargetCompany(_company.text));
    _jobTitle.addListener(() => _controller.updateJobTitle(_jobTitle.text));
    _jobDetails.addListener(
      () => _controller.updateJobDetails(_jobDetails.text),
    );
    _hiringManager.addListener(
      () => _controller.updateHiringManagerName(_hiringManager.text),
    );
    _candidateSummary.addListener(
      () => _controller.updateCandidateSummary(_candidateSummary.text),
    );
    _subjectLine.addListener(
      () => _controller.updateSubjectLine(_subjectLine.text),
    );
    _content.addListener(
      () => _controller.updateGeneratedContent(_content.text),
    );
    Future.microtask(() => _controller.initialize());
  }

  @override
  void dispose() {
    for (final controller in [
      _company,
      _jobTitle,
      _jobDetails,
      _hiringManager,
      _candidateSummary,
      _subjectLine,
      _content,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coverLetterControllerProvider);
    _sync(_company, state.targetCompany);
    _sync(_jobTitle, state.jobTitle);
    _sync(_jobDetails, state.jobDetails);
    _sync(_hiringManager, state.hiringManagerName);
    _sync(_candidateSummary, state.candidateSummary);
    _sync(_subjectLine, state.subjectLine);
    _sync(_content, state.generatedContent);

    if (state.isLoading && !state.hasInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: CustomLoadingView(message: AppStrings.coverLetterLoading),
      );
    }

    final hasLetter =
        state.hasGeneratedContent ||
        state.subjectLine.trim().isNotEmpty ||
        state.isGenerating;

    if (hasLetter && !_showSetup) {
      return CoverLetterLetterView(
        state: state,
        contentController: _content,
        subjectController: _subjectLine,
        onBack: () => context.pop(),
        onShare: () => _message(_controller.shareOutput()),
        onCopy: () => _message(_controller.copyOutput()),
        onChangeDetails: () => setState(() {
          _showSetup = true;
          _focusCompany = false;
        }),
        onToneChanged: _controller.selectTone,
        onRegenerate: _controller.generateContent,
        onExport: _export,
      );
    }

    return CoverLetterSetupView(
      state: state,
      form: CoverLetterFormControllers(
        company: _company,
        jobTitle: _jobTitle,
        jobDetails: _jobDetails,
        hiringManager: _hiringManager,
        candidateSummary: _candidateSummary,
      ),
      focusCompany: _focusCompany,
      onBack: () => context.pop(),
      onNewDraft: _controller.startNewDraft,
      onViewLetter: hasLetter ? () => setState(() => _showSetup = false) : null,
      onCreateCv: () => _createCv(context),
      onOpenSelectedCv: state.selectedCv == null
          ? null
          : () => _openCvBuilder(context, state.selectedCv!),
      onCvChanged: (value) => _controller.selectCv(
        value == null || value == manualCvSelectionValue ? null : value,
      ),
      onOutputTypeChanged: _controller.selectOutputType,
      onLanguageChanged: _controller.selectLanguage,
      onToneChanged: _controller.selectTone,
      onOpenDraft: (id) {
        _controller.loadDraft(id);
        setState(() => _showSetup = false);
      },
      onDeleteDraft: (draft) => _confirmDelete(context, draft),
      onGenerate: () {
        setState(() {
          _showSetup = false;
          _focusCompany = false;
        });
        _controller.generateContent();
      },
    );
  }

  /// Export saves the letter as a draft (so it shows under Recent drafts) and
  /// opens the share sheet.
  Future<void> _export() async {
    final saved = await _controller.saveDraft();
    if (!mounted) {
      return;
    }
    if (ref.read(coverLetterControllerProvider).errorMessage != null) {
      _snack(saved);
      return;
    }
    await _message(_controller.shareOutput());
  }

  void _sync(TextEditingController controller, String next) {
    if (controller.text == next) {
      return;
    }
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _createCv(BuildContext context) async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
    final builderState = ref.read(cvBuilderControllerProvider);
    if (!context.mounted) {
      return;
    }
    if (builderState.errorMessage != null) {
      _snack(builderState.errorMessage);
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (mounted) {
      await _controller.reload();
    }
  }

  Future<void> _openCvBuilder(BuildContext context, CvProfile profile) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(profile.id);
    if (!context.mounted) {
      return;
    }
    await context.push(RouteNames.cvBuilderPath);
    if (mounted) {
      await _controller.reload();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CoverLetterDraft draft,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.coverLetterDeleteTitle),
        content: Text(AppStrings.coverLetterDeleteBody(draft.displayTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.coverLetterCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.coverLetterDelete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _message(_controller.deleteDraft(draft.id));
    }
  }

  Future<void> _message(Future<String?> action) async {
    _snack(await action);
  }

  void _snack(String? message) {
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
