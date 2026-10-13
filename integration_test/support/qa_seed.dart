import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_harness.dart';

/// A complete non-tech CV (staff nurse) so the tailoring checks are not
/// developer-shaped.
CvProfile nurseCv({String id = 'qa-nurse', String title = 'Staff Nurse CV'}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: title,
    template: CvTemplate.classic,
    updatedAt: DateTime.now(),
    personalInfo: const PersonalInfo(
      fullName: 'Nusrat Jahan',
      desiredRole: 'Staff Nurse',
      email: 'nusrat@email.com',
      phone: '01812345678',
      address: 'Dhaka, BD',
    ),
    professionalSummary:
        'Registered staff nurse with 3 years of ward experience in patient '
        'care, medication administration and infection control.',
    education: [
      EducationInfo.empty(id: 'ed1').copyWith(
        degree: 'BSc in Nursing',
        institution: 'Dhaka Nursing College',
        startYear: '2016',
        endYear: '2020',
      ),
    ],
    experiences: [
      ExperienceInfo.empty(id: 'ex1').copyWith(
        jobTitle: 'Staff Nurse',
        companyName: 'City General Hospital',
        startDate: '2021',
        isCurrentRole: true,
        highlights: const [
          'Monitored vital signs and recorded patient charts for 30 patients per shift.',
          'Administered medication and IV therapy under physician orders.',
        ],
      ),
    ],
    skills: [
      for (final (i, name) in [
        'Patient Care',
        'Vital Signs',
        'Wound Dressing',
        'Infection Control',
      ].indexed)
        SkillInfo.empty(id: 's$i').copyWith(name: name),
    ],
    languages: [
      LanguageInfo.empty(id: 'l1').copyWith(name: 'Bangla', proficiency: 'Native'),
      LanguageInfo.empty(id: 'l2').copyWith(name: 'English', proficiency: 'Fluent'),
    ],
  );
}

const String nurseJobPost =
    'Registered Nurse (ICU) — Square Hospital, Dhaka. We are looking for a '
    'compassionate Registered Nurse to provide patient care in our intensive '
    'care unit. Responsibilities: monitor vital signs, administer medication '
    'and IV therapy, perform wound dressing, follow infection control '
    'protocols, maintain accurate patient records and support doctors during '
    'emergencies. Requirements: BSc in Nursing, BNMC registration, 2+ years of '
    'hospital experience, BLS and ACLS certification, strong teamwork and '
    'communication skills.';

/// Saves [profile] through the real repository and refreshes Home's list.
Future<void> seedCv(WidgetTester tester, CvProfile profile) async {
  final container = appContainer(tester);
  await container.read(cvRepositoryImplProvider).saveCv(profile);
  await container.read(cvLibraryControllerProvider.notifier).reload();
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// A deliberately thin CV so the ATS check reports issues across sections.
CvProfile weakCv({String id = 'qa-weak', String title = 'Fresher Draft'}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: title,
    updatedAt: DateTime.now().add(const Duration(minutes: 1)),
    personalInfo: const PersonalInfo(fullName: 'Rahim Uddin'),
    professionalSummary: 'Hardworking.',
  );
}

const String _longWord = 'Internationalization';

/// Extreme values in every field, plus Bangla, to provoke overflow and
/// clipping and to check Bangla survives to the PDF.
CvProfile stressCv({String id = 'qa-stress'}) {
  final longBullet =
      'Coordinated multidisciplinary patient care across 14 hospital wards, '
      'reducing average handover time by 35% while training 60+ junior staff '
      'in infection-control protocols and electronic charting systems. '
      '$_longWord-ready.';
  return CvProfile.empty().copyWith(
    id: id,
    title:
        'Senior Registered Nurse and Clinical Coordinator Curriculum Vitae 2026 — Extended Edition',
    template: CvTemplate.modern,
    updatedAt: DateTime.now().add(const Duration(minutes: 2)),
    personalInfo: const PersonalInfo(
      fullName:
          'Mohammad Abdullah Al Mamun Chowdhury Bin Abdur Rahman Siddique-Khan',
      desiredRole:
          'Senior Clinical Nurse Coordinator, Intensive Care and High Dependency',
      email: 'mohammad.abdullah.al.mamun.chowdhury@very-long-domain-name-example.com',
      phone: '+8801712345678',
      address:
          'House 12, Road 7, Block C, Bashundhara Residential Area, Dhaka 1229, Bangladesh',
      linkedInUrl:
          'https://www.linkedin.com/in/mohammad-abdullah-al-mamun-chowdhury-bin-abdur-rahman',
    ),
    professionalSummary: List.filled(
      6,
      'Dedicated senior nurse with extensive ICU, emergency and ward '
      'experience delivering safe, compassionate care. ',
    ).join(),
    education: [
      EducationInfo.empty(id: 'ed1').copyWith(
        degree: 'Bachelor of Science in Nursing (Honours) with Specialisation',
        institution:
            'National Institute of Advanced Nursing Education and Research, Dhaka',
        startYear: '2014',
        endYear: '2018',
      ),
    ],
    experiences: [
      for (var i = 0; i < 4; i++)
        ExperienceInfo.empty(id: 'ex$i').copyWith(
          jobTitle: 'Senior Staff Nurse and Shift Coordinator Level ${i + 1}',
          companyName:
              'Bangabandhu Sheikh Mujib Medical University Teaching Hospital',
          startDate: '${2018 + i}',
          endDate: '${2019 + i}',
          highlights: [longBullet, longBullet],
        ),
    ],
    skills: [
      for (var i = 0; i < 24; i++)
        SkillInfo.empty(id: 's$i').copyWith(
          name: i == 0
              ? 'Advanced Cardiac Life Support and Basic Life Support Certification'
              : 'Skill number ${i + 1}',
        ),
    ],
    languages: [
      LanguageInfo.empty(id: 'l1').copyWith(name: 'বাংলা', proficiency: 'Native'),
      LanguageInfo.empty(id: 'l2').copyWith(name: 'English', proficiency: 'Fluent'),
    ],
  );
}

/// A Bangla-first CV to check Bangla in the app and the exported PDF.
CvProfile banglaCv({String id = 'qa-bangla'}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: 'আমার সিভি',
    updatedAt: DateTime.now().add(const Duration(minutes: 3)),
    personalInfo: const PersonalInfo(
      fullName: 'মোঃ আবদুল্লাহ আল মামুন',
      desiredRole: 'স্টাফ নার্স',
      email: 'mamun@email.com',
      phone: '01712345678',
      address: 'ঢাকা, বাংলাদেশ',
    ),
    professionalSummary:
        'আমি একজন অভিজ্ঞ নার্স, রোগীর সেবা ও সংক্রমণ নিয়ন্ত্রণে দক্ষ। বেতন ৳ ২৫,০০০।',
    experiences: [
      ExperienceInfo.empty(id: 'ex1').copyWith(
        jobTitle: 'স্টাফ নার্স',
        companyName: 'সিটি জেনারেল হাসপাতাল',
        startDate: '2021',
        isCurrentRole: true,
        highlights: const ['প্রতি শিফটে ৩০ জন রোগীর যত্ন নিয়েছি।'],
      ),
    ],
    skills: [
      SkillInfo.empty(id: 's1').copyWith(name: 'রোগীর সেবা'),
      SkillInfo.empty(id: 's2').copyWith(name: 'Wound Dressing'),
    ],
  );
}

/// ~6,000 characters of job post.
String longJobPost() => List.filled(10, nurseJobPost).join(' ');
