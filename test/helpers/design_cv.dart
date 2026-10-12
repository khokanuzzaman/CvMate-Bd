import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';

/// A CV shaped like the design mocks. [blankPersonal] leaves the personal form
/// empty (as in the Personal design); otherwise every section is filled so the
/// Summary page shows its "all done" banner.
CvProfile designCv({
  bool blankPersonal = false,
  bool withTraining = true,
  bool withLanguages = true,
  String id = 'cv-frontend',
  String title = 'Frontend Developer CV',
  CvTemplate template = CvTemplate.modern,
  DateTime? updatedAt,
}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: title,
    template: template,
    updatedAt: updatedAt ?? DateTime.now().subtract(const Duration(days: 2)),
    personalInfo: blankPersonal
        ? const PersonalInfo()
        : const PersonalInfo(
            fullName: 'Ayesha Rahman',
            desiredRole: 'Frontend Developer',
            email: 'ayesha@email.com',
            phone: '01712345678',
            address: 'Dhaka, BD',
            linkedInUrl: 'https://linkedin.com/in/ayesha',
          ),
    professionalSummary:
        'Front-end developer building accessible, performant React '
        'interfaces. Comfortable owning features end to end and working in '
        'Agile teams.',
    education: [
      EducationInfo.empty(id: 'ed1').copyWith(
        degree: 'BSc in Computer Science',
        institution: blankPersonal ? '' : 'Dhaka University',
        startYear: '2018',
        endYear: '2022',
      ),
    ],
    experiences: [
      ExperienceInfo.empty(id: 'ex1').copyWith(
        jobTitle: 'Frontend Developer',
        companyName: 'Acme Ltd.',
        startDate: '2022',
        isCurrentRole: true,
        highlights: const [
          'Built responsive React interfaces used by thousands of users.',
          'Collaborated with designers to ship new features each sprint.',
        ],
      ),
      ExperienceInfo.empty(id: 'ex2').copyWith(
        jobTitle: 'Junior Developer',
        companyName: 'Beta Soft',
        startDate: '2020',
        endDate: '2022',
        highlights: const ['Maintained the web app and fixed bugs.'],
      ),
    ],
    skills: [
      for (final (index, name) in [
        'React',
        'JavaScript',
        'Git',
        'TypeScript',
      ].indexed)
        SkillInfo.empty(id: 's$index').copyWith(name: name),
    ],
    projects: [
      ProjectInfo.empty(id: 'p1').copyWith(
        title: 'Expense Tracker App',
        technologies: const ['React', 'Firebase'],
        description:
            '• Personal finance app with charts and budgets.\n'
            '• Built the full React front end and Firebase backend.',
      ),
    ],
    trainings: withTraining
        ? [
            TrainingInfo.empty(id: 't1').copyWith(
              title: 'Flutter bootcamp',
              organization: 'Code Academy',
              completionYear: '2024',
            ),
          ]
        : const [],
    languages: withLanguages
        ? [
            LanguageInfo.empty(
              id: 'l1',
            ).copyWith(name: 'Bangla', proficiency: 'Native'),
            LanguageInfo.empty(
              id: 'l2',
            ).copyWith(name: 'English', proficiency: 'Fluent'),
          ]
        : const [],
  );
}
