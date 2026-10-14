import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_market_blocks.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_template_builders.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final cvPdfServiceProvider = Provider<CvPdfService>((ref) {
  return const CvPdfService();
});

/// Renders a [CvProfile] to an ATS-friendly, single-column, selectable PDF.
///
/// TODO(docx): DOCX export is intentionally not implemented here. Dart-side
/// .docx generators are fragile for rich CV layouts; the cleaner path is a
/// server-side conversion (render this PDF, or the structured profile, to DOCX
/// via a backend/Cloud Function) so formatting stays consistent. PDF is the
/// priority export for now.
class CvPdfService {
  const CvPdfService();

  /// [compress] exists so tests can read the page text straight out of the
  /// bytes; the app always leaves it on.
  Future<Uint8List> generateCvPdf({
    required CvProfile profile,
    PdfPageFormat? pageFormat,
    bool compress = true,
    DateTime? exportDate,
  }) async {
    final document = pw.Document(
      compress: compress,
      title: profile.displayTitle,
      author: 'CareerMate BD',
      creator: 'CareerMate BD',
      subject: 'ATS-friendly CV export',
    );

    // Every CvTemplate maps to a dedicated builder; the exhaustive switch means
    // a new enum value cannot silently fall back to another template.
    final extras = CvPdfContext(
      fallbackFonts: await _fallbackFonts(),
      exportDate: exportDate,
    );
    document.addPage(
      _buildPage(
        profile: profile,
        // The CV's own paper size, unless a caller asks for a specific one.
        pageFormat: pageFormat ?? pageFormatFor(profile.paperSize),
        extras: extras,
      ),
    );

    return document.save();
  }

  static PdfPageFormat pageFormatFor(PaperSize size) =>
      size == PaperSize.letter ? PdfPageFormat.letter : PdfPageFormat.a4;

  /// Noto Sans Bengali, bundled with the app. Without it (a test without
  /// assets) the PDF still renders, just without Bangla glyphs.
  Future<List<pw.Font>> _fallbackFonts() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/NotoSansBengali-Regular.ttf',
      );
      return [pw.Font.ttf(data)];
    } catch (_) {
      return const [];
    }
  }

  pw.MultiPage _buildPage({
    required CvProfile profile,
    required PdfPageFormat pageFormat,
    required CvPdfContext extras,
  }) {
    return switch (profile.template) {
      CvTemplate.classic => CvPdfTemplateBuilders.buildClassic(
        profile: profile,
        pageFormat: pageFormat,
        extras: extras,
      ),
      CvTemplate.modern => CvPdfTemplateBuilders.buildModern(
        profile: profile,
        pageFormat: pageFormat,
        extras: extras,
      ),
      CvTemplate.minimal => CvPdfTemplateBuilders.buildMinimal(
        profile: profile,
        pageFormat: pageFormat,
        extras: extras,
      ),
      CvTemplate.professional => CvPdfTemplateBuilders.buildProfessional(
        profile: profile,
        pageFormat: pageFormat,
        extras: extras,
      ),
      CvTemplate.fresher => CvPdfTemplateBuilders.buildFresher(
        profile: profile,
        pageFormat: pageFormat,
        extras: extras,
      ),
    };
  }

  String buildFileName(CvProfile profile) {
    final baseName = profile.displayTitle
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safeName = baseName.isEmpty ? 'cv_export' : baseName;
    // "Staff Nurse CV" is already a CV: don't append a second "_cv".
    final alreadyNamedCv = RegExp(r'(^|_)cv(_|$)').hasMatch(safeName);
    return alreadyNamedCv ? '$safeName.pdf' : '${safeName}_cv.pdf';
  }
}
