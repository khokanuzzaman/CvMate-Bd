import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// What every template needs besides the CV itself: a fallback font for
/// scripts Helvetica cannot draw (Bangla) and the date printed on the
/// declaration when the user left it as "date of export".
class CvPdfContext {
  const CvPdfContext({this.fallbackFonts = const [], DateTime? exportDate})
    : _exportDate = exportDate;

  final List<pw.Font> fallbackFonts;
  final DateTime? _exportDate;

  DateTime get exportDate => _exportDate ?? DateTime.now();
}

/// The market-style blocks shared by all five templates: the photo beside the
/// header, the personal-details section, and the declaration with signature.
/// Everything is skipped for a CV that does not show it, so an international CV
/// prints exactly what it always did (single column, no photo).
abstract final class CvPdfMarketBlocks {
  /// 35x45 passport ratio, in PDF points (about 23x29 mm).
  static const double _photoWidth = 64;
  static const double _photoHeight = 82;

  static String _labelOf(PersonalField field) => switch (field) {
    PersonalField.dateOfBirth => 'Date of birth',
    PersonalField.nationality => 'Nationality',
    PersonalField.passport => 'Passport',
    PersonalField.visaStatus => 'Visa status',
    PersonalField.drivingLicence => 'Driving licence',
    PersonalField.maritalStatus => 'Marital status',
    PersonalField.religion => 'Religion',
    PersonalField.gender => 'Gender',
    _ => '',
  };

  /// [header] with the photo to its right, when the CV shows one.
  static pw.Widget headerWithPhoto(CvProfile profile, pw.Widget header) {
    final photo = profile.photoToShow;
    if (photo == null) {
      return header;
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: header),
        pw.SizedBox(width: 14),
        pw.Container(
          width: _photoWidth,
          height: _photoHeight,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 0.6),
          ),
          child: pw.Image(pw.MemoryImage(photo), fit: pw.BoxFit.cover),
        ),
      ],
    );
  }

  /// "Personal details": one "Label: value" line per shown field.
  static List<pw.Widget> details(
    CvProfile profile, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    final entries = profile.details.entries(profile.shownFields, _labelOf);
    if (entries.isEmpty) {
      return const [];
    }
    return [
      sectionTitleBuilder('Personal Details'),
      for (final entry in entries)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '${entry.label}: ',
                  style: pw.TextStyle(font: pw.Font.helveticaBold()),
                ),
                pw.TextSpan(text: entry.value),
              ],
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      pw.SizedBox(height: 12),
    ];
  }

  /// The declaration, with place and date on the left and the signature image
  /// on the right. The signature is just an image: not a digital certificate.
  static List<pw.Widget> declaration(CvProfile profile, CvPdfContext context) {
    final showDeclaration = profile.showDeclaration;
    final signature = profile.signatureToShow;
    if (!showDeclaration && signature == null) {
      return const [];
    }

    final declaration = profile.declaration;
    final place = declaration.place.trim();
    final date = declaration.date.trim().isEmpty
        ? formatDate(context.exportDate)
        : declaration.date.trim();

    return [
      pw.SizedBox(height: 18),
      if (showDeclaration)
        pw.Text(
          declaration.effectiveText,
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
        ),
      pw.SizedBox(height: 14),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (showDeclaration) ...[
                if (place.isNotEmpty)
                  pw.Text(
                    'Place: $place',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
              ],
            ],
          ),
          if (signature != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 120,
                  height: 46,
                  child: pw.Image(
                    pw.MemoryImage(signature),
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.Container(width: 120, height: 0.6, color: PdfColors.grey700),
                pw.SizedBox(height: 3),
                pw.Text(
                  profile.displayName,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "14 Oct 2026".
  static String formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
