import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_state.dart';
import 'package:careermatebd/features/subscription/presentation/export_gate.dart';
import 'package:careermatebd/features/tailoring/domain/entities/tailoring_result.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class TailoringScreen extends ConsumerStatefulWidget {
  const TailoringScreen({super.key});

  @override
  ConsumerState<TailoringScreen> createState() => _TailoringScreenState();
}

class _TailoringScreenState extends ConsumerState<TailoringScreen> {
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobPostController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _coverLetterController = TextEditingController();
  final List<TextEditingController> _bulletControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tailoringControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _jobPostController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    _coverLetterController.dispose();
    for (final controller in _bulletControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seedTailoredControllers(TailoringResult result) {
    _summaryController.text = result.tailoredSummary;
    _skillsController.text = result.emphasizedSkills.join(', ');

    for (final controller in _bulletControllers) {
      controller.dispose();
    }
    _bulletControllers
      ..clear()
      ..addAll(
        result.rewrittenBullets.map(
          (bullet) => TextEditingController(text: bullet.suggested),
        ),
      );
  }

  void _resetFlow() {
    setState(() {
      _jobTitleController.clear();
      _companyController.clear();
      _jobPostController.clear();
      _clearResultControllers();
    });
    ref.read(tailoringControllerProvider.notifier).reset();
  }

  void _clearResultControllers() {
    _summaryController.clear();
    _skillsController.clear();
    _coverLetterController.clear();
    for (final controller in _bulletControllers) {
      controller.dispose();
    }
    _bulletControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TailoringState>(tailoringControllerProvider, (previous, next) {
      final tailorDone =
          previous?.stage == TailoringStage.tailoring &&
          next.stage == TailoringStage.ready;
      final coverDone =
          previous?.stage == TailoringStage.generatingCoverLetter &&
          next.stage == TailoringStage.ready;

      if (tailorDone && next.result != null) {
        setState(() => _seedTailoredControllers(next.result!));
      }
      if (coverDone && next.result != null) {
        _coverLetterController.text = next.result!.coverLetter;
      }
      if (next.result == null && previous?.result != null) {
        setState(_clearResultControllers);
      }

      final message = next.failure?.message;
      if (message != null && message != previous?.failure?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(tailoringControllerProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tailor to a Job',
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: state.isBusy ? null : _resetFlow,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, TailoringState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: 'Loading your CVs...');
    }

    if (state.hasInitialized && !state.hasSavedCvs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CustomEmptyState(
            title: 'No CV to tailor yet',
            message:
                'Create a CV first, then paste a job post here to tailor it and generate a matched cover letter.',
            icon: Icons.tips_and_updates_outlined,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepHeader(
                step: '1',
                title: 'Pick a CV and paste the job post',
              ),
              const SizedBox(height: 12),
              _buildInputCard(context, state),
              const SizedBox(height: 20),
              if (state.hasMatchReport) ...[
                _StepHeader(step: '2', title: 'Keyword gap'),
                const SizedBox(height: 12),
                _MatchReportCard(report: state.matchReport!),
                const SizedBox(height: 20),
              ],
              if (state.result?.hasTailoredContent ?? false) ...[
                _StepHeader(step: '3', title: 'Tailored CV (editable)'),
                const SizedBox(height: 12),
                _buildTailoredCard(context, state),
                const SizedBox(height: 20),
              ],
              if (state.hasMatchReport) ...[
                _StepHeader(step: '4', title: 'Matched cover letter'),
                const SizedBox(height: 12),
                _buildCoverLetterCard(context, state),
                const SizedBox(height: 20),
              ],
              if ((state.result?.hasTailoredContent ?? false)) ...[
                _StepHeader(step: '5', title: 'Save and export'),
                const SizedBox(height: 12),
                _buildExportCard(context, state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, TailoringState state) {
    final notifier = ref.read(tailoringControllerProvider.notifier);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: state.cvId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'CV to tailor',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final cv in state.availableCvs)
                DropdownMenuItem(value: cv.id, child: Text(cv.displayTitle)),
            ],
            onChanged: state.isBusy
                ? null
                : (value) {
                    if (value != null) {
                      notifier.selectCv(value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _jobTitleController,
            label: 'Target job title (optional)',
            hintText: 'e.g. Staff Nurse, Accountant, Flutter Developer',
            onChanged: (value) => notifier.updateJobPost(jobTitle: value),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _companyController,
            label: 'Company (optional)',
            hintText: 'e.g. City General Hospital',
            onChanged: (value) => notifier.updateJobPost(company: value),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _jobPostController,
            label: 'Paste the job post',
            hintText:
                'Paste the full job description here. Requirements, skills, and responsibilities help the most.',
            minLines: 4,
            maxLines: 10,
            onChanged: (value) => notifier.updateJobPost(jobPostText: value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton.secondary(
                  label: 'Analyze',
                  icon: Icons.query_stats_rounded,
                  onPressed: state.canAnalyze
                      ? () => notifier.analyze()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: state.stage == TailoringStage.tailoring
                      ? 'Tailoring...'
                      : 'Tailor CV',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: (state.selectedCv != null && state.hasJobPost && !state.isBusy)
                      ? () => notifier.tailor()
                      : null,
                ),
              ),
            ],
          ),
          if (state.isBusy) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(state.stage.label),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTailoredCard(BuildContext context, TailoringState state) {
    final notifier = ref.read(tailoringControllerProvider.notifier);
    final result = state.result!;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tailored professional summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _summaryController,
            minLines: 3,
            maxLines: 6,
            onChanged: notifier.updateTailoredSummary,
          ),
          const SizedBox(height: 16),
          Text(
            'Emphasized skills (comma separated)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _skillsController,
            minLines: 1,
            maxLines: 3,
            onChanged: notifier.updateEmphasizedSkillsText,
          ),
          if (result.rewrittenBullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Rewritten experience bullets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Review each rewrite before saving. Keep only what is true.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < result.rewrittenBullets.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original: ${result.rewrittenBullets[index].original}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    CustomTextField(
                      controller: index < _bulletControllers.length
                          ? _bulletControllers[index]
                          : null,
                      minLines: 2,
                      maxLines: 4,
                      onChanged: (value) =>
                          notifier.updateBulletSuggestion(index, value),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoverLetterCard(BuildContext context, TailoringState state) {
    final notifier = ref.read(tailoringControllerProvider.notifier);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton.secondary(
            label: state.stage == TailoringStage.generatingCoverLetter
                ? 'Generating...'
                : 'Generate cover letter',
            icon: Icons.mail_outline_rounded,
            onPressed:
                (state.selectedCv != null &&
                    state.company.trim().isNotEmpty &&
                    !state.isBusy)
                ? () => notifier.generateCoverLetter()
                : null,
          ),
          if (state.company.trim().isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Add the target company above to generate a cover letter.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (state.result?.hasCoverLetter ?? false) ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: _coverLetterController,
              minLines: 6,
              maxLines: 16,
              onChanged: notifier.updateCoverLetter,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, TailoringState state) {
    final notifier = ref.read(tailoringControllerProvider.notifier);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your source CV stays unchanged. Saving creates a new tailored copy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Save as new tailored CV',
            icon: Icons.save_alt_rounded,
            onPressed: state.isBusy
                ? null
                : () async {
                    final saved = await notifier.saveAsTailoredCopy();
                    if (!context.mounted || saved == null) {
                      return;
                    }
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text('Saved "${saved.displayTitle}".')),
                      );
                  },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton.secondary(
                  label: 'Share / Download PDF',
                  icon: Icons.download_rounded,
                  onPressed: () => _sharePdf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton.secondary(
                  label: 'Print',
                  icon: Icons.print_rounded,
                  onPressed: () => _printPdf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final profile = ref.read(tailoringControllerProvider.notifier).buildTailoredCv();
    if (profile == null) {
      return;
    }
    final pdfService = ref.read(cvPdfServiceProvider);
    final fileName = pdfService.buildFileName(profile);

    await runGatedExport(
      ref: ref,
      context: context,
      source: 'tailoring',
      exportType: 'share',
      export: () async {
        final bytes = await pdfService.generateCvPdf(profile: profile);
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      },
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    final profile = ref.read(tailoringControllerProvider.notifier).buildTailoredCv();
    if (profile == null) {
      return;
    }
    final pdfService = ref.read(cvPdfServiceProvider);
    final fileName = pdfService.buildFileName(profile);

    await runGatedExport(
      ref: ref,
      context: context,
      source: 'tailoring',
      exportType: 'print',
      export: () => Printing.layoutPdf(
        name: fileName,
        onLayout: (format) =>
            pdfService.generateCvPdf(profile: profile, pageFormat: format),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(step, style: theme.textTheme.labelLarge),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
      ],
    );
  }
}

class _MatchReportCard extends StatelessWidget {
  const _MatchReportCard({required this.report});

  final AtsJobMatchReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${report.matchPercentage}%',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'keyword coverage vs the job post',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (report.matchedKeywords.isNotEmpty) ...[
            Text('Matched', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            _KeywordWrap(
              keywords: report.matchedKeywords,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
          ],
          if (report.missingKeywords.isNotEmpty) ...[
            Text('Missing', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            _KeywordWrap(
              keywords: report.missingKeywords,
              color: theme.colorScheme.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _KeywordWrap extends StatelessWidget {
  const _KeywordWrap({required this.keywords, required this.color});

  final List<String> keywords;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final keyword in keywords)
          Chip(
            label: Text(keyword),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
      ],
    );
  }
}
