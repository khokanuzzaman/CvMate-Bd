import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

Finder _chip(String label) => find.widgetWithText(AppChip, label);

Future<void> _addApplication(
  WidgetTester tester, {
  required String company,
  required String title,
  required String source,
  required String status,
  String notes = '',
}) async {
  await typeInto(
    tester,
    fieldByHint('Bdjobs, BRAC Bank, Unilever Bangladesh'),
    company,
  );
  await typeInto(
    tester,
    fieldByHint('Management Trainee, Flutter Developer'),
    title,
  );
  await tapOn(tester, _chip(source));
  await tapOn(tester, _chip(status));
  if (notes.isNotEmpty) {
    await typeInto(tester, find.byType(TextField).last, notes);
  }
}

void registerTrackerFlow() {
  qaTest('tracker: empty → add → edit → status → filter → search → delete', (
    tester,
  ) async {
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());
    await tapText(tester, 'Tracker');
    await waitFor(tester, find.text(AppStrings.trackerEmptyTitle));
    await shot(tester, 'tracker', 'empty');

    await tapText(tester, AppStrings.trackerAdd);
    await waitFor(tester, find.text('Save application'));
    await shot(tester, 'tracker', 'form-empty');

    // Validation.
    await tapText(tester, 'Save application');
    expect(find.text('Company name is required.'), findsWidgets);
    await shot(tester, 'tracker', 'form-validation');

    await _addApplication(
      tester,
      company: 'Square Hospital',
      title: 'Registered Nurse',
      source: 'LinkedIn',
      status: 'Applied',
      notes: 'Call HR on Monday.',
    );
    await shot(tester, 'tracker', 'form-filled');
    await tapText(
      tester,
      'Save application',
      settle: const Duration(seconds: 1),
    );
    await waitFor(tester, find.text('Square Hospital · via LinkedIn'));
    await shot(tester, 'tracker', 'one-application');

    // Two more.
    for (final (company, title, source, status) in [
      ('Evercare Hospital', 'Staff Nurse', 'Bdjobs', 'Interview'),
      ('Labaid Hospital', 'ICU Nurse', 'Email', 'Rejected'),
    ]) {
      await tapOn(tester, find.byTooltip(AppStrings.trackerAdd));
      await waitFor(tester, find.text('Save application'));
      await _addApplication(
        tester,
        company: company,
        title: title,
        source: source,
        status: status,
      );
      await tapText(
        tester,
        'Save application',
        settle: const Duration(seconds: 1),
      );
      await waitFor(tester, find.text('$company · via $source'));
    }
    await shot(tester, 'tracker', 'three-applications');

    // Details → status chip → edit.
    await tapText(tester, 'Registered Nurse');
    await waitFor(tester, find.text('Application details'));
    await shot(tester, 'tracker', 'details');
    await tapOn(tester, _chip('Interview'));
    await waitFor(tester, find.text('Status updated to Interview.'));
    await shot(tester, 'tracker', 'details-status-updated');
    await pumpFor(tester, const Duration(seconds: 4));
    await tapText(tester, 'Edit');
    await waitFor(tester, find.text('Edit application'));
    await shot(tester, 'tracker', 'form-edit');
    await typeInto(
      tester,
      fieldByHint('Management Trainee, Flutter Developer'),
      'Senior Registered Nurse',
    );
    await tapText(
      tester,
      'Save application',
      settle: const Duration(seconds: 1),
    );
    await shot(tester, 'tracker', 'after-save-tap-edit');
    await waitFor(tester, find.text('Application details'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await waitFor(tester, find.text('Senior Registered Nurse'));
    await shot(tester, 'tracker', 'details-after-edit');
    await goBack(tester);
    await waitFor(tester, find.text('Senior Registered Nurse'));

    // Filter by status, then search.
    await tapOn(tester, _chip('Interview'));
    await shot(tester, 'tracker', 'filter-interview');
    expect(find.text('Labaid Hospital · via Email'), findsNothing);
    await tapOn(tester, _chip('Rejected'));
    await shot(tester, 'tracker', 'filter-rejected');
    await tapOn(tester, _chip(AppStrings.trackerFilterAll));

    await tapOn(tester, find.byTooltip(AppStrings.trackerSearch));
    await typeInto(
      tester,
      find.byKey(const ValueKey('tracker-search')),
      'ever',
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Evercare Hospital · via Bdjobs'), findsOneWidget);
    expect(find.text('Labaid Hospital · via Email'), findsNothing);
    await shot(tester, 'tracker', 'search-ever');
    await typeInto(
      tester,
      find.byKey(const ValueKey('tracker-search')),
      'zzzz',
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    await waitFor(tester, find.text(AppStrings.trackerNoMatchTitle));
    await shot(tester, 'tracker', 'search-no-match');
    await tapText(tester, AppStrings.trackerClearFilters);
    await shot(tester, 'tracker', 'filters-cleared');

    // Delete asks first.
    await tapText(tester, 'ICU Nurse');
    await waitFor(tester, find.text('Application details'));
    await tapText(tester, 'Delete application');
    await waitFor(tester, find.text('Delete application').last);
    await shot(tester, 'tracker', 'delete-dialog');
    await tapText(tester, 'Cancel');
    expect(find.text('Application details'), findsOneWidget);
    await tapText(tester, 'Delete application');
    await tapOn(tester, find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(tester, find.text(AppStrings.trackerTitle));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Labaid Hospital · via Email'), findsNothing);
    await shot(tester, 'tracker', 'after-delete');
  });
}
