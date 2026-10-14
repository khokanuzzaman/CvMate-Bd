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

void main() {
  test(
    'Classic PDF follows the layout: order, hidden, renamed, custom',
    () async {
      final cv = _fullCv().copyWith(
        sectionLayout: [
          SectionConfig.builtIn(CvSectionKind.skills, titleOverride: 'Toolbox'),
          SectionConfig.custom('custom-bullets'),
          SectionConfig.builtIn(CvSectionKind.education),
          SectionConfig.custom('custom-rows'),
          SectionConfig.builtIn(
            CvSectionKind.experience,
            titleOverride: 'Work History',
          ),
          SectionConfig.builtIn(CvSectionKind.summary, visible: false),
          SectionConfig.builtIn(CvSectionKind.projects, visible: false),
        ],
      );
      final text = await pdfText(cv);

      // Order (custom sections in both layouts sit between built-ins).
      const inOrder = [
        'SKILLSBODY',
        'AWARDONE',
        'EDUCATIONBODY',
        'VOLROW',
        'EXPERIENCEBODY',
      ];
      final positions = [for (final m in inOrder) indexIn(text, m)];
      expect(positions, [...positions]..sort());

      // Hidden sections are left out, the rest are still there.
      expect(text, isNot(contains('SUMMARYBODY')));
      expect(text, isNot(contains('PROJECTSBODY')));
      expect(text, contains('TRAININGBODY'));

      // Renamed titles replace the defaults.
      final lower = text.toLowerCase();
      expect(lower, contains('toolbox'));
      expect(lower, contains('work history'));
      expect(lower, isNot(contains(' experience experiencebody')));

      // Custom layouts: titled rows, and "- " bullets.
      expect(lower, contains('volunteering'));
      expect(text, contains('VOLDESC'));
      expect(text, contains('- AWARDONE'));
    },
  );
}
