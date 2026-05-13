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

    final exportTemplate = _resolveExportTemplate(profile.template);
    final exportedProfile = profile.copyWith(template: exportTemplate);

    switch (exportTemplate) {
      case CvTemplate.classic:
        document.addPage(
          CvPdfTemplateBuilders.buildClassic(
            profile: exportedProfile,
            pageFormat: pageFormat,
          ),
        );
        break;
      case CvTemplate.modern:
        document.addPage(
          CvPdfTemplateBuilders.buildModern(
            profile: exportedProfile,
            pageFormat: pageFormat,
          ),
        );
        break;
      case CvTemplate.minimal:
        document.addPage(
          CvPdfTemplateBuilders.buildMinimal(
            profile: exportedProfile,
            pageFormat: pageFormat,
          ),
        );
        break;
      case CvTemplate.professional:
      case CvTemplate.fresher:
        break;
    }

    return document.save();
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

  CvTemplate _resolveExportTemplate(CvTemplate template) {
    return switch (template) {
      CvTemplate.classic => CvTemplate.classic,
      CvTemplate.modern => CvTemplate.modern,
      CvTemplate.minimal => CvTemplate.minimal,
      CvTemplate.professional => CvTemplate.classic,
      CvTemplate.fresher => CvTemplate.minimal,
    };
  }
}
