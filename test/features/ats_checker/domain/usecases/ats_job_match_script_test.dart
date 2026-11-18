import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

// A real Bangla post: only "Flutter Developer" and a few tools are Latin,
// which used to give a false 100% match.
const _banglaPost =
    'বিকাশ লিমিটেড, ঢাকা — ফ্লাটার ডেভেলপার (Flutter Developer) নিয়োগ। '
    'প্রয়োজনীয় যোগ্যতা: Flutter ও Dart-এ ২+ বছরের অভিজ্ঞতা, Firebase, '
    'REST API। দায়িত্ব: ফিনটেক অ্যাপের নতুন ফিচার তৈরি, বাগ ঠিক করা, QA '
    'টিমের সাথে কাজ করা, কোড রিভিউ এবং অ্যাপের পারফরম্যান্স উন্নত করা।';

const _englishPostWithBangla =
    'We are hiring a Flutter Developer in Dhaka (ঢাকা) with Dart, Firebase '
    'and REST API experience to build fintech app features with the QA team.';

CvProfile _cv() => CvProfile.empty().copyWith(
  personalInfo: const PersonalInfo(desiredRole: 'Flutter Developer'),
  skills: const [SkillInfo(id: 's1', name: 'Flutter')],
);

void main() {
  const engine = AtsRuleEngine();

  test('a mostly Bangla job post gets no score; an English post with a few '
      'Bangla words still does', () {
    expect(AtsRuleEngine.isMostlyNonLatin(_banglaPost), isTrue);
    final bangla = engine.analyzeJobPost(
      profile: _cv(),
      jobPostText: _banglaPost,
    );
    expect(bangla.keywordMatchSupported, isFalse);
    expect(bangla.matchedKeywords, isEmpty);
    expect(bangla.issues, isEmpty);

    expect(AtsRuleEngine.isMostlyNonLatin(_englishPostWithBangla), isFalse);
    final english = engine.analyzeJobPost(
      profile: _cv(),
      jobPostText: _englishPostWithBangla,
    );
    expect(english.keywordMatchSupported, isTrue);
    expect(english.matchedKeywords, isNotEmpty);
  });

  testWidgets('the tailoring match page shows the English-only note instead '
      'of a score for a Bangla post', (tester) async {
    final app = await pumpCoreFlow(
      tester,
      repository: FakeCvRepository([designCv()]),
      surface: const Size(390, 1700),
    );
    unawaited(app.router.push(RouteNames.tailoringPath));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, _banglaPost);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tailorAnalyze));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.keywordMatchEnglishOnly), findsOneWidget);
    expect(find.byType(ScoreRing), findsNothing);
    expect(find.text(AppStrings.tailorMatched), findsNothing);
    expect(find.text(AppStrings.tailorTailorMyCv), findsOneWidget);
  });
}
