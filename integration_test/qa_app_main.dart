import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/qa_harness.dart';

/// The real app, wired the way the integration tests wire it (Firebase Auth
/// emulator, no cloud sync, no analytics), for exploring by hand:
///
///   flutter run -d SIMULATOR_ID -t integration_test/qa_app_main.dart \
///     --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1
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
  runApp(
    ProviderScope(overrides: qaBaseOverrides(), child: const CareerMateApp()),
  );
}
