import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_state.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JobApplicationFormScreen extends ConsumerStatefulWidget {
  const JobApplicationFormScreen({super.key, this.applicationId});

  final String? applicationId;

  @override
  ConsumerState<JobApplicationFormScreen> createState() =>
      _JobApplicationFormScreenState();
}

class _JobApplicationFormScreenState
    extends ConsumerState<JobApplicationFormScreen> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobPostLinkController = TextEditingController();
  final TextEditingController _salaryRangeController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _companyController.addListener(_handleCompanyChanged);
    _jobTitleController.addListener(_handleJobTitleChanged);
    _jobPostLinkController.addListener(_handleJobPostLinkChanged);
    _salaryRangeController.addListener(_handleSalaryChanged);
    _contactPersonController.addListener(_handleContactPersonChanged);
    _contactEmailController.addListener(_handleContactEmailChanged);
    _notesController.addListener(_handleNotesChanged);
    Future.microtask(
      () => ref
          .read(jobApplicationFormControllerProvider.notifier)
          .initialize(applicationId: widget.applicationId),
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
    _jobPostLinkController
      ..removeListener(_handleJobPostLinkChanged)
      ..dispose();
    _salaryRangeController
      ..removeListener(_handleSalaryChanged)
      ..dispose();
    _contactPersonController
      ..removeListener(_handleContactPersonChanged)
      ..dispose();
    _contactEmailController
      ..removeListener(_handleContactEmailChanged)
      ..dispose();
    _notesController
      ..removeListener(_handleNotesChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobApplicationFormControllerProvider);
    _syncController(_companyController, state.companyName);
    _syncController(_jobTitleController, state.jobTitle);
    _syncController(_jobPostLinkController, state.jobPostLink);
    _syncController(_salaryRangeController, state.salaryRange);
    _syncController(_contactPersonController, state.contactPerson);
    _syncController(_contactEmailController, state.contactEmail);
    _syncController(_notesController, state.notes);

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
              child: AppTopBar(
                title: state.isEditing ? 'Edit application' : 'Add application',
                onBack: () => context.pop(),
              ),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobApplicationFormState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: 'Loading application form...');
    }

    if (state.errorMessage != null &&
        state.applicationId == null &&
        widget.applicationId != null &&
        state.companyName.trim().isEmpty) {
      return CustomErrorView(
        title: 'Could not load application',
        message: state.errorMessage!,
        onRetry: () => ref
            .read(jobApplicationFormControllerProvider.notifier)
            .initialize(applicationId: widget.applicationId, force: true),
      );
    }

    final form = ref.read(jobApplicationFormControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BasicsCard(
            state: state,
            companyController: _companyController,
            jobTitleController: _jobTitleController,
            onSourceChanged: form.updateJobSource,
          ),
          const SizedBox(height: AppSpacing.s16),
          _LinksCard(
            state: state,
            onCvChanged: form.selectCv,
            onCoverLetterChanged: form.selectCoverLetter,
          ),
          const SizedBox(height: AppSpacing.s16),
          _TimelineCard(
            state: state,
            onPickAppliedDate: () => _pickDate(
              initialDate: state.appliedDate,
              onSelected: form.updateAppliedDate,
            ),
            onPickDeadlineDate: () => _pickOptionalDate(
              initialDate: state.deadlineDate ?? state.appliedDate,
              onSelected: form.updateDeadlineDate,
            ),
            onClearDeadlineDate: () => form.updateDeadlineDate(null),
            onPickInterviewDate: () => _pickOptionalDate(
              initialDate: state.interviewDate ?? state.appliedDate,
              onSelected: form.updateInterviewDate,
            ),
            onClearInterviewDate: () => form.updateInterviewDate(null),
            onPickFollowUpDate: () => _pickOptionalDate(
              initialDate: state.followUpDate ?? state.appliedDate,
              onSelected: form.updateFollowUpDate,
            ),
            onClearFollowUpDate: () => form.updateFollowUpDate(null),
            onStatusChanged: form.updateStatus,
          ),
          const SizedBox(height: AppSpacing.s16),
          _ContactAndNotesCard(
            jobPostLinkController: _jobPostLinkController,
            salaryRangeController: _salaryRangeController,
            contactPersonController: _contactPersonController,
            contactEmailController: _contactEmailController,
            notesController: _notesController,
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              state.errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          PrimaryButton(
            label: state.isSaving ? 'Saving...' : 'Save application',
            leadingIcon: Icons.check_rounded,
            onPressed: state.isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final message = await ref
        .read(jobApplicationFormControllerProvider.notifier)
        .save();
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }

    if (message == 'Application saved.' || message == 'Application updated.') {
      context.pop(message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    onSelected(picked);
  }

  Future<void> _pickOptionalDate({
    required DateTime initialDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    onSelected(picked);
  }

  void _handleCompanyChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateCompanyName(_companyController.text);
  }

  void _handleJobTitleChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateJobTitle(_jobTitleController.text);
  }

  void _handleJobPostLinkChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateJobPostLink(_jobPostLinkController.text);
  }

  void _handleSalaryChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateSalaryRange(_salaryRangeController.text);
  }

  void _handleContactPersonChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateContactPerson(_contactPersonController.text);
  }

  void _handleContactEmailChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateContactEmail(_contactEmailController.text);
  }

  void _handleNotesChanged() {
    ref
        .read(jobApplicationFormControllerProvider.notifier)
        .updateNotes(_notesController.text);
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
}

class _BasicsCard extends StatelessWidget {
  const _BasicsCard({
    required this.state,
    required this.companyController,
    required this.jobTitleController,
    required this.onSourceChanged,
  });

  final JobApplicationFormState state;
  final TextEditingController companyController;
  final TextEditingController jobTitleController;
  final ValueChanged<JobSource> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Application basics'),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: companyController,
            label: 'Company name',
            hintText: 'Bdjobs, BRAC Bank, Unilever Bangladesh',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: jobTitleController,
            label: 'Job title',
            hintText: 'Management Trainee, Flutter Developer',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          Text('Job source', style: AppTextStyles.fieldLabel),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final source in JobSource.values)
                AppChip(
                  label: source.label,
                  variant: source == state.jobSource
                      ? AppChipVariant.selected
                      : AppChipVariant.neutral,
                  onTap: () => onSourceChanged(source),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard({
    required this.state,
    required this.onCvChanged,
    required this.onCoverLetterChanged,
  });

  final JobApplicationFormState state;
  final ValueChanged<String?> onCvChanged;
  final ValueChanged<String?> onCoverLetterChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Linked assets'),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Connect the exact CV and cover letter you used for this '
            'application.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s14),
          DropdownButtonFormField<String?>(
            initialValue: state.selectedCvId,
            onChanged: onCvChanged,
            isExpanded: true,
            style: AppTextStyles.bodySm,
            decoration: const InputDecoration(labelText: 'Linked CV'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No linked CV'),
              ),
              for (final cv in state.availableCvs)
                DropdownMenuItem<String?>(
                  value: cv.id,
                  child: Text(
                    '${cv.displayTitle} • ${cv.displayRole}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          DropdownButtonFormField<String?>(
            initialValue: state.selectedCoverLetterId,
            onChanged: onCoverLetterChanged,
            isExpanded: true,
            style: AppTextStyles.bodySm,
            decoration: const InputDecoration(labelText: 'Linked cover letter'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No linked cover letter'),
              ),
              for (final draft in state.availableCoverLetters)
                DropdownMenuItem<String?>(
                  value: draft.id,
                  child: Text(
                    draft.displayTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.state,
    required this.onPickAppliedDate,
    required this.onPickDeadlineDate,
    required this.onClearDeadlineDate,
    required this.onPickInterviewDate,
    required this.onClearInterviewDate,
    required this.onPickFollowUpDate,
    required this.onClearFollowUpDate,
    required this.onStatusChanged,
  });

  final JobApplicationFormState state;
  final VoidCallback onPickAppliedDate;
  final VoidCallback onPickDeadlineDate;
  final VoidCallback onClearDeadlineDate;
  final VoidCallback onPickInterviewDate;
  final VoidCallback onClearInterviewDate;
  final VoidCallback onPickFollowUpDate;
  final VoidCallback onClearFollowUpDate;
  final ValueChanged<JobApplicationStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    String optional(DateTime? value) =>
        value == null ? 'Optional' : DateFormatter.shortDate(value);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Timeline and status'),
          const SizedBox(height: AppSpacing.s14),
          Text('Status', style: AppTextStyles.fieldLabel),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final status in JobFilterChips.order)
                AppChip(
                  label: status.label,
                  variant: status == state.status
                      ? AppChipVariant.selected
                      : AppChipVariant.neutral,
                  onTap: () => onStatusChanged(status),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          _DateSelectorTile(
            label: 'Applied date',
            value: DateFormatter.shortDate(state.appliedDate),
            onTap: onPickAppliedDate,
          ),
          const SizedBox(height: AppSpacing.s10),
          _DateSelectorTile(
            label: 'Deadline date',
            value: optional(state.deadlineDate),
            onTap: onPickDeadlineDate,
            onClear: state.deadlineDate == null ? null : onClearDeadlineDate,
          ),
          const SizedBox(height: AppSpacing.s10),
          _DateSelectorTile(
            label: 'Interview date',
            value: optional(state.interviewDate),
            onTap: onPickInterviewDate,
            onClear: state.interviewDate == null ? null : onClearInterviewDate,
          ),
          const SizedBox(height: AppSpacing.s10),
          _DateSelectorTile(
            label: 'Follow-up reminder date',
            value: optional(state.followUpDate),
            onTap: onPickFollowUpDate,
            onClear: state.followUpDate == null ? null : onClearFollowUpDate,
          ),
        ],
      ),
    );
  }
}

class _ContactAndNotesCard extends StatelessWidget {
  const _ContactAndNotesCard({
    required this.jobPostLinkController,
    required this.salaryRangeController,
    required this.contactPersonController,
    required this.contactEmailController,
    required this.notesController,
  });

  final TextEditingController jobPostLinkController;
  final TextEditingController salaryRangeController;
  final TextEditingController contactPersonController;
  final TextEditingController contactEmailController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Reference details'),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: jobPostLinkController,
            label: 'Job post link',
            hintText: 'Optional',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: salaryRangeController,
            label: 'Salary range',
            hintText: 'Optional',
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: contactPersonController,
            label: 'Contact person',
            hintText: 'Optional',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextField(
            controller: contactEmailController,
            label: 'Contact email',
            hintText: 'Optional',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: notesController,
            label: 'Notes',
            hintText:
                'Interview rounds, recruiter message, next follow-up, salary '
                'expectation, or application notes.',
            minLines: 4,
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}

class _DateSelectorTile extends StatelessWidget {
  const _DateSelectorTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadii.inputRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.inputRadius,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s10,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.inputRadius,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.fieldLabel),
                    Text(
                      value,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.muted2,
                  tooltip: 'Clear date',
                ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
