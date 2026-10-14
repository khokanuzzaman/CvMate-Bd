import 'dart:convert';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';

/// The words of a CV's exported PDF in drawing order (which is reading order:
/// the exports are a single column), joined by single spaces. Reads the page
/// content straight from the uncompressed bytes — no PDF viewer needed.
Future<String> pdfText(CvProfile profile) async {
  final bytes = await const CvPdfService().generateCvPdf(
    profile: profile,
    compress: false,
  );
  final content = latin1.decode(bytes);
  final words = <String>[];
  for (final match in RegExp(r'\[\((.*?)\)\]TJ').allMatches(content)) {
    words.add(
      match
          .group(1)!
          .replaceAll(r'\(', '(')
          .replaceAll(r'\)', ')')
          .replaceAll(r'\\', r'\'),
    );
  }
  return words.join(' ');
}

/// Where [needle] first appears in [text], failing loudly when it does not.
int indexIn(String text, String needle) {
  final index = text.indexOf(needle);
  if (index < 0) {
    throw StateError('"$needle" is not in the PDF text:\n$text');
  }
  return index;
}
