import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_page.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_message_templates.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_details_provider.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_details_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One application: its status (tap to change), dates, links, notes, copyable
/// message templates, and edit / archive / delete.
class JobApplicationDetailsScreen extends ConsumerWidget {
  const JobApplicationDetailsScreen({super.key, this.applicationId});

  final String? applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = applicationId;
    if (id == null || id.trim().isEmpty) {
      return AppPage(
        title: AppStrings.jobDetailsTitle,
        onBack: () => context.pop(),
        body: const CustomErrorView(
          title: AppStrings.jobDetailsNotFoundTitle,
          message: AppStrings.jobDetailsNoIdBody,
        ),
      );
    }

    final details = ref.watch(jobApplicationDetailsProvider(id));

    return AppPage(
      title: AppStrings.jobDetailsTitle,
      onBack: () => context.pop(),
      trailingIcon: Icons.edit_outlined,
      trailingTooltip: AppStrings.jobDetailsEdit,
      onTrailingTap: () => _openEditForm(context, ref, id),
      body: details.when(
        loading: () =>
            const CustomLoadingView(message: AppStrings.jobDetailsLoading),
        error: (error, stackTrace) => CustomErrorView(
          title: AppStrings.jobDetailsLoadErrorTitle,
          message: AppStrings.trackerLoadErrorBody,
          onRetry: () => ref.invalidate(jobApplicationDetailsProvider(id)),
        ),
        data: (data) {
          if (data == null) {
            return const CustomErrorView(
              title: AppStrings.jobDetailsNotFoundTitle,
              message: AppStrings.jobDetailsMissingBody,
            );
          }

          final application = data.application;
          final archived = application.status == JobApplicationStatus.archived;
          return AppPageScroll(
            children: [
              JobDetailsHeader(application: application),
              const SizedBox(height: AppSpacing.s12),
              JobDetailsStatusCard(
                status: application.status,
                onChanged: (status) => _updateStatus(context, ref, id, status),
              ),
              const SizedBox(height: AppSpacing.s12),
              JobDetailsInfoCard(application: application),
              const SizedBox(height: AppSpacing.s12),
              JobDetailsLinkedCard(
                application: application,
                linkedCvTitle: data.cv?.displayTitle,
                linkedCoverLetterTitle: data.coverLetter?.displayTitle,
              ),
              const SizedBox(height: AppSpacing.s12),
              JobDetailsNotesCard(notes: application.notes),
              const SizedBox(height: AppSpacing.s12),
              JobDetailsTemplatesCard(
                onCopy: (type) => _copyTemplate(context, application, type),
              ),
              const SizedBox(height: AppSpacing.s12),
              PrimaryButton(
                label: AppStrings.jobDetailsEdit,
                leadingIcon: Icons.edit_outlined,
                onPressed: () => _openEditForm(context, ref, id),
              ),
              const SizedBox(height: AppSpacing.s10),
              SecondaryButton(
                label: archived
                    ? AppStrings.jobDetailsRestore
                    : AppStrings.jobDetailsArchive,
                leadingIcon: Icons.archive_outlined,
                onPressed: () => _updateStatus(
                  context,
                  ref,
                  id,
                  archived
                      ? JobApplicationStatus.applied
                      : JobApplicationStatus.archived,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              SecondaryButton(
                label: AppStrings.jobDetailsDelete,
                leadingIcon: Icons.delete_outline_rounded,
                outlineColor: AppColors.danger,
                foregroundColor: AppColors.danger,
                onPressed: () => _delete(context, ref, application),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditForm(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final path = Uri(
      path: RouteNames.jobApplicationFormPath,
      queryParameters: {'id': id},
    ).toString();
    final message = await context.push<String>(path);
    if (!context.mounted || message == null || message.trim().isEmpty) {
      return;
    }

    ref.invalidate(jobApplicationDetailsProvider(id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    JobApplicationStatus status,
  ) async {
    final updated = await ref
        .read(jobTrackerControllerProvider.notifier)
        .updateStatus(id, status);
    if (!context.mounted || updated == null) {
      return;
    }

    ref.invalidate(jobApplicationDetailsProvider(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.jobDetailsStatusUpdated(status.label))),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    JobApplication application,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.jobDetailsDeleteTitle),
        content: Text(
          AppStrings.jobDetailsDeleteBody(application.displayTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.jobDetailsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.jobDetailsDelete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }

    await ref
        .read(jobTrackerControllerProvider.notifier)
        .deleteApplication(application.id);
    if (!context.mounted) {
      return;
    }

    context.pop('Application deleted.');
  }

  Future<void> _copyTemplate(
    BuildContext context,
    JobApplication application,
    JobApplicationMessageTemplateType type,
  ) async {
    final text = JobApplicationMessageTemplates.build(type, application);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.jobDetailsTemplateCopied(type.label))),
    );
  }
}
