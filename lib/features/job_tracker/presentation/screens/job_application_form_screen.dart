import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_state.dart';
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
      appBar: CustomAppBar(
        title: state.isEditing ? 'Edit Application' : 'Add Application',
        actions: [
          IconButton(
            onPressed: state.isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save application',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
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
              _BasicsCard(
                state: state,
                companyController: _companyController,
                jobTitleController: _jobTitleController,
                onSourceChanged: (value) {
                  if (value != null) {
                    ref
                        .read(jobApplicationFormControllerProvider.notifier)
                        .updateJobSource(value);
                  }
                },
              ),
              const SizedBox(height: 20),
              _LinksCard(
                state: state,
                onCvChanged: (value) => ref
                    .read(jobApplicationFormControllerProvider.notifier)
                    .selectCv(value),
                onCoverLetterChanged: (value) => ref
                    .read(jobApplicationFormControllerProvider.notifier)
                    .selectCoverLetter(value),
              ),
              const SizedBox(height: 20),
              _TimelineCard(
                state: state,
                onPickAppliedDate: () => _pickDate(
                  initialDate: state.appliedDate,
                  onSelected: (value) => ref
                      .read(jobApplicationFormControllerProvider.notifier)
                      .updateAppliedDate(value),
                ),
                onPickDeadlineDate: () => _pickOptionalDate(
                  initialDate: state.deadlineDate ?? state.appliedDate,
                  onSelected: (value) => ref
                      .read(jobApplicationFormControllerProvider.notifier)
                      .updateDeadlineDate(value),
                ),
                onClearDeadlineDate: () => ref
                    .read(jobApplicationFormControllerProvider.notifier)
                    .updateDeadlineDate(null),
                onPickInterviewDate: () => _pickOptionalDate(
                  initialDate: state.interviewDate ?? state.appliedDate,
                  onSelected: (value) => ref
                      .read(jobApplicationFormControllerProvider.notifier)
                      .updateInterviewDate(value),
                ),
                onClearInterviewDate: () => ref
                    .read(jobApplicationFormControllerProvider.notifier)
                    .updateInterviewDate(null),
                onPickFollowUpDate: () => _pickOptionalDate(
                  initialDate: state.followUpDate ?? state.appliedDate,
                  onSelected: (value) => ref
                      .read(jobApplicationFormControllerProvider.notifier)
                      .updateFollowUpDate(value),
                ),
                onClearFollowUpDate: () => ref
                    .read(jobApplicationFormControllerProvider.notifier)
                    .updateFollowUpDate(null),
                onStatusChanged: (value) {
                  if (value != null) {
                    ref
                        .read(jobApplicationFormControllerProvider.notifier)
                        .updateStatus(value);
                  }
                },
              ),
              const SizedBox(height: 20),
              _ContactAndNotesCard(
                jobPostLinkController: _jobPostLinkController,
                salaryRangeController: _salaryRangeController,
                contactPersonController: _contactPersonController,
                contactEmailController: _contactEmailController,
                notesController: _notesController,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                _InlineErrorCard(message: state.errorMessage!),
              ],
              const SizedBox(height: 20),
              CustomButton(
                label: state.isSaving ? 'Saving...' : 'Save application',
                onPressed: state.isSaving ? null : _save,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
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
  final ValueChanged<JobSource?> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application basics', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          CustomTextField(
            controller: companyController,
            label: 'Company name',
            hintText: 'Bdjobs, BRAC Bank, Unilever Bangladesh',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobTitleController,
            label: 'Job title',
            hintText: 'Management Trainee, Flutter Developer',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<JobSource>(
            initialValue: state.jobSource,
            onChanged: onSourceChanged,
            decoration: const InputDecoration(labelText: 'Job source'),
            items: [
              for (final source in JobSource.values)
                DropdownMenuItem(value: source, child: Text(source.label)),
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
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linked assets', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Connect the exact CV and cover letter draft you used for this application.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: state.selectedCvId,
            onChanged: onCvChanged,
            decoration: const InputDecoration(labelText: 'Linked CV'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No linked CV'),
              ),
              for (final cv in state.availableCvs)
                DropdownMenuItem<String?>(
                  value: cv.id,
                  child: Text('${cv.displayTitle} • ${cv.displayRole}'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: state.selectedCoverLetterId,
            onChanged: onCoverLetterChanged,
            decoration: const InputDecoration(labelText: 'Linked cover letter'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No linked cover letter'),
              ),
              for (final draft in state.availableCoverLetters)
                DropdownMenuItem<String?>(
                  value: draft.id,
                  child: Text(draft.displayTitle),
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
  final ValueChanged<JobApplicationStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline and status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<JobApplicationStatus>(
            initialValue: state.status,
            onChanged: onStatusChanged,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in JobApplicationStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
          ),
          const SizedBox(height: 16),
          _DateSelectorTile(
            label: 'Applied date',
            value: DateFormatter.shortDate(state.appliedDate),
            onTap: onPickAppliedDate,
          ),
          const SizedBox(height: 12),
          _DateSelectorTile(
            label: 'Deadline date',
            value: state.deadlineDate == null
                ? 'Optional'
                : DateFormatter.shortDate(state.deadlineDate!),
            onTap: onPickDeadlineDate,
            onClear: state.deadlineDate == null ? null : onClearDeadlineDate,
          ),
          const SizedBox(height: 12),
          _DateSelectorTile(
            label: 'Interview date',
            value: state.interviewDate == null
                ? 'Optional'
                : DateFormatter.shortDate(state.interviewDate!),
            onTap: onPickInterviewDate,
            onClear: state.interviewDate == null ? null : onClearInterviewDate,
          ),
          const SizedBox(height: 12),
          _DateSelectorTile(
            label: 'Follow-up reminder date',
            value: state.followUpDate == null
                ? 'Optional'
                : DateFormatter.shortDate(state.followUpDate!),
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
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reference details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          CustomTextField(
            controller: jobPostLinkController,
            label: 'Job post link',
            hintText: 'Optional',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: salaryRangeController,
            label: 'Salary range',
            hintText: 'Optional',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: contactPersonController,
            label: 'Contact person',
            hintText: 'Optional',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: contactEmailController,
            label: 'Contact email',
            hintText: 'Optional',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: notesController,
            label: 'Notes',
            hintText:
                'Interview rounds, recruiter message, next follow-up, salary expectation, or application notes.',
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label), const SizedBox(height: 4), Text(value)],
            ),
          ),
          if (onClear != null) ...[
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Clear date',
            ),
          ],
          const Icon(Icons.calendar_today_outlined, size: 18),
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
