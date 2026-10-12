import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the headline follows the match bands', () {
    expect(matchHeadline(100), AppStrings.tailorMatchStrong);
    expect(matchHeadline(kStrongMatchPercent), AppStrings.tailorMatchStrong);
    expect(matchHeadline(kStrongMatchPercent - 1), AppStrings.tailorMatchGood);
    expect(matchHeadline(kGoodMatchPercent), AppStrings.tailorMatchGood);
    expect(matchHeadline(kGoodMatchPercent - 1), AppStrings.tailorMatchLow);
    expect(matchHeadline(0), AppStrings.tailorMatchLow);
  });

  test('the body only promises a jump when keywords are missing', () {
    expect(
      matchBody(hasMissingKeywords: true),
      AppStrings.tailorMatchBodyMissing,
    );
    expect(
      matchBody(hasMissingKeywords: false),
      AppStrings.tailorMatchBodyCovered,
    );
  });

  test('isNewSkill compares against the CV, ignoring case and spacing', () {
    final cv = CvProfile.empty().copyWith(
      skills: const [SkillInfo(id: 's1', name: 'React', level: '')],
    );

    expect(isNewSkill(cv, 'react '), isFalse);
    expect(isNewSkill(cv, 'Next.js'), isTrue);
    expect(isNewSkill(null, 'Next.js'), isFalse);
  });
}
