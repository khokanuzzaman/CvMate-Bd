import 'package:careermatebd/app/constants/app_links.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/shared/services/links/url_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_screen_harness.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late List<Uri> opened;
  late bool openWorks;

  setUp(() {
    repository = FakeAuthRepository();
    opened = [];
    openWorks = true;
  });
  tearDown(() => repository.dispose());

  Future<void> pumpRegister(WidgetTester tester) => pumpAuthScreen(
    tester,
    repository: repository,
    initialLocation: '/register',
    overrides: [
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return openWorks;
      }),
    ],
  );

  testWidgets('the name typed at sign-up is saved on the account', (
    tester,
  ) async {
    await pumpRegister(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Rahim Uddin ');
    await tester.enterText(fields.at(1), 'rahim@example.com');
    await tester.enterText(fields.at(2), 'Rahim123');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(
      find.widgetWithText(PrimaryButton, AppStrings.createAccount),
    );
    await tester.pumpAndSettle();

    expect(repository.createdDisplayNames, ['  Rahim Uddin ']);
    expect(find.text(homePlaceholder), findsOneWidget);
  });

  testWidgets('Terms and Privacy Policy open the published pages without '
      'ticking the box; if a page cannot open, the in-app text shows', (
    tester,
  ) async {
    await pumpRegister(tester);

    await tester.tap(find.text(AppStrings.registerTerms));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.registerPrivacy));
    await tester.pumpAndSettle();

    expect(opened, [
      Uri.parse(AppLinks.termsOfUse),
      Uri.parse(AppLinks.privacyPolicy),
    ]);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    openWorks = false;
    await tester.tap(find.text(AppStrings.registerTerms));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profilePrivacyTerms), findsOneWidget);
  });
}
