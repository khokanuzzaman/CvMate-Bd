import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/subscription/presentation/export_gate.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CvPdfPreviewScreen extends ConsumerWidget {
  const CvPdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);
    final draft = state.draft;
    final pdfService = ref.read(cvPdfServiceProvider);
    final fileName = pdfService.buildFileName(draft);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'PDF Preview',
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
        child: state.hasActiveDraft && draft.hasContent
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton.secondary(
                            label: 'Share / Download',
                            icon: Icons.download_rounded,
                            onPressed: () =>
                                _sharePdf(context, ref, fileName: fileName),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Print',
                            icon: Icons.print_rounded,
                            onPressed: () =>
                                _printPdf(context, ref, fileName: fileName),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfPreview(
                      build: (format) => pdfService.generateCvPdf(
                        profile: draft,
                        pageFormat: format,
                      ),
                      initialPageFormat: PdfPageFormat.a4,
                      pdfFileName: fileName,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      maxPageWidth: AppConstants.contentMaxWidth,
                      loadingWidget: const CustomLoadingView(
                        message: 'Generating PDF preview...',
                      ),
                      onError: (context, error) {
                        return CustomErrorView(
                          title: 'PDF preview failed',
                          message: '$error',
                        );
                      },
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CustomEmptyState(
                    title: 'No CV content ready',
                    message:
                        'Open a saved CV or complete the builder first, then return here to preview the PDF export.',
                    icon: Icons.picture_as_pdf_outlined,
                    actionLabel: 'Open CV list',
                    onAction: () => context.go(RouteNames.cvListPath),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref, {
    required String fileName,
  }) async {
    final profile = ref.read(cvBuilderControllerProvider).draft;
    final pdfService = ref.read(cvPdfServiceProvider);

    await runGatedExport(
      ref: ref,
      context: context,
      source: 'cv_pdf_preview',
      exportType: 'share',
      export: () async {
        final bytes = await pdfService.generateCvPdf(profile: profile);
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      },
    );
  }

  Future<void> _printPdf(
    BuildContext context,
    WidgetRef ref, {
    required String fileName,
  }) async {
    final profile = ref.read(cvBuilderControllerProvider).draft;
    final pdfService = ref.read(cvPdfServiceProvider);

    await runGatedExport(
      ref: ref,
      context: context,
      source: 'cv_pdf_preview',
      exportType: 'print',
      export: () => Printing.layoutPdf(
        name: fileName,
        onLayout: (format) =>
            pdfService.generateCvPdf(profile: profile, pageFormat: format),
      ),
    );
  }
}
