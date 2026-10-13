import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/qa_harness.dart';
import 'support/qa_seed.dart';

/// **Test-only.** Lives outside `lib/`, so it can never be part of a release
/// build. The real app wired the way the integration tests wire it (Firebase
/// Auth emulator, no cloud sync, no analytics), for exploring by hand:
///
///   flutter run -d SIMULATOR_ID -t integration_test/qa_app_main.dart \
///     --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1
///
/// Add `--dart-define=QA_SEED=true` to start with a saved nurse CV, which makes
/// Preview → Export PDF (the native share sheet) a few taps away.
const bool _seed = bool.fromEnvironment('QA_SEED');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (qaAuthEmulatorHost.isEmpty) {
    throw StateError('Pass --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1');
  }
  await dotenv.load(fileName: '.env', isOptional: true);
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator(
    qaAuthEmulatorHost,
    qaAuthEmulatorPort,
  );

  final container = ProviderContainer(overrides: qaBaseOverrides());
  if (_seed) {
    await container.read(cvRepositoryImplProvider).saveCv(nurseCv());
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CareerMateApp(),
    ),
  );
}
