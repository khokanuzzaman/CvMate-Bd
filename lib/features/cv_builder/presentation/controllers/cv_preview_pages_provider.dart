import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_rasterizer.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';

/// Resolution of the preview pages: an A4 page is 1240 px wide, sharp on a
/// 3x phone screen without holding huge bitmaps.
const double cvPreviewDpi = 150;

/// The preview of one draft: the PDF exactly as Export builds it, and its
/// pages as PNGs.
class CvPreviewPages {
  const CvPreviewPages({
    required this.profile,
    required this.pdf,
    required this.pages,
    required this.pageFormat,
  });

  /// The draft the pages were built from (template included).
  final CvProfile profile;
  final Uint8List pdf;
  final List<Uint8List> pages;
  final PdfPageFormat pageFormat;

  double get aspectRatio => pageFormat.width / pageFormat.height;
}

/// Builds the preview from the active draft with the same call Export uses
/// (`generateCvPdf(profile: draft)`), so the preview and the exported PDF have
/// the same layout, fonts and page breaks. Rebuilt whenever the draft changes,
/// e.g. after picking another template.
final cvPreviewPagesProvider = FutureProvider.autoDispose<CvPreviewPages>((
  ref,
) async {
  final draft = ref.watch(cvBuilderControllerProvider.select((s) => s.draft));
  final pdf = await ref
      .read(cvPdfServiceProvider)
      .generateCvPdf(profile: draft);
  final pages = await ref
      .read(cvPdfRasterizerProvider)
      .rasterize(pdf, dpi: cvPreviewDpi);
  return CvPreviewPages(
    profile: draft,
    pdf: pdf,
    pages: pages,
    pageFormat: CvPdfService.pageFormatFor(draft.paperSize),
  );
});
