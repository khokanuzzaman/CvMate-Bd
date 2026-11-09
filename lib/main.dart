import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `.env` holds debug-only switches (USE_MOCK_AI), never keys.
  await dotenv.load(fileName: '.env', isOptional: true);

  // Fail loudly rather than ship canned mock AI output, or no AI server, in a
  // release build.
  final aiProblem = EnvConfig.aiConfigurationProblem();
  if (aiProblem != null) {
    throw StateError(aiProblem);
  }
  await Hive.initFlutter();
  await HiveAiEntitlementCache.openBox();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: CareerMateApp()));
}
