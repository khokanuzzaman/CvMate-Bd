import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// A CV whose sections are all empty, so every "missing" issue can fire.
CvProfile _bare() => CvProfile.empty().copyWith(
  title: 'Bare CV',
  personalInfo: const PersonalInfo(
    fullName: 'Rahim Hasan',
    desiredRole: 'Nurse',
    email: 'rahim@email.com',
    phone: '01711111111',
    linkedInUrl: 'https://linkedin.com/in/rahim',
  ),
);

List<SectionConfig> _hidden(Iterable<CvSectionKind> kinds) => [
  for (final kind in kinds) SectionConfig.builtIn(kind, visible: false),
];

Set<String> _problems(CvProfile profile) => {
  for (final issue in const AtsRuleEngine().analyzeCv(profile).issues)
    issue.problem,
};

const _volunteering = CustomSection(
  id: 'custom-1',
  title: 'Volunteering',
  items: [
    CustomSectionItem(
      id: 'v1',
      title: 'Red Crescent',
      description: 'Taught first aid and wound dressing at community camps.',
    ),
  ],
);

void main() {
  const engine = AtsRuleEngine();

  group('a hidden section is not scored as missing', () {
    test(
      'every missing-section issue disappears when that section is hidden',
      () {
        final shown = _problems(_bare());
        expect(shown, contains('Professional summary is missing.'));
        expect(shown, contains('Career objective is missing.'));
        expect(shown, contains('Education section is missing.'));
        expect(shown, contains('Skills section is missing.'));
        expect(
          shown,
          contains('Experience and project sections are both missing.'),
        );

        final hidden = _problems(
          _bare().copyWith(
            sectionLayout: _hidden([
              CvSectionKind.summary,
              CvSectionKind.objective,
              CvSectionKind.education,
              CvSectionKind.skills,
              CvSectionKind.experience,
              CvSectionKind.projects,
            ]),
          ),
        );
        expect(hidden, isNot(contains('Professional summary is missing.')));
        expect(hidden, isNot(contains('Career objective is missing.')));
        expect(hidden, isNot(contains('Education section is missing.')));
        expect(hidden, isNot(contains('Skills section is missing.')));
        expect(
          hidden,
          isNot(contains('Experience and project sections are both missing.')),
        );
      },
    );

    test('hiding experience alone still flags empty projects', () {
      final problems = _problems(
        _bare().copyWith(sectionLayout: _hidden([CvSectionKind.experience])),
      );
      expect(
        problems,
        contains('Experience and project sections are both missing.'),
      );
    });

    test('hidden sections do not count towards "too many empty sections"', () {
      const issue = 'Too many sections are still empty or underdeveloped.';
      expect(_problems(_bare()), contains(issue));

      final problems = _problems(
        _bare().copyWith(
          sectionLayout: _hidden([
            CvSectionKind.objective,
            CvSectionKind.training,
            CvSectionKind.languages,
            CvSectionKind.projects,
          ]),
        ),
      );
      expect(problems, isNot(contains(issue)));
    });

    test('a CV with no layout is scored exactly as before', () {
      final plain = engine.analyzeCv(_bare());
      final explicit = engine.analyzeCv(
        _bare().copyWith(
          sectionLayout: CvSectionLayout.defaultFor(_bare().template),
        ),
      );
      expect(explicit.score, plain.score);
      expect(
        explicit.issues.map((issue) => issue.problem).toList(),
        plain.issues.map((issue) => issue.problem).toList(),
      );
    });
  });

  group('custom sections are read', () {
    final jobPost =
        'We need a nurse with wound dressing, first aid and community outreach experience.';

    test(
      'keywords found only in a visible custom section count as matched',
      () {
        final without = engine.analyzeJobPost(
          profile: _bare(),
          jobPostText: jobPost,
        );
        final withSection = engine.analyzeJobPost(
          profile: _bare().copyWith(customSections: const [_volunteering]),
          jobPostText: jobPost,
        );

        expect(
          withSection.matchedKeywords.length,
          greaterThan(without.matchedKeywords.length),
        );
        expect(
          withSection.matchedKeywords.map((k) => k.toLowerCase()),
          anyOf(contains('wound dressing'), contains('first aid')),
        );
      },
    );

    test('a hidden custom section is ignored', () {
      final hidden = _bare().copyWith(
        customSections: const [_volunteering],
        sectionLayout: [SectionConfig.custom('custom-1', visible: false)],
      );
      final report = engine.analyzeJobPost(
        profile: hidden,
        jobPostText: jobPost,
      );
      final without = engine.analyzeJobPost(
        profile: _bare(),
        jobPostText: jobPost,
      );

      expect(report.matchedKeywords, without.matchedKeywords);
    });

    test(
      'custom text counts towards the CV word count; hidden text does not',
      () {
        final base = engine.analyzeCv(_bare()).wordCount;
        final withCustom = engine
            .analyzeCv(_bare().copyWith(customSections: const [_volunteering]))
            .wordCount;
        final hiddenCustom = engine
            .analyzeCv(
              _bare().copyWith(
                customSections: const [_volunteering],
                sectionLayout: [
                  SectionConfig.custom('custom-1', visible: false),
                ],
              ),
            )
            .wordCount;

        expect(withCustom, greaterThan(base));
        expect(hiddenCustom, base);
      },
    );

    test('text in a hidden built-in section is not evidence either', () {
      final withSummary = _bare().copyWith(
        professionalSummary: 'Experienced in wound dressing and first aid.',
      );
      final shown = engine.analyzeJobPost(
        profile: withSummary,
        jobPostText: jobPost,
      );
      final hidden = engine.analyzeJobPost(
        profile: withSummary.copyWith(
          sectionLayout: _hidden([CvSectionKind.summary]),
        ),
        jobPostText: jobPost,
      );

      expect(shown.matchedKeywords, isNotEmpty);
      expect(
        hidden.matchedKeywords.length,
        lessThan(shown.matchedKeywords.length),
      );
    });
  });

  group('AI prompts', () {
    const builder = AiPromptBuilder();

    String prompt(CvProfile profile) => builder.generateProfessionalSummary(
      profile: profile,
      language: AiOutputLanguage.english,
      tone: AiTone.professional,
    );

    test('include visible custom sections', () {
      final text = prompt(
        _bare().copyWith(customSections: const [_volunteering]),
      );
      expect(text, contains('Additional sections'));
      expect(text, contains('wound dressing'));
    });

    test('leave hidden ones out, and are unchanged for an ordinary CV', () {
      final hidden = prompt(
        _bare().copyWith(
          customSections: const [_volunteering],
          sectionLayout: [SectionConfig.custom('custom-1', visible: false)],
        ),
      );
      expect(hidden, isNot(contains('Additional sections')));
      expect(hidden, prompt(_bare()));
    });
  });
}
