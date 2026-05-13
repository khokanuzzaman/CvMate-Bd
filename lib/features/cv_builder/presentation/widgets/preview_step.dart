import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_preview_content.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PreviewStep extends ConsumerWidget {
  const PreviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);
    final warnings = ref
        .read(cvBuilderControllerProvider.notifier)
        .previewWarnings();

    return CvStepSection(
      title: 'Preview your CV',
      description:
          'Review the structure, wording, and missing sections before exporting the PDF.',
      child: Column(
        children: [
          if (warnings.isNotEmpty)
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.info_outline_rounded, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(warning)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (warnings.isNotEmpty) const SizedBox(height: 16),
          CvPreviewContent(profile: state.draft),
          const SizedBox(height: 16),
          CustomButton.secondary(
            label: 'Open full preview',
            icon: Icons.open_in_full_rounded,
            onPressed: () => _openRoute(context, ref, RouteNames.cvPreviewPath),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Open PDF Preview',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () =>
                _openRoute(context, ref, RouteNames.cvPdfPreviewPath),
          ),
        ],
      ),
    );
  }

  Future<void> _openRoute(
    BuildContext context,
    WidgetRef ref,
    String routePath,
  ) async {
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

    context.push(routePath);
  }
}
