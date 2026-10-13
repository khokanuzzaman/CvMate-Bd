import 'dart:io';

import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_remote_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
  registerFlows();
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
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);
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
    await body(tester);
  }, timeout: timeout);
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
Future<void> shot(WidgetTester tester, String flow, String step) async {
  await tester.pump(const Duration(milliseconds: 250));
  _shotCounter++;
  final prefix = qaRun == 'main' ? '' : '$qaRun/';
  final name = '$prefix$flow/${_shotCounter.toString().padLeft(2, '0')}-$step';
  await qaBinding.takeScreenshot(name);
}

/// Taps [finder] after scrolling it into view and lets the UI react.
Future<void> tapOn(
  WidgetTester tester,
  Finder finder, {
  Duration settle = const Duration(milliseconds: 500),
}) async {
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder.first);
  await pumpFor(tester, settle);
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  Duration settle = const Duration(milliseconds: 500),
}) => tapOn(tester, find.text(text), settle: settle);

/// The text field whose placeholder (while empty) or label is [hintOrLabel].
Finder fieldByHint(String hint) => find.widgetWithText(TextFormField, hint);

Future<void> typeInto(
  WidgetTester tester,
  Finder field,
  String text,
) async {
  await tester.ensureVisible(field.first);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.enterText(field.first, text);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Unique e-mail per run so repeated runs never collide in the emulator.
String uniqueEmail(String tag) =>
    'qa-$tag-${DateTime.now().millisecondsSinceEpoch}@example.com';
