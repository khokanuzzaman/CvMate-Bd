import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

void main() {
  testWidgets('turning the declaration on, choosing Bangla and a place '
      'saves them on the CV', (tester) async {
    final repository = FakeCvRepository([
      CvProfile.empty().copyWith(id: 'cv-1', title: 'CV'),
    ]);
    await pumpBuilderApp(
      tester,
      repository: repository,
      initialLocation: RouteNames.cvDeclarationPath,
      loadDraftId: 'cv-1',
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.declarationBangla));
    await tester.pumpAndSettle();
    expect(find.text(CvDeclaration.defaultBangla), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.declarationPlaceHint),
      'Dhaka',
    );
    await tester.tap(find.text(AppStrings.declarationSave));
    await tester.pumpAndSettle();

    final saved = repository.saved('cv-1')!;
    expect(saved.showDeclaration, isTrue);
    expect(saved.declaration.language, DeclarationLanguage.bangla);
    expect(saved.declaration.effectiveText, CvDeclaration.defaultBangla);
    expect(saved.declaration.place, 'Dhaka');
  });

  testWidgets('with no CV open it says so instead of showing the form', (
    tester,
  ) async {
    await pumpBuilderApp(
      tester,
      repository: FakeCvRepository(),
      initialLocation: RouteNames.cvDeclarationPath,
    );

    expect(find.text(AppStrings.builderNoDraftTitle), findsOneWidget);
    expect(find.text(AppStrings.declarationSave), findsNothing);
  });
}
