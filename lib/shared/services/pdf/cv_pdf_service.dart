import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_template_builders.dart';
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

  Future<Uint8List> generateCvPdf({
    required CvProfile profile,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final document = pw.Document(
      title: profile.displayTitle,
      author: 'CareerMate BD',
      creator: 'CareerMate BD',
      subject: 'ATS-friendly CV export',
    );

    // Every CvTemplate maps to a dedicated builder; the exhaustive switch means
    // a new enum value cannot silently fall back to another template.
    document.addPage(_buildPage(profile: profile, pageFormat: pageFormat));

    return document.save();
  }

  pw.MultiPage _buildPage({
    required CvProfile profile,
    required PdfPageFormat pageFormat,
  }) {
    return switch (profile.template) {
      CvTemplate.classic => CvPdfTemplateBuilders.buildClassic(
        profile: profile,
        pageFormat: pageFormat,
      ),
      CvTemplate.modern => CvPdfTemplateBuilders.buildModern(
        profile: profile,
        pageFormat: pageFormat,
      ),
      CvTemplate.minimal => CvPdfTemplateBuilders.buildMinimal(
        profile: profile,
        pageFormat: pageFormat,
      ),
      CvTemplate.professional => CvPdfTemplateBuilders.buildProfessional(
        profile: profile,
        pageFormat: pageFormat,
      ),
      CvTemplate.fresher => CvPdfTemplateBuilders.buildFresher(
        profile: profile,
        pageFormat: pageFormat,
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
    return '${safeName}_cv.pdf';
  }
}
