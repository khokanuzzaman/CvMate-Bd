import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_preview_pages_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The CV preview: the pages of the exported PDF, one sheet under another.
/// While a new PDF is built (e.g. after a template switch) the previous pages
/// stay visible under a thin progress bar.
class CvPdfPagesView extends ConsumerWidget {
  const CvPdfPagesView({super.key, required this.paperSize});

  /// Used for the empty sheet shown before the first pages exist.
  final PaperSize paperSize;

  static Key pageKey(int index) => ValueKey('cv-preview-page-$index');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(cvPreviewPagesProvider);
    final pages = preview.value;

    if (pages == null) {
      if (preview.hasError) {
        return _Sheet(
          aspectRatio: _aspect(paperSize),
          child: CustomErrorView(
            title: AppStrings.previewRenderFailedTitle,
            message: AppStrings.previewRenderFailedBody,
            onRetry: () => ref.invalidate(cvPreviewPagesProvider),
          ),
        );
      }
      return _Sheet(
        aspectRatio: _aspect(paperSize),
        child: const CustomLoadingView(message: AppStrings.previewRendering),
      );
    }

    final count = pages.pages.length;
    return Column(
      children: [
        SizedBox(
          height: 3,
          child: preview.isLoading
              ? const LinearProgressIndicator(minHeight: 3)
              : null,
        ),
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s16),
          Semantics(
            image: true,
            label: AppStrings.previewPageLabel(i + 1, count),
            child: _Sheet(
              key: pageKey(i),
              aspectRatio: pages.aspectRatio,
              child: Image.memory(
                pages.pages[i],
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static double _aspect(PaperSize size) =>
      size == PaperSize.letter ? 8.5 / 11 : 1 / 1.414;
}

/// A white page with the paper shadow, at the page's aspect ratio.
class _Sheet extends StatelessWidget {
  const _Sheet({super.key, required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.soft,
        ),
        child: child,
      ),
    );
  }
}
