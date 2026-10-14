import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = AtsRuleEngine();

  test(
    'analyzeCv returns a low score when core ATS-friendly sections are missing',
    () {
      final profile = CvProfile.empty().copyWith(
        title: 'Draft CV',
        personalInfo: const PersonalInfo(
          fullName: 'Rahim Hasan',
          desiredRole: 'Flutter Developer',
        ),
      );

      final report = engine.analyzeCv(profile);

      expect(report.score, lessThan(25));
      expect(
        report.issues.where(
          (issue) => issue.severity == AtsSuggestionSeverity.high,
        ),
        isNotEmpty,
      );
      expect(
        report.issues.map((issue) => issue.problem),
        containsAll([
          'Phone number is missing.',
          'Email address is missing.',
          'Professional summary is missing.',
          'Skills section is missing.',
        ]),
      );
    },
  );

  test(
    'analyzeJobPost extracts keywords and only suggests skills backed by CV evidence',
    () {
      final profile = CvProfile.empty().copyWith(
        title: 'Mobile Engineer CV',
        personalInfo: const PersonalInfo(
          fullName: 'Nusrat Jahan',
          desiredRole: 'Flutter Developer',
          email: 'nusrat@example.com',
          phone: '01700000000',
          linkedInUrl: 'https://www.linkedin.com/in/nusrat-jahan',
        ),
        professionalSummary:
            'Flutter developer with hands-on experience building responsive mobile apps using Dart, Firebase, REST API integration, GitHub collaboration, and clear communication with product teams.',
        careerObjective:
            'Seeking a junior Flutter role where I can contribute to real mobile products and continue improving through practical team work.',
        education: const [
          EducationInfo(
            id: 'edu-1',
            institution: 'North South University',
            degree: 'BSc',
            fieldOfStudy: 'Computer Science',
            endYear: '2025',
          ),
        ],
        experiences: const [
          ExperienceInfo(
            id: 'exp-1',
            companyName: 'Tech Studio BD',
            jobTitle: 'Flutter Intern',
            highlights: [
              'Developed a Flutter app with Firebase authentication and REST API integration for 500+ active users.',
              'Coordinated testing feedback with product teams and resolved release issues before deployment.',
            ],
          ),
        ],
        skills: const [
          SkillInfo(id: 'skill-1', name: 'Flutter', level: 'Advanced'),
          SkillInfo(id: 'skill-2', name: 'Dart', level: 'Advanced'),
        ],
        projects: const [
          ProjectInfo(
            id: 'project-1',
            title: 'CareerMate Student App',
            role: 'Lead Developer',
            description:
                'Built a job-tracking app for Bangladeshi applicants with Firebase workflows and GitHub-based collaboration.',
            technologies: ['Flutter', 'Firebase', 'GitHub'],
          ),
        ],
      );

      const jobPost = '''
We are hiring a Flutter Developer.
Required skills: Flutter, Dart, Firebase, REST API, GitHub, Riverpod, and communication.
Candidates should be comfortable building mobile products with cross-functional teams.
''';

      final report = engine.analyzeJobPost(
        profile: profile,
        jobPostText: jobPost,
      );

      final matchedKeywords = report.matchedKeywords
          .map((keyword) => keyword.toLowerCase())
          .toSet();
      final missingKeywords = report.missingKeywords
          .map((keyword) => keyword.toLowerCase())
          .toSet();
      final suggestedSkills = report.suggestedSkillsToAdd
          .map((keyword) => keyword.toLowerCase())
          .toSet();

      expect(report.matchPercentage, greaterThan(70));
      expect(
        matchedKeywords,
        containsAll(['flutter', 'dart', 'firebase', 'rest api', 'github']),
      );
      expect(missingKeywords, contains('riverpod'));
      expect(
        suggestedSkills,
        containsAll(['firebase', 'rest api', 'github', 'communication']),
      );
      expect(suggestedSkills, isNot(contains('flutter')));
      expect(suggestedSkills, isNot(contains('dart')));
      expect(
        report.suggestedSectionsToImprove,
        containsAll([
          'Professional Summary',
          'Skills',
          'Experience',
          'Projects',
        ]),
      );
    },
  );

  test(
    'analyzeJobPost normalizes keyword aliases and calculates match percentage',
    () {
      final profile = CvProfile.empty().copyWith(
        title: 'Frontend CV',
        personalInfo: const PersonalInfo(
          fullName: 'Arif Chowdhury',
          desiredRole: 'Frontend Developer',
          email: 'arif@example.com',
          phone: '01711111111',
        ),
        professionalSummary:
            'Frontend developer with practical problem solving and product collaboration experience.',
        skills: const [
          SkillInfo(id: 'skill-1', name: 'React', level: 'Advanced'),
        ],
        projects: const [
          ProjectInfo(
            id: 'project-1',
            title: 'Travel Planner',
            role: 'Mobile UI Developer',
            description:
                'Built an iOS-friendly mobile interface for a travel planning product.',
            technologies: ['React'],
          ),
        ],
      );

      const jobPost = '''
We need React, Node JS, iOS, and problem solving.
''';

      final report = engine.analyzeJobPost(
        profile: profile,
        jobPostText: jobPost,
      );

      expect(
        report.extractedKeywords,
        containsAll(['React', 'Node.js', 'iOS', 'Problem Solving']),
      );
      expect(
        report.matchPercentage,
        ((report.matchedKeywords.length / report.extractedKeywords.length) *
                100)
            .round(),
      );
      expect(report.matchPercentage, greaterThan(50));
      expect(report.matchPercentage, lessThan(100));
      expect(report.missingKeywords, contains('Node.js'));
    },
  );

  test(
    'extractJobKeywords pulls salient keywords from any job post without a fixed skill list',
    () {
      const jobPost = '''
Registered Nurse needed for a hospital ward.
Required skills: patient care, medication administration, IV therapy, vital signs monitoring, infection control, and teamwork.
''';

      final keywords = engine
          .extractJobKeywords(jobPost)
          .map((keyword) => keyword.toLowerCase())
          .toSet();

      // Comma-listed requirements are treated as the salient keywords.
      expect(
        keywords,
        containsAll([
          'patient care',
          'medication administration',
          'iv therapy',
          'vital signs monitoring',
          'infection control',
          'teamwork',
        ]),
      );
      // No developer-biased leakage from a hardcoded list.
      expect(keywords, isNot(contains('flutter')));
      expect(keywords, isNot(contains('dart')));
      expect(keywords.length, lessThanOrEqualTo(8));
    },
  );

  test(
    'analyzeJobPost produces sensible matching for a non-tech (nurse) CV',
    () {
      final profile = CvProfile.empty().copyWith(
        title: 'Nursing CV',
        personalInfo: const PersonalInfo(
          fullName: 'Ayesha Karim',
          desiredRole: 'Registered Nurse',
          email: 'ayesha@example.com',
          phone: '01722222222',
        ),
        professionalSummary:
            'Compassionate registered nurse experienced in patient care, medication administration, and infection control across busy hospital wards.',
        careerObjective:
            'Seeking a hospital nursing role where I can deliver safe, patient-centred care and continue building clinical skills.',
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
            highlights: [
              'Administered IV therapy and monitored patients for 30+ admissions per shift.',
              'Coordinated infection control procedures with the ward team and doctors.',
            ],
          ),
        ],
        skills: const [
          SkillInfo(id: 'skill-1', name: 'Patient Care', level: 'Advanced'),
          SkillInfo(
            id: 'skill-2',
            name: 'Medication Administration',
            level: 'Advanced',
          ),
        ],
      );

      const jobPost = '''
Registered Nurse needed for a hospital ward.
Required skills: patient care, medication administration, IV therapy, vital signs monitoring, infection control, and teamwork.
''';

      final report = engine.analyzeJobPost(
        profile: profile,
        jobPostText: jobPost,
      );

      final matched = report.matchedKeywords
          .map((keyword) => keyword.toLowerCase())
          .toSet();
      final missing = report.missingKeywords
          .map((keyword) => keyword.toLowerCase())
          .toSet();
      final suggested = report.suggestedSkillsToAdd
          .map((keyword) => keyword.toLowerCase())
          .toSet();

      expect(report.matchPercentage, greaterThan(40));
      expect(
        matched,
        containsAll([
          'patient care',
          'medication administration',
          'iv therapy',
          'infection control',
        ]),
      );
      // 'vital signs monitoring' and 'teamwork' are not in the CV wording.
      expect(missing, contains('teamwork'));
      // Skills backed by CV evidence but missing from the skills section.
      expect(suggested, containsAll(['iv therapy', 'infection control']));
      // Skills already listed in the skills section are not re-suggested.
      expect(suggested, isNot(contains('patient care')));
      expect(suggested, isNot(contains('medication administration')));
    },
  );
}
