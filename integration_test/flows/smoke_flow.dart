import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_harness.dart';

void registerSmokeFlow() {
  qaTest('smoke: app boots to onboarding on a fresh install', (tester) async {
    await launchApp(tester);
    await shot(tester, 'smoke', 'splash');
    await waitFor(tester, find.text(AppStrings.onboardingGetStarted));
    await shot(tester, 'smoke', 'onboarding');
  });
}
