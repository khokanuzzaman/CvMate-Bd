import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class CvPdfTemplateBuilders {
  static pw.MultiPage buildClassic({
    required CvProfile profile,
    required PdfPageFormat pageFormat,
  }) {
    return pw.MultiPage(
      pageTheme: _pageTheme(pageFormat),
      footer: _pageFooter,
      build: (context) => [
        _classicHeader(profile),
        pw.SizedBox(height: 18),
        ..._sharedSections(
          profile,
          sectionTitleBuilder: (title) => _classicSectionTitle(title),
        ),
      ],
    );
  }

  static pw.MultiPage buildModern({
    required CvProfile profile,
    required PdfPageFormat pageFormat,
  }) {
    return pw.MultiPage(
      pageTheme: _pageTheme(pageFormat),
      footer: _pageFooter,
      build: (context) => [
        _modernHeader(profile),
        pw.SizedBox(height: 18),
        ..._sharedSections(
          profile,
          sectionTitleBuilder: (title) => _modernSectionTitle(title),
        ),
      ],
    );
  }

  static pw.MultiPage buildMinimal({
    required CvProfile profile,
    required PdfPageFormat pageFormat,
  }) {
    return pw.MultiPage(
      pageTheme: _pageTheme(pageFormat),
      footer: _pageFooter,
      build: (context) => [
        _minimalHeader(profile),
        pw.SizedBox(height: 18),
        ..._sharedSections(
          profile,
          sectionTitleBuilder: (title) => _minimalSectionTitle(title),
        ),
      ],
    );
  }

  static pw.PageTheme _pageTheme(PdfPageFormat pageFormat) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 28),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  static pw.Widget _classicHeader(CvProfile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          profile.displayName,
          style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 24),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          profile.displayRole,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 10),
        _contactWrap(profile),
        pw.SizedBox(height: 14),
        pw.Divider(thickness: 1.1, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _modernHeader(CvProfile profile) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          color: PdfColors.grey900,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.displayName,
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 24,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                profile.displayRole,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: _contactWrap(profile),
        ),
      ],
    );
  }

  static pw.Widget _minimalHeader(CvProfile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          profile.displayName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 23),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          profile.displayRole,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: _contactWrap(profile, alignment: pw.WrapAlignment.center),
        ),
        pw.SizedBox(height: 14),
        pw.Divider(thickness: 0.9, color: PdfColors.grey700),
      ],
    );
  }

  static pw.Widget _classicSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.8, color: PdfColors.grey700),
        ],
      ),
    );
  }

  static pw.Widget _modernSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: PdfColors.grey900,
        child: pw.Text(
          title,
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 11,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _minimalSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static List<pw.Widget> _sharedSections(
    CvProfile profile, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    final widgets = <pw.Widget>[];

    _appendSimpleSection(
      widgets,
      title: 'Professional Summary',
      content: profile.professionalSummary,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendSimpleSection(
      widgets,
      title: 'Career Objective',
      content: profile.careerObjective,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendEducationSection(
      widgets,
      profile.education,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendExperienceSection(
      widgets,
      profile.experiences,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendSkillsSection(
      widgets,
      profile,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendProjectsSection(
      widgets,
      profile.projects,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendTrainingSection(
      widgets,
      profile.trainings,
      sectionTitleBuilder: sectionTitleBuilder,
    );
    _appendLanguagesSection(
      widgets,
      profile,
      sectionTitleBuilder: sectionTitleBuilder,
    );

    if (widgets.isEmpty) {
      widgets.add(
        pw.Text(
          'This CV draft is still empty. Complete the builder before exporting.',
          style: const pw.TextStyle(fontSize: 11),
        ),
      );
    }

    return widgets;
  }

  static void _appendSimpleSection(
    List<pw.Widget> widgets, {
    required String title,
    required String content,
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder(title));
    widgets.add(
      pw.Text(text, style: const pw.TextStyle(fontSize: 10.8, lineSpacing: 3)),
    );
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendEducationSection(
    List<pw.Widget> widgets,
    List<EducationInfo> items, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (items.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Education'));
    for (final item in items) {
      widgets.add(
        _entryBlock(
          title: item.degree,
          subtitle: item.institution,
          meta: _joinNonEmpty([
            item.fieldOfStudy,
            item.location,
            item.isOngoing
                ? _joinNonEmpty([item.startYear, 'Present'], separator: ' - ')
                : _joinNonEmpty([
                    item.startYear,
                    item.endYear,
                  ], separator: ' - '),
          ]),
          description: item.result,
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendExperienceSection(
    List<pw.Widget> widgets,
    List<ExperienceInfo> items, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (items.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Experience'));
    for (final item in items) {
      widgets.add(
        _entryBlock(
          title: item.jobTitle,
          subtitle: item.companyName,
          meta: _joinNonEmpty([
            item.location,
            item.isCurrentRole
                ? _joinNonEmpty([item.startDate, 'Present'], separator: ' - ')
                : _joinNonEmpty([
                    item.startDate,
                    item.endDate,
                  ], separator: ' - '),
          ]),
          bullets: item.highlights,
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendSkillsSection(
    List<pw.Widget> widgets,
    CvProfile profile, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (profile.skills.isEmpty) {
      return;
    }

    final skillText = profile.skills
        .map(
          (item) => item.level.trim().isEmpty
              ? item.name.trim()
              : '${item.name.trim()} (${item.level.trim()})',
        )
        .where((item) => item.isNotEmpty)
        .join(' | ');

    if (skillText.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Skills'));
    widgets.add(
      pw.Text(
        skillText,
        style: const pw.TextStyle(fontSize: 10.8, lineSpacing: 3),
      ),
    );
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendProjectsSection(
    List<pw.Widget> widgets,
    List<ProjectInfo> items, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (items.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Projects'));
    for (final item in items) {
      widgets.add(
        _entryBlock(
          title: item.title,
          subtitle: item.role,
          meta: item.link,
          description: item.description,
          bullets: item.technologies.isEmpty
              ? const []
              : ['Technologies: ${item.technologies.join(', ')}'],
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendTrainingSection(
    List<pw.Widget> widgets,
    List<TrainingInfo> items, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (items.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Training / Certifications'));
    for (final item in items) {
      widgets.add(
        _entryBlock(
          title: item.title,
          subtitle: item.organization,
          meta: item.completionYear,
          description: item.details,
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 14));
  }

  static void _appendLanguagesSection(
    List<pw.Widget> widgets,
    CvProfile profile, {
    required pw.Widget Function(String title) sectionTitleBuilder,
  }) {
    if (profile.languages.isEmpty) {
      return;
    }

    final languageText = profile.languages
        .map(
          (item) =>
              _joinNonEmpty([item.name, item.proficiency], separator: ' - '),
        )
        .where((item) => item.isNotEmpty)
        .join(' | ');

    if (languageText.isEmpty) {
      return;
    }

    widgets.add(sectionTitleBuilder('Languages'));
    widgets.add(
      pw.Text(
        languageText,
        style: const pw.TextStyle(fontSize: 10.8, lineSpacing: 3),
      ),
    );
    widgets.add(pw.SizedBox(height: 14));
  }

  static pw.Widget _entryBlock({
    required String title,
    required String subtitle,
    required String meta,
    String description = '',
    List<String> bullets = const [],
  }) {
    final cleanedBullets = bullets
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty)
            pw.Text(
              title.trim(),
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11),
            ),
          if (subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(subtitle.trim(), style: const pw.TextStyle(fontSize: 10.6)),
          ],
          if (meta.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              meta.trim(),
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.grey700,
              ),
            ),
          ],
          if (description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              description.trim(),
              style: const pw.TextStyle(fontSize: 10.4, lineSpacing: 2.5),
            ),
          ],
          for (final bullet in cleanedBullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('- ', style: const pw.TextStyle(fontSize: 10.4)),
                  pw.Expanded(
                    child: pw.Text(
                      bullet,
                      style: const pw.TextStyle(
                        fontSize: 10.4,
                        lineSpacing: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _contactWrap(
    CvProfile profile, {
    pw.WrapAlignment alignment = pw.WrapAlignment.start,
  }) {
    final values = [
      profile.personalInfo.email,
      profile.personalInfo.phone,
      profile.personalInfo.address,
      profile.personalInfo.linkedInUrl,
      profile.personalInfo.portfolioUrl,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    if (values.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Wrap(
      alignment: alignment,
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final value in values)
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
      ],
    );
  }

  static String _joinNonEmpty(List<String> values, {String separator = ' | '}) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(separator);
  }
}
