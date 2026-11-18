import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingCrashSink implements CrashSink {
  final List<(String, bool)> records = [];
  final List<String> userIds = [];
  final List<bool> collection = [];
  int deletedUnsent = 0;

  @override
  Future<void> record(
    ScrubbedError error,
    StackTrace stack, {
    required bool fatal,
  }) async => records.add((error.toString(), fatal));

  @override
  Future<void> setUserId(String id) async => userIds.add(id);

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      collection.add(enabled);

  @override
  Future<void> deleteUnsent() async => deletedUnsent++;
}

void main() {
  test('a crash sends its type and stack only, never the message', () async {
    final sink = _RecordingCrashSink();
    final reporter = CrashReporter(sink: sink, enabled: true);

    await reporter.recordFatal(
      const FormatException('Rahim Uddin, rahim@example.com, +8801711000000'),
      StackTrace.current,
    );
    await reporter.recordNonFatal(CrashArea.ai, 'ai_unavailable');
    await reporter.recordNonFatal(CrashArea.billing, 'card declined: 4242');

    expect(sink.records, [
      ('FormatException', true),
      ('ai:ai_unavailable', false),
      ('billing:other', false),
    ]);
  });

  test('records nothing while off; turning off drops unsent reports', () async {
    final sink = _RecordingCrashSink();
    final reporter = CrashReporter(sink: sink, enabled: true);

    await reporter.setEnabled(false);
    await reporter.recordFatal(StateError('x'), null);
    await reporter.recordNonFatal(CrashArea.export, 'pdf_export_failed');

    expect(sink.records, isEmpty);
    expect(sink.collection, [false]);
    expect(sink.deletedUnsent, 1);
  });

  test('the user id is a hash of the uid, cleared on sign-out', () async {
    final sink = _RecordingCrashSink();
    final reporter = CrashReporter(sink: sink);

    await reporter.setUser('firebase-uid-123');
    await reporter.setUser(null);

    expect(sink.userIds.first, isNot(contains('firebase-uid-123')));
    expect(sink.userIds.first, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(sink.userIds.last, '');
  });
}
