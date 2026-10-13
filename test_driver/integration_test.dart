import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver: writes every `takeScreenshot(name)` to
/// `build/qa/<name>.png`, and the issues the run recorded to
/// `build/qa/issues/<QA_RUN>.json`.
Future<void> main() async {
  const run = String.fromEnvironment('QA_RUN', defaultValue: 'main');
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('build/qa/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      if (data == null) {
        return;
      }
      final file = File('build/qa/issues/$run.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    },
  );
}
