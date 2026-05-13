import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_preview_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CvPreviewScreen extends ConsumerWidget {
  const CvPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);
    final warnings = ref
        .read(cvBuilderControllerProvider.notifier)
        .previewWarnings();

    if (state.isLoading && !state.hasActiveDraft) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'CV Preview'),
        body: SafeArea(
          child: CustomLoadingView(message: 'Loading your CV preview...'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'CV Preview',
        actions: [
          IconButton(
            onPressed: state.hasActiveDraft
                ? () => context.push(RouteNames.aiImprovePath)
                : null,
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI Improve',
          ),
        ],
      ),
      body: SafeArea(
        child: !state.hasActiveDraft
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CustomEmptyState(
                    title: 'No CV draft ready',
                    message:
                        'Open a saved CV or create a new one before previewing.',
                    icon: Icons.preview_outlined,
                    actionLabel: 'Open CV list',
                    onAction: () => context.go(RouteNames.cvListPath),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.draft.displayTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Template: ${state.draft.template.label}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        if (state.lastSavedAt != null)
                          Text(
                            'Saved ${DateFormatter.shortDateTime(state.lastSavedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton.secondary(
                                label: 'Back to builder',
                                icon: Icons.edit_outlined,
                                onPressed: () => context.pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                label: 'Open PDF Preview',
                                icon: Icons.picture_as_pdf_outlined,
                                onPressed: () => _openPdfPreview(context, ref),
                              ),
                            ),
                          ],
                        ),
                        if (warnings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review notes',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                for (final warning in warnings)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(warning),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        CvPreviewContent(profile: state.draft),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _openPdfPreview(BuildContext context, WidgetRef ref) async {
    await ref.read(cvBuilderControllerProvider.notifier).flushAutosave();
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

    context.push(RouteNames.cvPdfPreviewPath);
  }
}
