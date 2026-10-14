import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/printing_mock.dart';
import '../support/qa_harness.dart';

void registerMarketStyleFlow() {
  qaTest(
    'market style: create CV → choose Gulf → personal details → preview → export',
    (tester) async {
      final shares = mockSharePlugin(tester);
      await launchSignedIn(tester);

      // Creating a CV starts on the CV style screen.
      await tapText(tester, AppStrings.homeNewCv);
      await waitFor(tester, find.text(AppStrings.styleTitle));
      await shot(tester, 'market-style', 'style-default');
      await tapText(tester, AppStrings.styleGulf);
      await shot(tester, 'market-style', 'style-gulf-selected');
      await tapOn(
        tester,
        find.widgetWithText(
          PrimaryButton,
          AppStrings.styleUse(AppStrings.styleShortGulf),
        ),
      );
      await waitFor(tester, find.text('Step 1 of 7 · Personal'));
      expect(find.text('${AppStrings.styleShortGulf} style'), findsOneWidget);

      // Personal details: Gulf turns the photo and passport fields on.
      await typeInto(
        tester,
        fieldByHint(AppStrings.builderFullNameHint),
        'Rakibul Islam',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.builderHeadlineHint),
        'Site Engineer',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.builderPhoneHint),
        '01712345678',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.builderLocationHint),
        'Dubai',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.builderEmailHint),
        'rakib@email.com',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.personalNationalityHint),
        'Bangladeshi',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.personalPassportNumberHint),
        'A01234567',
      );
      await typeInto(
        tester,
        fieldByHint(AppStrings.personalPassportExpiryHint),
        '2031',
      );
      await scrollIntoReach(tester, find.text(AppStrings.personalPrivacyNote));
      await shot(tester, 'market-style', 'personal-details-gulf');

      // Declaration & signature screen (turn the declaration on, then back).
      await tapText(tester, AppStrings.declarationTile);
      await waitFor(tester, find.text(AppStrings.declarationAdd));
      await tapOn(tester, find.byType(Switch).first);
      await typeInto(
        tester,
        fieldByHint(AppStrings.declarationPlaceHint),
        'Dubai',
      );
      await shot(tester, 'market-style', 'declaration');
      await tapText(tester, AppStrings.declarationSave);
      await waitFor(tester, find.text(AppStrings.declarationTile));

      // Preview shows the shown fields.
      await tapOn(tester, find.byIcon(Icons.visibility_outlined));
      await waitFor(tester, find.text(AppStrings.previewExport));
      await shot(tester, 'market-style', 'preview-gulf');
      expect(find.textContaining('Nationality: Bangladeshi'), findsOneWidget);
      expect(find.textContaining('Passport: A01234567 · 2031'), findsOneWidget);
      expect(find.textContaining('Place: Dubai'), findsOneWidget);

      // Export reaches the share sheet.
      await tapText(
        tester,
        AppStrings.previewExport,
        settle: const Duration(seconds: 3),
      );
      expect(shares, isNotEmpty);
      final doc = shares.first.arguments['doc'];
      if (doc is List<int>) {
        await saveHostFile('market-style/export-gulf.pdf', doc);
      }

      // Saved with the CV.
      final saved = await appContainer(
        tester,
      ).read(cvRepositoryImplProvider).getAllCvs();
      final cv = saved.first;
      expect(cv.style, CvStyle.gulf);
      expect(cv.details.passportNumber, 'A01234567');
      expect(cv.isFieldShown(PersonalField.passport), isTrue);
    },
  );
}
