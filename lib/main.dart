import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Development-only dotenv loading for temporary direct OpenAI access.
  // Remove this client-side key path before Play Store release and use the
  // Firebase Cloud Functions AI proxy instead.
  await dotenv.load(fileName: '.env', isOptional: true);
  await Hive.initFlutter();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: CareerMateApp()));
}
