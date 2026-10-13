import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_tracker_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_filter_chips.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_stat_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_job_application_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<RoutedScreen> _open(
  WidgetTester tester, {
  FakeJobApplicationRepository? repository,
}) {
  return pumpRoutedScreen(
    tester,
    path: RouteNames.jobTrackerPath,
    screen: const JobTrackerScreen(),
    overrides: [
      jobApplicationRepositoryProvider.overrideWithValue(
        repository ?? FakeJobApplicationRepository(designApplications()),
      ),
    ],
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(AppChip, label);

void main() {
  group('summary and cards', () {
    testWidgets('shows the counts across the top', (tester) async {
      await _open(tester);

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(JobStatTiles),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(texts, [
        '3',
        AppStrings.trackerStatApplied,
        '1',
        AppStrings.trackerStatInterview,
        '1',
        AppStrings.trackerStatOffer,
        '0',
        AppStrings.trackerStatClosed,
      ]);
    });

    testWidgets('each card shows role, company and source', (tester) async {
      await _open(tester);

      expect(find.text('Frontend Developer'), findsOneWidget);
      expect(find.text('Acme Ltd. · via LinkedIn'), findsOneWidget);
      expect(find.text('Beta Soft · via Bdjobs'), findsOneWidget);
      expect(find.text('Cloud Co. · via Email'), findsOneWidget);
      expect(find.text('Interview'), findsWidgets);
      expect(find.text('Offered'), findsWidgets);
    });

    testWidgets('next-action hints come from the existing dates', (
      tester,
    ) async {
      await _open(tester);

      expect(find.textContaining('· Prep now'), findsOneWidget);
      expect(
        find.text('Applied 8 days ago · Send a follow-up'),
        findsOneWidget,
      );
      // The offer has nothing left to do.
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('a card with no title or company says so', (tester) async {
      await _open(
        tester,
        repository: FakeJobApplicationRepository([
          JobApplication.empty().copyWith(
            id: 'blank',
            status: JobApplicationStatus.offered,
          ),
        ]),
      );

      expect(find.text(AppStrings.trackerUntitledRole), findsOneWidget);
      expect(
        find.text(
          AppStrings.trackerVia(AppStrings.trackerUnknownCompany, 'Bdjobs'),
        ),
        findsOneWidget,
      );
    });
  });

  group('filters', () {
    testWidgets('a status chip shows only that status', (tester) async {
      final app = await _open(tester);

      await _tap(tester, _chip('Interview'));

      expect(find.text('Acme Ltd. · via LinkedIn'), findsOneWidget);
      expect(find.text('Beta Soft · via Bdjobs'), findsNothing);
      expect(
        app.container.read(jobTrackerStatusFilterProvider),
        JobApplicationStatus.interview,
      );
      expect(
        tester.widget<AppChip>(_chip('Interview')).variant,
        AppChipVariant.selected,
      );

      await _tap(tester, _chip(AppStrings.trackerFilterAll));
      expect(find.text('Beta Soft · via Bdjobs'), findsOneWidget);
    });

    test('the chips cover every status exactly once', () {
      expect(JobFilterChips.order.toSet(), JobApplicationStatus.values.toSet());
      expect(JobFilterChips.order.length, JobApplicationStatus.values.length);
    });

    testWidgets('a filter with no matches can be cleared', (tester) async {
      final app = await _open(tester);

      await _tap(tester, _chip('Rejected'));
      expect(find.text(AppStrings.trackerNoMatchTitle), findsOneWidget);

      await _tap(tester, find.text(AppStrings.trackerClearFilters));

      expect(app.container.read(jobTrackerStatusFilterProvider), isNull);
      expect(find.text('Beta Soft · via Bdjobs'), findsOneWidget);
    });

    testWidgets('search narrows by company or title', (tester) async {
      final app = await _open(tester);

      await _tap(tester, find.byTooltip(AppStrings.trackerSearch));
      await tester.enterText(find.byType(TextField), 'beta');
      await tester.pumpAndSettle();

      expect(find.text('Beta Soft · via Bdjobs'), findsOneWidget);
      expect(find.text('Acme Ltd. · via LinkedIn'), findsNothing);

      // Closing the search clears it.
      await _tap(tester, find.byTooltip(AppStrings.trackerSearch));
      expect(app.container.read(jobTrackerSearchQueryProvider), isEmpty);
      expect(find.text('Acme Ltd. · via LinkedIn'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('+ opens the add form', (tester) async {
      await _open(tester);

      await _tap(tester, find.byTooltip(AppStrings.trackerAdd));

      expect(
        find.text(placeholderFor(RouteNames.jobApplicationFormPath)),
        findsOneWidget,
      );
    });

    testWidgets('a card opens its details', (tester) async {
      await _open(tester);

      await _tap(tester, find.text('React Developer'));

      expect(
        find.text(uriTextFor('/job-tracker/details?id=job-applied')),
        findsOneWidget,
      );
    });

    testWidgets('the interview hint opens interview prep', (tester) async {
      await _open(tester);

      await _tap(tester, find.textContaining('· Prep now'));

      expect(
        find.text(placeholderFor(RouteNames.interviewPrepPath)),
        findsOneWidget,
      );
    });

    testWidgets('the bottom nav has Tracker selected and switches tabs', (
      tester,
    ) async {
      await _open(tester);
      expect(
        tester.widget<BottomNavBar>(find.byType(BottomNavBar)).currentIndex,
        3,
      );

      await _tap(tester, find.text('Profile'));
      expect(find.text(placeholderFor(RouteNames.profilePath)), findsOneWidget);
    });

    testWidgets('Home and Tailor are reachable from the nav', (tester) async {
      await _open(tester);

      await _tap(tester, find.text('Tailor'));
      expect(
        find.text(placeholderFor(RouteNames.tailoringPath)),
        findsOneWidget,
      );
    });

    testWidgets('Home replaces the tracker', (tester) async {
      await _open(tester);

      await _tap(tester, find.text('Home'));

      expect(find.text(placeholderFor(RouteNames.homePath)), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('with no applications it invites the first one', (
      tester,
    ) async {
      await _open(tester, repository: FakeJobApplicationRepository());

      expect(find.text(AppStrings.trackerEmptyTitle), findsOneWidget);

      await _tap(tester, find.text(AppStrings.trackerAdd));
      expect(
        find.text(placeholderFor(RouteNames.jobApplicationFormPath)),
        findsOneWidget,
      );
    });

    testWidgets('a load failure shows an error with a retry', (tester) async {
      await _open(tester, repository: _ThrowingRepository());

      expect(find.byType(CustomErrorView), findsOneWidget);
      expect(find.text(AppStrings.trackerLoadErrorTitle), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}

class _ThrowingRepository extends FakeJobApplicationRepository {
  @override
  Future<List<JobApplication>> getAllApplications() async =>
      throw Exception('boom');
}
