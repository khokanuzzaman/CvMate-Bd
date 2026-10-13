import 'dart:io';

import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_remote_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

/// Test-only switch. Host of the Firebase **Auth emulator**; the suite refuses
/// to run without it so it can never create users in the production project:
///
///   --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1
const String qaAuthEmulatorHost = String.fromEnvironment(
  'QA_AUTH_EMULATOR_HOST',
);
const int qaAuthEmulatorPort = int.fromEnvironment(
  'QA_AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);

/// Name of this run, used as the screenshot folder prefix for stress runs.
const String qaRun = String.fromEnvironment('QA_RUN', defaultValue: 'main');

/// Text scale applied to the whole app (stress runs use 1.3 and 2.0).
final double qaTextScale =
    double.tryParse(const String.fromEnvironment('QA_TEXT_SCALE')) ?? 1.0;

/// When true (the 1.5x / 2x runs), the run ends with a test that fails if any
/// layout overflow was recorded anywhere.
const bool qaStrictOverflow = bool.fromEnvironment('QA_STRICT_OVERFLOW');

/// Host folder for files a flow wants to hand back (e.g. exported PDFs). The
/// iOS simulator shares the Mac's file system, so the app can write there.
const String qaHostOut = String.fromEnvironment('QA_HOST_OUT');

late final IntegrationTestWidgetsFlutterBinding qaBinding;
bool _booted = false;
int _shotCounter = 0;

/// Everything non-fatal the run noticed (overflows, exceptions), for the report.
final List<Map<String, Object?>> qaIssues = [];

String _currentTest = '';

/// Entry point for a QA suite: initializes the binding synchronously (tests
/// must be registered before `main` returns), boots the app services once in
/// `setUpAll`, then registers the flows.
void registerQaSuite(void Function() registerFlows) {
  qaBinding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_bootQa);
  tearDownAll(
    () =>
        qaBinding.reportData = {...?qaBinding.reportData, 'qaIssues': qaIssues},
  );
  registerFlows();
  if (qaStrictOverflow) {
    testWidgets('no layout overflow anywhere in the run', (tester) async {
      final overflows = [
        for (final issue in qaIssues)
          if (issue['kind'] == 'overflow')
            '${issue['test']}: ${issue['message']}',
      ];
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  }
}

/// Boots Hive + Firebase (pointed at the Auth emulator) once per process.
Future<void> _bootQa() async {
  if (_booted) {
    return;
  }
  if (qaAuthEmulatorHost.isEmpty) {
    throw StateError(
      'QA_AUTH_EMULATOR_HOST is not set. Start the emulator '
      '(firebase emulators:start --only auth --project demo-cvmate) and pass '
      '--dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1. Refusing to run against '
      'the production Firebase project.',
    );
  }
  await _assertEmulatorReachable();
  await dotenv.load(fileName: '.env', isOptional: true);
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator(
    qaAuthEmulatorHost,
    qaAuthEmulatorPort,
  );
  _booted = true;
}

Future<void> _assertEmulatorReachable() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client.getUrl(
      Uri.parse('http://$qaAuthEmulatorHost:$qaAuthEmulatorPort/'),
    );
    final response = await request.close();
    await response.drain<void>();
  } finally {
    client.close(force: true);
  }
}

/// A remote data source that goes nowhere: cloud sync must not touch the
/// production Firestore from a QA run (only Auth has an emulator here).
class _OfflineCvRemote extends CvRemoteDataSource {
  _OfflineCvRemote() : super(FirebaseFirestore.instance);

  @override
  Future<void> upsert(String uid, CvProfileDto dto) async {}

  @override
  Future<void> delete(String uid, String id) async {}

  @override
  Future<List<CvProfileDto>> fetchAll(String uid) async => const [];
}

class _SilentAnalytics extends AnalyticsService {
  const _SilentAnalytics();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? params}) async {}
}

/// Providers every QA run replaces. Add per-test overrides on top.
List<Override> qaBaseOverrides() => [
  cvRemoteDataSourceProvider.overrideWithValue(_OfflineCvRemote()),
  analyticsServiceProvider.overrideWithValue(const _SilentAnalytics()),
];

/// Wipes local state (signed-in user, Hive boxes) so each flow starts as a
/// fresh install.
Future<void> resetAppState() async {
  await FirebaseAuth.instance.signOut();
  await Hive.deleteFromDisk();
}

/// Starts the real app (real router, real auth against the emulator, mock AI).
Future<void> launchApp(
  WidgetTester tester, {
  bool freshInstall = true,
  List<Override> overrides = const [],
}) async {
  if (freshInstall) {
    await resetAppState();
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...qaBaseOverrides(), ...overrides],
      child: const CareerMateApp(),
    ),
  );
  await pumpFor(tester, const Duration(milliseconds: 300));
}

/// Registers a test with overflow/exception capture. Overflows and other
/// framework errors are recorded in [qaIssues] (and printed as `QA-ISSUE`)
/// instead of aborting, so one run surfaces all of them.
void qaTest(
  String description,
  Future<void> Function(WidgetTester tester) body, {
  Timeout timeout = const Timeout(Duration(minutes: 5)),
}) {
  testWidgets(description, (tester) async {
    _currentTest = description;
    _shotCounter = 0;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      final isOverflow = text.contains('overflowed');
      qaIssues.add({
        'test': _currentTest,
        'kind': isOverflow ? 'overflow' : 'exception',
        'message': text.split('\n').first,
        'library': details.library,
      });
      debugPrint('QA-ISSUE[$_currentTest] ${text.split('\n').first}');
      if (!isOverflow) {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    final scale = qaTextScale;
    if (scale != 1.0) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    try {
      await body(tester);
      await _leaveApp(tester);
    } catch (_) {
      // Keep a picture of where the flow broke, plus any snackbar text.
      try {
        for (final text
            in find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Text),
                )
                .evaluate()
                .map((e) => (e.widget as Text).data)) {
          debugPrint('QA-FAILSTATE snackbar: $text');
        }
        await shot(tester, 'FAILED', description.split(':').first);
      } catch (_) {}
      rethrow;
    }
  }, timeout: timeout);
}

/// Navigates the app back to the splash route so screens (e.g. the CV
/// builder, which flushes an autosave in `dispose`) are torn down while their
/// providers are still alive, as in real use, not by the harness dropping the
/// whole ProviderScope under them.
Future<void> _leaveApp(WidgetTester tester) async {
  if (find.byType(CareerMateApp).evaluate().isEmpty) {
    return;
  }
  appContainer(tester).read(appRouterProvider).go('/');
  await pumpFor(tester, const Duration(milliseconds: 600));
}

/// Pumps frames for [duration] without waiting for animations to finish
/// (the splash dots and progress indicators never settle).
Future<void> pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Pumps until [finder] matches, or fails after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  String? reason,
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    elapsed += const Duration(milliseconds: 100);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for ${reason ?? finder}');
}

/// Pumps until [finder] no longer matches.
Future<void> waitGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    elapsed += const Duration(milliseconds: 100);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder to disappear');
}

/// Saves `build/qa/<[qaRun] prefix>/<flow>/<NN-step>.png`.
///
/// Screenshots capture only the Flutter surface, not the iOS keyboard, so the
/// keyboard is dismissed first: a half-height layout with no keyboard drawn
/// would be misleading.
Future<void> shot(WidgetTester tester, String flow, String step) async {
  if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFor(tester, const Duration(milliseconds: 500));
  }
  await tester.pump(const Duration(milliseconds: 250));
  _shotCounter++;
  final prefix = qaRun == 'main' ? '' : '$qaRun/';
  final name = '$prefix$flow/${_shotCounter.toString().padLeft(2, '0')}-$step';
  await qaBinding.takeScreenshot(name);
}

/// [shot] after scrolling the main scroll view back to the top, so the whole
/// first screen of a form can be compared with its design.
Future<void> shotTop(WidgetTester tester, String flow, String step) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpFor(tester, const Duration(milliseconds: 500));
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    for (final element in scrollables.evaluate()) {
      final widget = element.widget as Scrollable;
      if (widget.axisDirection == AxisDirection.down) {
        await tester.drag(find.byWidget(widget), const Offset(0, 4000));
        break;
      }
    }
    await pumpFor(tester, const Duration(milliseconds: 400));
  }
  await shot(tester, flow, step);
}

/// Scrolls [finder] into a tappable position. `ensureVisible` alone can stop
/// short while the keyboard has shrunk the viewport, so fall back to dragging
/// the nearest vertical scrollable.
Future<void> scrollIntoReach(WidgetTester tester, Finder finder) async {
  // Lazy lists only build what is near the viewport; scroll to build it.
  if (finder.evaluate().isEmpty) {
    final lists = find.byType(Scrollable).hitTestable();
    for (final element in lists.evaluate()) {
      final widget = element.widget as Scrollable;
      if (widget.axisDirection == AxisDirection.down) {
        try {
          await tester.scrollUntilVisible(
            finder,
            300,
            scrollable: find.byWidget(widget),
            maxScrolls: 40,
          );
        } catch (_) {
          // It may be above the viewport: look upwards too.
          await tester.scrollUntilVisible(
            finder,
            -300,
            scrollable: find.byWidget(widget),
            maxScrolls: 80,
          );
        }
        break;
      }
    }
  }
  // A user closes the keyboard (tap outside / Done) before reaching a button
  // below the fold; the open keyboard shrinks the viewport to a sliver.
  if (!finder.hitTestable().evaluate().isNotEmpty) {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFor(tester, const Duration(milliseconds: 600));
  }
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 100));
  if (finder.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  Finder? scrollable;
  finder.first.evaluate().first.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up)) {
      scrollable = find.byWidget(widget);
      return false;
    }
    return true;
  });
  if (scrollable == null) {
    return;
  }
  await tester.dragUntilVisible(
    finder.first,
    scrollable!,
    const Offset(0, -150),
    maxIteration: 40,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Taps [finder] after scrolling it into view and lets the UI react.
Future<void> tapOn(
  WidgetTester tester,
  Finder finder, {
  Duration settle = const Duration(milliseconds: 500),
}) async {
  await scrollIntoReach(tester, finder);
  await tester.tap(finder.first);
  await pumpFor(tester, settle);
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  Duration settle = const Duration(milliseconds: 500),
}) => tapOn(tester, find.text(text), settle: settle);

/// The text field whose placeholder (while empty) or label is [hintOrLabel].
Finder fieldByHint(String hint) => find.widgetWithText(TextField, hint);

/// The text currently in [field]'s editable.
String fieldText(WidgetTester tester, Finder field) => tester
    .state<EditableTextState>(
      find.descendant(of: field.first, matching: find.byType(EditableText)),
    )
    .textEditingValue
    .text;

/// Types like a user: bring the field into reach, tap it to focus (the
/// keyboard may have been dismissed by a screenshot or a scroll), enter the
/// text, and check it arrived. On some devices a second entry into a field
/// that already has text is dropped, so retry a few times before giving up.
Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    await scrollIntoReach(tester, field);
    await tester.tap(field.first);
    await pumpFor(tester, const Duration(milliseconds: 250));
    await tester.enterText(field.first, text);
    await pumpFor(tester, const Duration(milliseconds: 150));
    if (fieldText(tester, field) == text) {
      return;
    }
    debugPrint('QA-NOTE typeInto retry ${attempt + 1} for "$text"');
  }
  fail('Could not enter "$text" into $field');
}

/// Unique e-mail per run so repeated runs never collide in the emulator.
String uniqueEmail(String tag) =>
    'qa-$tag-${DateTime.now().millisecondsSinceEpoch}@example.com';

/// The app's Riverpod container (to read state or seed data through the real
/// repositories, never to bypass the UI under test).
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CareerMateApp)));

/// Goes back like a user would: the screen's own chevron when it has one,
/// otherwise the system back (pop) gesture.
Future<void> goBack(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpFor(tester, const Duration(milliseconds: 300));
  final chevron = find.byIcon(Icons.chevron_left_rounded).hitTestable();
  if (chevron.evaluate().isNotEmpty) {
    await tester.tap(chevron.last);
  } else {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
  }
  await pumpFor(tester, const Duration(milliseconds: 600));
}

/// Signs in as a fresh guest-free test user and lands on Home, the way a
/// returning user would (account created in the emulator only).
Future<void> launchSignedIn(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await resetAppState();
  await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: uniqueEmail('user'),
    password: 'QaPass123',
  );
  await launchApp(tester, freshInstall: false, overrides: overrides);
  await waitFor(tester, find.text('Ready to apply?'));
}

/// Writes [bytes] to `<QA_HOST_OUT>/<relativePath>` on the host (no-op when
/// QA_HOST_OUT is not set).
Future<void> saveHostFile(String relativePath, List<int> bytes) async {
  if (qaHostOut.isEmpty) {
    return;
  }
  final file = File('$qaHostOut/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

/// Replaces share_plus' native side (the iOS share sheet can't be dismissed
/// from Dart). Returns the calls it received. The real sheet is checked by hand.
List<MethodCall> mockSharePlus(WidgetTester tester) {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    call,
  ) async {
    calls.add(call);
    return 'dev.fluttercommunity.plus/share/unavailable';
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
  return calls;
}
