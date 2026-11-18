import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The header the AI server checks (cvmate-api, `src/auth/appCheck.ts`).
const String appCheckHeader = 'X-Firebase-AppCheck';

/// Optional fixed debug token for debug builds:
/// `--dart-define=APP_CHECK_DEBUG_TOKEN=<token registered in Firebase>`.
/// Without it, the iOS SDK makes one per install and prints it once in the
/// Xcode / device console ("App Check debug token").
const String _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// Starts Firebase App Check. Release and profile builds prove they are a
/// genuine CvMate with App Attest (DeviceCheck where App Attest is missing)
/// or Play Integrity; debug builds and the simulator use the debug
/// provider. The SDK caches the token and refreshes it before it expires.
Future<void> activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? AppleDebugProvider(
              debugToken: _debugToken.isEmpty ? null : _debugToken,
            )
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: _debugToken.isEmpty ? null : _debugToken,
            )
          : const AndroidPlayIntegrityProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    if (kDebugMode) {
      developer.log(
        'App Check uses the debug provider. Find "App Check debug token" '
        'in the Xcode / device console once and register it in Firebase.',
        name: 'cvmate.appcheck',
      );
    }
  } catch (error) {
    // Requests still go out without the header; the server decides
    // (monitor mode logs, enforce mode rejects).
    developer.log(
      'App Check could not start (${error.runtimeType}).',
      name: 'cvmate.appcheck',
    );
  }
}

/// The current App Check token, or null when there is none.
typedef AppCheckTokenReader = Future<String?> Function();

final appCheckTokenReaderProvider = Provider<AppCheckTokenReader>((ref) {
  return () async {
    if (Firebase.apps.isEmpty) {
      return null; // Not initialized (widget tests).
    }
    // The SDK answers from its cache; a first App Attest can take a moment,
    // but must never hold a request for long.
    return FirebaseAppCheck.instance.getToken().timeout(
      const Duration(seconds: 5),
    );
  };
});

/// Adds [appCheckHeader] to every request to our server. A missing token
/// (no network for the first attestation, an old device, a failure) never
/// blocks the request: the server's App Check mode decides.
class AppCheckInterceptor extends Interceptor {
  AppCheckInterceptor(this.readToken);

  final AppCheckTokenReader readToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await readToken();
      if (token != null && token.isNotEmpty) {
        options.headers[appCheckHeader] = token;
      }
    } catch (error) {
      developer.log(
        'No App Check token (${error.runtimeType}).',
        name: 'cvmate.appcheck',
      );
    }
    handler.next(options);
  }
}
