import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files allowed to put "mock" in a string: the debug-only labels (shown
/// only when EnvConfig.isMockAiActive, never in release) and the USE_MOCK_AI
/// env key.
const _allowed = {
  'lib/core/config/dev_labels.dart',
  'lib/core/config/env_config.dart',
};

/// Single- or double-quoted string literals on one line.
final _single = RegExp(r"'(?:[^'\\]|\\.)*'");
final _double = RegExp(r'"(?:[^"\\]|\\.)*"');

void main() {
  test('no user-facing string in lib/ says "mock"', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (_allowed.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('import ') ||
            line.startsWith('export ') ||
            line.startsWith('part ') ||
            line.startsWith('//')) {
          continue;
        }
        for (final match in [
          ..._single.allMatches(line),
          ..._double.allMatches(line),
        ]) {
          if (match.group(0)!.toLowerCase().contains('mock')) {
            offenders.add('$path:${i + 1}: ${match.group(0)}');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
