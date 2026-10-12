import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_preview_content.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/preview_warnings_banner.dart';
import 'package:careermatebd/features/subscription/presentation/export_gate.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

/// Paper-style CV preview with the template picker and PDF export. Export still
/// goes through [runGatedExport] (first export free, then the paywall).
class CvPreviewScreen extends ConsumerWidget {
  const CvPreviewScreen({super.key});

  static const String _exportSource = 'cv_preview';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);

    if (state.isLoading && !state.hasActiveDraft) {
      return const Scaffold(
        backgroundColor: AppColors.previewBg,
        body: SafeArea(
          child: CustomLoadingView(message: AppStrings.previewLoading),
        ),
      );
    }

    if (!state.hasActiveDraft) {
      return Scaffold(
        backgroundColor: AppColors.previewBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s22),
              child: CustomEmptyState(
                title: AppStrings.builderNoDraftTitle,
                message: AppStrings.previewNoDraftBody,
                icon: Icons.preview_outlined,
                actionLabel: AppStrings.previewOpenCvList,
                onAction: () => context.go(RouteNames.cvListPath),
              ),
            ),
          ),
        ),
      );
    }

    final draft = state.draft;
    final warnings = ref
        .read(cvBuilderControllerProvider.notifier)
        .previewWarnings();

    return Scaffold(
      backgroundColor: AppColors.previewBg,
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
              child: Row(
                children: [
                  Expanded(
                    child: AppTopBar(
                      title: AppStrings.previewTitle,
                      onBack: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  _TemplatePill(
                    template: draft.template,
                    onTap: () => context.push(RouteNames.cvTemplatePath),
                  ),
                  _OverflowMenu(
                    canPrint: draft.hasContent,
                    onPrint: () => _export(context, ref, _ExportKind.print),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s8,
                  AppSpacing.screen,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PreviewWarningsBanner(warnings: warnings),
                    if (warnings.isNotEmpty)
                      const SizedBox(height: AppSpacing.s12),
                    CvPreviewContent(profile: draft),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s4,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 40,
                    child: SecondaryButton(
                      label: AppStrings.previewTemplate,
                      leadingIcon: Icons.grid_view_rounded,
                      outlineColor: AppColors.lineStrong,
                      onPressed: () => context.push(RouteNames.cvTemplatePath),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    flex: 60,
                    child: PrimaryButton(
                      label: AppStrings.previewExport,
                      leadingIcon: Icons.file_download_outlined,
                      onPressed: draft.hasContent
                          ? () => _export(context, ref, _ExportKind.share)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shares or prints the PDF. Both go through [runGatedExport], so the fair
  /// export rule (first export free, then the paywall) applies to each.
  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    _ExportKind kind,
  ) async {
    await ref.read(cvBuilderControllerProvider.notifier).flushAutosave();
    if (!context.mounted) {
      return;
    }

    final state = ref.read(cvBuilderControllerProvider);
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }

    final profile = state.draft;
    final pdfService = ref.read(cvPdfServiceProvider);
    final fileName = pdfService.buildFileName(profile);

    await runGatedExport(
      ref: ref,
      context: context,
      source: _exportSource,
      exportType: kind.name,
      export: () async {
        switch (kind) {
          case _ExportKind.share:
            final bytes = await pdfService.generateCvPdf(profile: profile);
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          case _ExportKind.print:
            await Printing.layoutPdf(
              name: fileName,
              onLayout: (format) => pdfService.generateCvPdf(
                profile: profile,
                pageFormat: format,
              ),
            );
        }
      },
    );
  }
}

enum _ExportKind { share, print }

/// The ⋮ menu in the top bar; currently just Print.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.canPrint, required this.onPrint});

  final bool canPrint;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportKind>(
      tooltip: AppStrings.previewMoreOptions,
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.inputRadius,
        side: BorderSide(color: AppColors.line),
      ),
      onSelected: (_) => onPrint(),
      itemBuilder: (context) => [
        PopupMenuItem<_ExportKind>(
          value: _ExportKind.print,
          enabled: canPrint,
          child: Row(
            children: [
              const Icon(
                Icons.print_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(AppStrings.previewPrint, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

/// The current template's name as a white pill; tapping opens the picker.
class _TemplatePill extends StatelessWidget {
  const _TemplatePill({required this.template, required this.onTap});

  final CvTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.previewChangeTemplate,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.pillRadius,
                border: Border.all(color: AppColors.line),
              ),
              child: ExcludeSemantics(
                child: Text(
                  template.label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
