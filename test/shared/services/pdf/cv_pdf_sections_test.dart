import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pdf_text.dart';

/// A CV with every built-in section filled in, using words that are unique to
/// each section so the text order can be read from the PDF.
CvProfile _fullCv({CvTemplate template = CvTemplate.classic}) {
  return CvProfile.empty().copyWith(
    id: 'cv',
    title: 'Sections CV',
    template: template,
    personalInfo: const PersonalInfo(
      fullName: 'Nusrat Jahan',
      desiredRole: 'Staff Nurse',
      email: 'nusrat@email.com',
      phone: '01812345678',
      address: 'Dhaka',
    ),
    professionalSummary: 'SUMMARYBODY nurse with ward experience.',
    careerObjective: 'OBJECTIVEBODY seeking a hospital role.',
    education: [
      EducationInfo.empty(id: 'e').copyWith(
        degree: 'EDUCATIONBODY BSc Nursing',
        institution: 'Dhaka Nursing College',
      ),
    ],
    experiences: [
      ExperienceInfo.empty(id: 'x').copyWith(
        jobTitle: 'EXPERIENCEBODY Staff Nurse',
        companyName: 'City Hospital',
        highlights: const ['Monitored vital signs.'],
      ),
    ],
    skills: [
      SkillInfo.empty(id: 's').copyWith(name: 'SKILLSBODY Patient Care'),
    ],
    projects: [
      ProjectInfo.empty(id: 'p').copyWith(
        title: 'PROJECTSBODY Ward Checklist',
        description: 'Standardised handovers.',
      ),
    ],
    trainings: [
      TrainingInfo.empty(id: 't').copyWith(title: 'TRAININGBODY BLS'),
    ],
    languages: [
      LanguageInfo.empty(id: 'l').copyWith(name: 'LANGUAGESBODY Bangla'),
    ],
    customSections: const [
      CustomSection(
        id: 'custom-rows',
        title: 'Volunteering',
        layout: CustomSectionLayout.titledRows,
        items: [
          CustomSectionItem(
            id: 'r1',
            title: 'VOLROW Red Crescent',
            description: 'VOLDESC first-aid trainer.',
          ),
        ],
      ),
      CustomSection(
        id: 'custom-bullets',
        title: 'Awards',
        layout: CustomSectionLayout.bullets,
        items: [
          CustomSectionItem(id: 'b1', title: 'AWARDONE Best Nurse'),
          CustomSectionItem(
            id: 'b2',
            title: 'AWARDTWO Dean’s list',
            description: 'AWARDDESC 2019',
          ),
        ],
      ),
    ],
  );
}

/// Marker word of each built-in section's body, in the standard order.
const _bodyMarkers = {
  CvSectionKind.summary: 'SUMMARYBODY',
  CvSectionKind.objective: 'OBJECTIVEBODY',
  CvSectionKind.education: 'EDUCATIONBODY',
  CvSectionKind.experience: 'EXPERIENCEBODY',
  CvSectionKind.skills: 'SKILLSBODY',
  CvSectionKind.projects: 'PROJECTSBODY',
  CvSectionKind.training: 'TRAININGBODY',
  CvSectionKind.languages: 'LANGUAGESBODY',
};

List<String> _order(String text, Iterable<String> markers) {
  final found = {for (final m in markers) m: text.indexOf(m)}
    ..removeWhere((_, index) => index < 0);
  return (found.keys.toList()..sort((a, b) => found[a]!.compareTo(found[b]!)));
}

void main() {
  for (final template in CvTemplate.values) {
    group('${template.label} template', () {
      test('a CV with no layout prints its template default order', () async {
        final text = await pdfText(_fullCv(template: template));
        final expected = [
          for (final kind
              in template == CvTemplate.fresher
                  ? CvSectionLayout.fresherOrder
                  : CvSectionLayout.standardOrder)
            _bodyMarkers[kind]!,
        ];
        expect(_order(text, _bodyMarkers.values), expected);
      });

      test(
        'an explicit default layout prints exactly what no layout prints',
        () async {
          final plain = _fullCv(template: template);
          final explicit = plain.copyWith(
            sectionLayout: CvSectionLayout.defaultFor(template),
            customSections: const [],
          );
          expect(
            await pdfText(explicit),
            await pdfText(plain.copyWith(customSections: const [])),
          );
        },
      );

      test('follows the configured order, including custom sections', () async {
        final cv = _fullCv(template: template).copyWith(
          sectionLayout: [
            SectionConfig.builtIn(CvSectionKind.skills),
            SectionConfig.custom('custom-bullets'),
            SectionConfig.builtIn(CvSectionKind.education),
            SectionConfig.custom('custom-rows'),
            SectionConfig.builtIn(CvSectionKind.experience),
          ],
        );
        final text = await pdfText(cv);

        expect(
          _order(text, [
            'SKILLSBODY',
            'AWARDONE',
            'EDUCATIONBODY',
            'VOLROW',
            'EXPERIENCEBODY',
            'SUMMARYBODY', // not listed: appended after the configured ones
          ]),
          [
            'SKILLSBODY',
            'AWARDONE',
            'EDUCATIONBODY',
            'VOLROW',
            'EXPERIENCEBODY',
            'SUMMARYBODY',
          ],
        );
      });

      test('hidden sections are not printed, visible ones still are', () async {
        final cv = _fullCv(template: template).copyWith(
          sectionLayout: [
            SectionConfig.builtIn(CvSectionKind.summary, visible: false),
            SectionConfig.builtIn(CvSectionKind.projects, visible: false),
            SectionConfig.custom('custom-rows', visible: false),
          ],
        );
        final text = await pdfText(cv);

        expect(text, isNot(contains('SUMMARYBODY')));
        expect(text, isNot(contains('Professional Summary')));
        expect(text, isNot(contains('PROJECTSBODY')));
        expect(text, isNot(contains('VOLROW')));
        expect(text, isNot(contains('Volunteering')));
        expect(text, contains('EXPERIENCEBODY'));
        expect(text, contains('AWARDONE'));
      });

      test('renamed sections print their new title', () async {
        final cv = _fullCv(template: template).copyWith(
          sectionLayout: [
            SectionConfig.builtIn(
              CvSectionKind.experience,
              titleOverride: 'Work History',
            ),
            SectionConfig.builtIn(
              CvSectionKind.skills,
              titleOverride: 'Toolbox',
            ),
          ],
        );
        final text = await pdfText(cv);

        // Template styles may upper-case or letter-space titles; compare
        // case-insensitively.
        final lower = text.toLowerCase();
        expect(lower, contains('work history'));
        expect(lower, contains('toolbox'));
        expect(
          lower.indexOf('work history'),
          lessThan(lower.indexOf('experiencebody')),
          reason: 'the new title heads the section',
        );
        expect(lower, isNot(contains(' experience experiencebody')));
      });

      test('custom sections render in both layouts', () async {
        final text = await pdfText(_fullCv(template: template));
        final lower = text.toLowerCase();

        // titledRows: the heading, the row title, the description under it.
        expect(lower, contains('volunteering'));
        expect(_order(text, ['VOLROW', 'Crescent', 'VOLDESC']), [
          'VOLROW',
          'Crescent',
          'VOLDESC',
        ]);
        // bullets: every item is a "- " line; description joins the title.
        expect(lower, contains('awards'));
        expect(text, contains('- AWARDONE'));
        expect(text, contains('- AWARDTWO'));
        expect(text, contains('AWARDDESC'));
        expect(
          lower.indexOf('volunteering'),
          lessThan(lower.indexOf('awards')),
          reason: 'custom sections default to the end, in creation order',
        );
      });

      test('empty and typographic text in custom sections is safe', () async {
        final cv = _fullCv(template: template).copyWith(
          customSections: const [
            CustomSection(
              id: 'empty',
              title: 'Nothing here',
              items: [CustomSectionItem(id: 'x')],
            ),
            CustomSection(
              id: 'bul',
              title: 'Highlights',
              layout: CustomSectionLayout.bullets,
              items: [CustomSectionItem(id: 'y', title: '• LEADING bullet')],
            ),
          ],
        );
        final text = await pdfText(cv);

        expect(text, isNot(contains('Nothing')));
        expect(text, contains('- LEADING'));
        expect(text, isNot(contains('•')));
      });
    });
  }
}
