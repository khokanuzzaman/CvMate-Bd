import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_page.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/inline_error_card.dart';
import 'package:careermatebd/core/widgets/picker_field.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_state.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_form_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The messages [JobApplicationFormController.save] returns on success; the
/// screen closes and passes them back to the list.
const String _savedMessage = 'Application saved.';
const String _updatedMessage = 'Application updated.';

/// Add or edit a job application. All work happens in
/// [JobApplicationFormController].
class JobApplicationFormScreen extends ConsumerStatefulWidget {
  const JobApplicationFormScreen({super.key, this.applicationId});

  final String? applicationId;

  @override
  ConsumerState<JobApplicationFormScreen> createState() =>
      _JobApplicationFormScreenState();
}

class _JobApplicationFormScreenState
    extends ConsumerState<JobApplicationFormScreen> {
  final _company = TextEditingController();
  final _jobTitle = TextEditingController();
  final _jobPostLink = TextEditingController();
  final _salaryRange = TextEditingController();
  final _contactPerson = TextEditingController();
  final _contactEmail = TextEditingController();
  final _notes = TextEditingController();

  JobApplicationFormController get _controller =>
      ref.read(jobApplicationFormControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _company.addListener(() => _controller.updateCompanyName(_company.text));
    _jobTitle.addListener(() => _controller.updateJobTitle(_jobTitle.text));
    _jobPostLink.addListener(
      () => _controller.updateJobPostLink(_jobPostLink.text),
    );
    _salaryRange.addListener(
      () => _controller.updateSalaryRange(_salaryRange.text),
    );
    _contactPerson.addListener(
      () => _controller.updateContactPerson(_contactPerson.text),
    );
    _contactEmail.addListener(
      () => _controller.updateContactEmail(_contactEmail.text),
    );
    _notes.addListener(() => _controller.updateNotes(_notes.text));
    Future.microtask(
      () => _controller.initialize(applicationId: widget.applicationId),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _company,
      _jobTitle,
      _jobPostLink,
      _salaryRange,
      _contactPerson,
      _contactEmail,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobApplicationFormControllerProvider);
    _sync(_company, state.companyName);
    _sync(_jobTitle, state.jobTitle);
    _sync(_jobPostLink, state.jobPostLink);
    _sync(_salaryRange, state.salaryRange);
    _sync(_contactPerson, state.contactPerson);
    _sync(_contactEmail, state.contactEmail);
    _sync(_notes, state.notes);

    return AppPage(
      title: state.isEditing
          ? AppStrings.jobFormEditTitle
          : AppStrings.jobFormAddTitle,
      onBack: () => context.pop(),
      footer: AppPageFooter(
        child: PrimaryButton(
          label: state.isSaving
              ? AppStrings.jobFormSaving
              : AppStrings.jobFormSave,
          leadingIcon: Icons.save_outlined,
          onPressed: state.isSaving ? null : _save,
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(JobApplicationFormState state) {
    if (state.isLoading && !state.hasInitialized) {
      return const CustomLoadingView(message: AppStrings.jobFormLoading);
    }

    if (state.errorMessage != null &&
        state.applicationId == null &&
        widget.applicationId != null &&
        state.companyName.trim().isEmpty) {
      return CustomErrorView(
        title: AppStrings.jobFormLoadErrorTitle,
        message: state.errorMessage!,
        onRetry: () => _controller.initialize(
          applicationId: widget.applicationId,
          force: true,
        ),
      );
    }

    return AppPageScroll(
      children: [
        JobFormBasics(
          state: state,
          form: _form,
          onSourceChanged: _controller.updateJobSource,
        ),
        const SizedBox(height: AppSpacing.s16),
        JobFormLinks(
          state: state,
          onPickCv: () => _pickCv(state),
          onPickCoverLetter: () => _pickCoverLetter(state),
        ),
        const SizedBox(height: AppSpacing.s16),
        JobFormTimeline(
          state: state,
          onStatusChanged: _controller.updateStatus,
          onPickApplied: () =>
              _pickDate(state.appliedDate, _controller.updateAppliedDate),
          onPickDeadline: () => _pickDate(
            state.deadlineDate ?? state.appliedDate,
            _controller.updateDeadlineDate,
          ),
          onClearDeadline: () => _controller.updateDeadlineDate(null),
          onPickInterview: () => _pickDate(
            state.interviewDate ?? state.appliedDate,
            _controller.updateInterviewDate,
          ),
          onClearInterview: () => _controller.updateInterviewDate(null),
          onPickFollowUp: () => _pickDate(
            state.followUpDate ?? state.appliedDate,
            _controller.updateFollowUpDate,
          ),
          onClearFollowUp: () => _controller.updateFollowUpDate(null),
        ),
        const SizedBox(height: AppSpacing.s16),
        JobFormReference(form: _form),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s16),
          InlineErrorCard(message: state.errorMessage!),
        ],
      ],
    );
  }

  JobFormControllers get _form => JobFormControllers(
    company: _company,
    jobTitle: _jobTitle,
    jobPostLink: _jobPostLink,
    salaryRange: _salaryRange,
    contactPerson: _contactPerson,
    contactEmail: _contactEmail,
    notes: _notes,
  );

  Future<void> _pickCv(JobApplicationFormState state) async {
    final id = await showCvPickerSheet(
      context,
      cvs: state.availableCvs,
      selectedId: state.selectedCvId,
      noneLabel: AppStrings.jobFormNoLinkedCv,
    );
    if (id != null && mounted) {
      _controller.selectCv(id == kNoCvChoice ? null : id);
    }
  }

  Future<void> _pickCoverLetter(JobApplicationFormState state) async {
    final id = await showOptionSheet(
      context,
      title: AppStrings.jobFormLinkedCoverLetter,
      selectedId: state.selectedCoverLetterId,
      noneLabel: AppStrings.jobFormNoLinkedCoverLetter,
      options: [
        for (final draft in state.availableCoverLetters)
          OptionItem(id: draft.id, title: draft.displayTitle),
      ],
    );
    if (id != null && mounted) {
      _controller.selectCoverLetter(id == kNoOptionChoice ? null : id);
    }
  }

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> onSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _save() async {
    final message = await _controller.save();
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    if (message == _savedMessage || message == _updatedMessage) {
      context.pop(message);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
}
