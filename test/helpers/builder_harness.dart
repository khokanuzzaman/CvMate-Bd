import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_builder_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_preview_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_sections_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_style_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_template_screen.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_cv_repository.dart';

const String builderPath = '/builder';
const String aiImprovePlaceholder = 'ai-improve-page';
const String paywallPlaceholder = 'paywall-page';

/// In-memory [EntitlementStore]; [saveCount] shows whether an export was
/// recorded.
class FakeEntitlementStore implements EntitlementStore {
  FakeEntitlementStore([EntitlementRecord? record])
    : record = record ?? const EntitlementRecord.initial();

  EntitlementRecord record;
  int saveCount = 0;

  @override
  Future<EntitlementRecord> load() async => record;

  @override
  Future<void> save(EntitlementRecord value) async {
    record = value;
    saveCount++;
  }
}

/// Pumps the real builder, preview and template screens in a small router (AI
/// improve and paywall are placeholders) on a phone-sized surface. Returns the
/// container so tests can read controller state.
Future<ProviderContainer> pumpBuilderApp(
  WidgetTester tester, {
  required FakeCvRepository repository,
  FakeEntitlementStore? entitlements,
  String initialLocation = builderPath,
  String? loadDraftId,
}) async {
  tester.view.physicalSize = const Size(390, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = entitlements ?? FakeEntitlementStore();
  final container = ProviderContainer(
    overrides: [
      cvRepositoryProvider.overrideWithValue(repository),
      entitlementServiceProvider.overrideWithValue(EntitlementService(store)),
    ],
  );
  addTearDown(container.dispose);

  if (loadDraftId != null) {
    await container
        .read(cvBuilderControllerProvider.notifier)
        .loadDraft(loadDraftId);
  }

  Widget placeholder(String label) =>
      Scaffold(body: Center(child: Text(label)));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: builderPath,
        builder: (context, state) => const CvBuilderScreen(),
      ),
      GoRoute(
        path: RouteNames.cvPreviewPath,
        builder: (context, state) => const CvPreviewScreen(),
      ),
      GoRoute(
        path: RouteNames.cvStylePath,
        builder: (context, state) => const CvStyleScreen(),
      ),
      GoRoute(
        path: RouteNames.cvSectionsPath,
        builder: (context, state) => CvSectionsScreen(
          openedFromBuilder: state.uri.queryParameters['from'] == 'builder',
        ),
      ),
      GoRoute(
        path: RouteNames.cvTemplatePath,
        builder: (context, state) => const CvTemplateScreen(),
      ),
      GoRoute(
        path: RouteNames.aiImprovePath,
        builder: (context, state) => placeholder(aiImprovePlaceholder),
      ),
      GoRoute(
        path: RouteNames.paywallPath,
        builder: (context, state) => placeholder(paywallPlaceholder),
      ),
      GoRoute(
        path: RouteNames.cvListPath,
        builder: (context, state) => placeholder('cv-list-page'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
