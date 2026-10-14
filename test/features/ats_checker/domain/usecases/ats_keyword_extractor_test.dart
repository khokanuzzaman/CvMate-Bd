import 'package:careermatebd/features/ats_checker/domain/usecases/ats_keyword_matcher.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = AtsRuleEngine();

/// The nurse job post and CV from the QA report (build/qa: Tailor step 2).
const _nurseJobPost =
    'Registered Nurse (ICU) — Square Hospital, Dhaka. We are looking for a '
    'compassionate Registered Nurse to provide patient care in our intensive '
    'care unit. Responsibilities: monitor vital signs, administer medication '
    'and IV therapy, perform wound dressing, follow infection control '
    'protocols, maintain accurate patient records and support doctors during '
    'emergencies. Requirements: BSc in Nursing, BNMC registration, 2+ years of '
    'hospital experience, BLS and ACLS certification, strong teamwork and '
    'communication skills.';

CvProfile _nurseCv() => CvProfile.empty().copyWith(
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
    EducationInfo.empty(
      id: 'ed1',
    ).copyWith(degree: 'BSc in Nursing', institution: 'Dhaka Nursing College'),
  ],
  experiences: [
    ExperienceInfo.empty(id: 'ex1').copyWith(
      jobTitle: 'Staff Nurse',
      companyName: 'City General Hospital',
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
);

void main() {
  test(
    'nurse post: a sensible match, no place or employer names as skills',
    () {
      final report = _engine.analyzeJobPost(
        profile: _nurseCv(),
        jobPostText: _nurseJobPost,
      );

      final extracted = report.extractedKeywords.map((k) => k.toLowerCase());
      expect(
        extracted,
        containsAll([
          'registered nurse',
          'vital signs',
          'iv therapy',
          'wound dressing',
          'infection control',
        ]),
      );
      for (final keyword in [...extracted, ...report.missingKeywords]) {
        final lower = keyword.toLowerCase();
        expect(lower, isNot(contains('square')), reason: keyword);
        expect(lower, isNot(contains('dhaka')), reason: keyword);
        expect(lower, isNot(contains('hospital')), reason: keyword);
      }

      // The QA report had this at 0 %: "Provide Patient Care" never matched.
      expect(report.matchPercentage, greaterThanOrEqualTo(60));
      expect(
        report.matchedKeywords.map((k) => k.toLowerCase()),
        containsAll(['registered nurse', 'vital signs', 'infection control']),
      );
    },
  );

  test('a tech post still yields the stack it names', () {
    final keywords = _engine
        .extractJobKeywords('''
We are hiring a Flutter Developer.
Required skills: Flutter, Dart, Firebase, REST API, GitHub, Riverpod, and communication.
Candidates should be comfortable building mobile products with cross-functional teams.
''')
        .map((k) => k.toLowerCase());

    expect(
      keywords,
      containsAll([
        'flutter',
        'dart',
        'firebase',
        'rest api',
        'github',
        'riverpod',
        'communication',
      ]),
    );
  });

  test('a finance post drops employer, place, date, pay and contact text', () {
    final keywords = _engine
        .extractJobKeywords('''
Senior Accountant — BRAC Bank Ltd, Gulshan, Dhaka
Salary: BDT 60,000 - 80,000 per month. Deadline: 15 March 2026.
Responsibilities:
• Prepare monthly financial statements and bank reconciliations
• Manage accounts payable and accounts receivable
Requirements: CA or ACCA qualified, 3+ years of experience, proficiency in Excel and Tally, knowledge of IFRS.
Send your CV to hr@brac.net or call +880 1712 345678.
''')
        .map((k) => k.toLowerCase())
        .toList();

    expect(keywords, containsAll(['excel', 'tally', 'ifrs']));
    final all = keywords.join(' | ');
    for (final noise in [
      'brac',
      'dhaka',
      'gulshan',
      'march',
      '2026',
      'bdt',
      '60',
      'deadline',
      'salary',
      'hr@',
      '880',
    ]) {
      expect(all, isNot(contains(noise)), reason: noise);
    }
  });

  test(
    'keywords match plural, tense, hyphen, word-order and alias variants',
    () {
      final matcher = AtsKeywordMatcher([
        'Monitored vital sign changes on the ward',
        'Worked in the intensive care unit',
        'Full stack developer',
        'Provided care of patients',
        'ICU rotation',
        'Registered staff nurse',
      ]);

      expect(matcher.matches('Vital Signs'), isTrue);
      expect(matcher.matches('ICU'), isTrue); // "intensive care unit"
      expect(matcher.matches('Intensive Care Unit'), isTrue); // "ICU"
      expect(matcher.matches('Full-Stack'), isTrue);
      expect(matcher.matches('Patient Care'), isTrue);
      expect(matcher.matches('Registered Nurse'), isTrue);

      // Near-misses stay missing.
      expect(matcher.matches('Teamwork'), isFalse); // not "team"
      expect(matcher.matches('Wound Dressing'), isFalse);
      expect(AtsKeywordMatcher(['Nurse']).matches('Registered Nurse'), isFalse);
    },
  );
}
