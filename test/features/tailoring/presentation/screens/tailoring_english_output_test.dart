import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

const _banglaJobPost =
    'বিকাশ লিমিটেড, ঢাকা — Frontend Developer নিয়োগ। প্রয়োজনীয় যোগ্যতা: '
    'React, TypeScript ও REST API-তে ২+ বছরের অভিজ্ঞতা, Git ও CI/CD। '
    'দায়িত্ব: নতুন ফিচার তৈরি, বাগ ঠিক করা এবং কোড রিভিউ।';

void main() {
  testWidgets('a Bangla job post is sent as is, the CV is tailored in '
      'English, and the result says so', (tester) async {
    final app = await pumpCoreFlow(
      tester,
      repository: FakeCvRepository([designCv()]),
      surface: const Size(390, 1700),
    );
    unawaited(app.router.push(RouteNames.tailoringPath));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tailorAnyLanguage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, _banglaJobPost);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tailorAnalyze));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tailorTailorMyCv));
    await tester.pumpAndSettle();

    expect(app.ai.tailorCalls, 1);
    expect(app.ai.lastTailorJobPost, _banglaJobPost);
    expect(app.ai.lastTailorLanguage, AiOutputLanguage.english);
    expect(find.text(AppStrings.tailorEnglishOutputNote), findsOneWidget);
  });
}
