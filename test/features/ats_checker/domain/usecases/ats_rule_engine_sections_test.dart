import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a hidden section is not scored as missing', () {
    final bare = CvProfile.empty().copyWith(
      title: 'Bare CV',
      personalInfo: const PersonalInfo(
        fullName: 'Rahim Hasan',
        desiredRole: 'Nurse',
        email: 'rahim@email.com',
        phone: '01711111111',
      ),
    );
    Set<String> problems(CvProfile cv) => {
      for (final issue in const AtsRuleEngine().analyzeCv(cv).issues)
        issue.problem,
    };

    expect(problems(bare), contains('Skills section is missing.'));
    expect(problems(bare), contains('Education section is missing.'));

    final hidden = problems(
      bare.copyWith(
        sectionLayout: [
          SectionConfig.builtIn(CvSectionKind.skills, visible: false),
          SectionConfig.builtIn(CvSectionKind.education, visible: false),
        ],
      ),
    );
    expect(hidden, isNot(contains('Skills section is missing.')));
    expect(hidden, isNot(contains('Education section is missing.')));
  });
}
