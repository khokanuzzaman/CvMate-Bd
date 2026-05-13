import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _CvMenuAction { duplicate, delete }

class CvListScreen extends ConsumerWidget {
  const CvListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvLibrary = ref.watch(cvLibraryControllerProvider);
    final builderState = ref.watch(cvBuilderControllerProvider);
    final activeDraftId = builderState.hasActiveDraft
        ? builderState.draft.id
        : '';

    return Scaffold(
      appBar: const CustomAppBar(title: 'My CVs'),
      body: SafeArea(
        child: cvLibrary.when(
          loading: () =>
              const CustomLoadingView(message: 'Loading your saved CVs...'),
          error: (error, stackTrace) => CustomErrorView(
            title: 'Could not load saved CVs',
            message: 'Something went wrong. Please try again.',
            onRetry: () =>
                ref.read(cvLibraryControllerProvider.notifier).reload(),
          ),
          data: (cvs) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved CV library',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cvs.isEmpty
                                ? 'Create your first CV draft and keep it saved locally on this device.'
                                : '${cvs.length} saved CV${cvs.length == 1 ? '' : 's'} ready to edit, preview, and export again.',
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'Create new CV',
                            icon: Icons.add_rounded,
                            onPressed: () => _createNewCv(context, ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (cvs.isEmpty)
                      const CustomCard(
                        child: CustomEmptyState(
                          title: 'No CV created yet',
                          message:
                              'Create your first professional CV, save it locally, and come back anytime to update or re-export it.',
                          icon: Icons.description_outlined,
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final cv in cvs) ...[
                            _CvListCard(
                              cv: cv,
                              isActiveDraft: cv.id == activeDraftId,
                              onContinue: () =>
                                  _openBuilder(context, ref, cv.id),
                              onPreview: () =>
                                  _openPreview(context, ref, cv.id),
                              onActionSelected: (action) =>
                                  _handleMenuAction(context, ref, cv, action),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewCv(BuildContext context, WidgetRef ref) async {
    await ref.read(cvBuilderControllerProvider.notifier).startNewDraft();
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved locally.')));
    context.push(RouteNames.cvBuilderPath);
  }

  Future<void> _openBuilder(
    BuildContext context,
    WidgetRef ref,
    String cvId,
  ) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cvId);
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

    context.push(RouteNames.cvBuilderPath);
  }

  Future<void> _openPreview(
    BuildContext context,
    WidgetRef ref,
    String cvId,
  ) async {
    await ref.read(cvBuilderControllerProvider.notifier).loadDraft(cvId);
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

    context.push(RouteNames.cvPreviewPath);
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    CvProfile cv,
    _CvMenuAction action,
  ) async {
    switch (action) {
      case _CvMenuAction.duplicate:
        await _duplicateCv(context, ref, cv.id);
        break;
      case _CvMenuAction.delete:
        await _deleteCv(context, ref, cv);
        break;
    }
  }

  Future<void> _duplicateCv(
    BuildContext context,
    WidgetRef ref,
    String cvId,
  ) async {
    try {
      await ref.read(cvLibraryControllerProvider.notifier).duplicateCv(cvId);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV duplicated.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not duplicate this CV.')),
      );
    }
  }

  Future<void> _deleteCv(
    BuildContext context,
    WidgetRef ref,
    CvProfile cv,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete CV'),
          content: Text(
            'Delete "${cv.displayTitle}" from local storage? This action cannot be undone.',
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

    try {
      await ref.read(cvLibraryControllerProvider.notifier).deleteCv(cv.id);
      ref
          .read(cvBuilderControllerProvider.notifier)
          .clearActiveDraftIfMatches(cv.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV deleted.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this CV.')),
      );
    }
  }
}

class _CvListCard extends StatelessWidget {
  const _CvListCard({
    required this.cv,
    required this.isActiveDraft,
    required this.onContinue,
    required this.onPreview,
    required this.onActionSelected,
  });

  final CvProfile cv;
  final bool isActiveDraft;
  final VoidCallback onContinue;
  final VoidCallback onPreview;
  final ValueChanged<_CvMenuAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    Text(cv.displayTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      '${cv.displayName} • ${cv.displayRole}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Updated ${DateFormatter.shortDateTime(cv.updatedAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_CvMenuAction>(
                onSelected: onActionSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _CvMenuAction.duplicate,
                    child: Text('Duplicate CV'),
                  ),
                  PopupMenuItem(
                    value: _CvMenuAction.delete,
                    child: Text('Delete CV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${cv.education.length} education')),
              Chip(label: Text('${cv.experiences.length} experience')),
              Chip(label: Text('${cv.skills.length} skills')),
              Chip(label: Text(cv.template.label)),
              if (isActiveDraft) const Chip(label: Text('Current draft')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: isActiveDraft ? 'Continue draft' : 'Edit saved CV',
                  icon: Icons.edit_note_outlined,
                  onPressed: onContinue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton.secondary(
                  label: 'Preview',
                  icon: Icons.preview_outlined,
                  onPressed: onPreview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
