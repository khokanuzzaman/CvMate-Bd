import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Replaced in `main.dart` with the instance the global error hooks use.
final crashReporterProvider = Provider<CrashReporter>((ref) {
  return CrashReporter(sink: const FirebaseCrashSink());
});

/// Which part of the app a non-fatal failure came from.
enum CrashArea { ai, billing, export, account, feedback }

/// What reaches Crashlytics instead of the real exception: its type only.
///
/// Exception messages can contain user text (a `FormatException` echoes its
/// input, an AI error may quote a CV), so the message is never sent.
@immutable
class ScrubbedError {
  const ScrubbedError(this.type);

  /// For a crash: the exception's runtime type. For a non-fatal:
  /// `area:code`, e.g. `ai:ai_unavailable`.
  final String type;

  @override
  String toString() => type;
}

/// Where crash reports go. [FirebaseCrashSink] in the app; tests record.
abstract class CrashSink {
  Future<void> record(
    ScrubbedError error,
    StackTrace stack, {
    required bool fatal,
  });

  Future<void> setUserId(String id);

  Future<void> setCollectionEnabled(bool enabled);

  /// Drops reports saved on the device but not sent yet (after opting out).
  Future<void> deleteUnsent();
}

class FirebaseCrashSink implements CrashSink {
  const FirebaseCrashSink();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> record(
    ScrubbedError error,
    StackTrace stack, {
    required bool fatal,
  }) =>
      _crashlytics.recordError(error, stack, fatal: fatal, printDetails: false);

  @override
  Future<void> setUserId(String id) => _crashlytics.setUserIdentifier(id);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> deleteUnsent() => _crashlytics.deleteUnsentReports();
}

/// Crash and failure reporting, with no user content.
///
/// - Crashes: the exception's type and a stack trace (code locations only);
///   never the message or Flutter's error details.
/// - Non-fatals: `area:code` only (AI, billing, export failures).
/// - User id: a SHA-256 hash of the Firebase uid, never the email.
/// - Nothing is recorded while [enabled] is false (debug builds unless
///   `ANALYTICS_DEBUG=true`, or "Share usage analytics" off).
class CrashReporter {
  CrashReporter({required CrashSink sink, bool enabled = false})
    : _sink = sink,
      _enabled = enabled;

  final CrashSink _sink;
  bool _enabled;

  bool get enabled => _enabled;

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _safely(() => _sink.setCollectionEnabled(enabled));
    if (!enabled) {
      await _safely(_sink.deleteUnsent);
    }
  }

  /// An uncaught error (Flutter framework or platform dispatcher).
  Future<void> recordFatal(Object error, StackTrace? stack) async {
    if (!_enabled) {
      return;
    }
    await _safely(
      () => _sink.record(
        ScrubbedError(error.runtimeType.toString()),
        stack ?? StackTrace.empty,
        fatal: true,
      ),
    );
  }

  /// An expected failure worth counting, by its error code only.
  Future<void> recordNonFatal(CrashArea area, String code) async {
    if (!_enabled) {
      return;
    }
    await _safely(
      () => _sink.record(
        ScrubbedError('${area.name}:${safeCode(code)}'),
        StackTrace.current,
        fatal: false,
      ),
    );
  }

  /// Signed in: the hashed uid. Signed out: an empty id.
  Future<void> setUser(String? uid) async {
    await _safely(() => _sink.setUserId(uid == null ? '' : hashUid(uid)));
  }

  static String hashUid(String uid) =>
      sha256.convert(utf8.encode(uid)).toString();

  /// Error codes are ours (`ai_unavailable`, `network-request-failed`); this
  /// keeps anything else out.
  static String safeCode(String code) {
    final trimmed = code.trim();
    return RegExp(r'^[a-zA-Z0-9_.\-]{1,64}$').hasMatch(trimmed)
        ? trimmed
        : 'other';
  }

  Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      developer.log(
        'Crash reporting call failed (${error.runtimeType}).',
        name: 'cvmate.crash',
      );
    }
  }
}

/// Sends uncaught Flutter and platform errors to [reporter]. Debug builds
/// still print them to the console as usual.
void installCrashHandlers(CrashReporter reporter) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    reporter.recordFatal(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordFatal(error, stack);
    // Debug builds still print it; release builds treat it as handled.
    return !kDebugMode;
  };
}
