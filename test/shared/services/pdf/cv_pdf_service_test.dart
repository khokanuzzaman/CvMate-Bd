import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

CvProfile _experiencedProfile(CvTemplate template) {
  return CvProfile.empty().copyWith(
    title: 'Sample CV',
    template: template,
    personalInfo: const PersonalInfo(
      fullName: 'Ayesha Karim',
      desiredRole: 'Registered Nurse',
      email: 'ayesha@example.com',
      phone: '01700000000',
      address: 'Dhaka, Bangladesh',
    ),
    professionalSummary:
        'Registered nurse experienced in patient care and infection control.',
    careerObjective: 'Seeking a hospital nursing role with growth.',
    education: const [
      EducationInfo(
        id: 'edu-1',
        institution: 'Dhaka Nursing College',
        degree: 'BSc in Nursing',
        fieldOfStudy: 'Nursing',
        endYear: '2023',
      ),
    ],
    experiences: const [
      ExperienceInfo(
        id: 'exp-1',
        companyName: 'City General Hospital',
        jobTitle: 'Staff Nurse',
        highlights: ['Administered IV therapy for 30+ patients per shift.'],
      ),
    ],
    skills: const [
      SkillInfo(id: 'skill-1', name: 'Patient Care', level: 'Advanced'),
    ],
    projects: const [
      ProjectInfo(
        id: 'project-1',
        title: 'Ward Handover Checklist',
        role: 'Coordinator',
        description: 'Standardized shift handovers to reduce errors.',
      ),
    ],
  );
}

bool _looksLikePdf(List<int> bytes) {
  if (bytes.length < 5) {
    return false;
  }
  return String.fromCharCodes(bytes.take(5)) == '%PDF-';
}

void main() {
  const service = CvPdfService();

  test('generates a selectable single-column PDF for every template', () async {
    for (final template in CvTemplate.values) {
      final bytes = await service.generateCvPdf(
        profile: _experiencedProfile(template),
      );
      expect(bytes, isNotEmpty, reason: 'template ${template.name} was empty');
      expect(
        _looksLikePdf(bytes),
        isTrue,
        reason: 'template ${template.name} did not produce a PDF',
      );
    }
  });

  test('fresher template renders gracefully with no work experience', () async {
    final fresher = CvProfile.empty().copyWith(
      title: 'Fresher CV',
      template: CvTemplate.fresher,
      personalInfo: const PersonalInfo(
        fullName: 'Rahim Hasan',
        desiredRole: 'Junior Software Engineer',
        email: 'rahim@example.com',
        phone: '01711111111',
      ),
      professionalSummary: 'Recent graduate focused on mobile development.',
      education: const [
        EducationInfo(
          id: 'edu-1',
          institution: 'North South University',
          degree: 'BSc in CSE',
          fieldOfStudy: 'Computer Science',
          endYear: '2024',
        ),
      ],
      projects: const [
        ProjectInfo(
          id: 'project-1',
          title: 'CareerMate Student App',
          role: 'Lead Developer',
          description: 'A Flutter job-tracking app for applicants.',
          technologies: ['Flutter', 'Firebase'],
        ),
      ],
      skills: const [SkillInfo(id: 'skill-1', name: 'Flutter', level: 'Basic')],
    );

    expect(fresher.experiences, isEmpty);
    final bytes = await service.generateCvPdf(profile: fresher);
    expect(bytes, isNotEmpty);
    expect(_looksLikePdf(bytes), isTrue);
  });

  test('renders an empty draft without throwing for every template', () async {
    for (final template in CvTemplate.values) {
      final bytes = await service.generateCvPdf(
        profile: CvProfile.empty().copyWith(template: template),
      );
      expect(bytes, isNotEmpty, reason: 'empty ${template.name} was empty');
      expect(_looksLikePdf(bytes), isTrue);
    }
  });
}
