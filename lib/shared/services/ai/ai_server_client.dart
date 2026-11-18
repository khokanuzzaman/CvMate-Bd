import 'dart:convert';
import 'dart:developer' as developer;

import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads the signed-in user's Firebase ID token (null when signed out).
typedef IdTokenReader = Future<String?> Function({bool forceRefresh});

/// [AppException.code] / `Failure.code` values for AI failures.
abstract final class AiFailureCodes {
  /// Out of AI actions: open the paywall.
  static const String quotaExceeded = 'ai_quota_exceeded';

  /// Too many AI requests in a minute: a snackbar is enough.
  static const String rateLimited = 'ai_rate_limited';
  static const String unavailable = 'ai_unavailable';
  static const String tooLong = 'ai_payload_too_large';
  static const String invalidInput = 'ai_invalid_input';
  static const String authRequired = 'ai_auth_required';
  static const String consentRequired = 'ai_consent_required';
  static const String failed = 'ai_failed';
}

abstract final class AiFailureMessages {
  static const String busy = 'AI is busy, please try again.';
  static const String quota = "You've used all your AI actions.";
  static const String rateLimited =
      'Too many AI requests. Please wait a minute and try again.';
  static const String tooLong = 'This text is too long.';
  static const String invalidInput = 'Please check your input and try again.';
  static const String login = 'Please sign in to use AI features.';
  static const String generic = 'AI generation failed. Please try again.';
}

final aiServerDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: EnvConfig.aiApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
});

final idTokenReaderProvider = Provider<IdTokenReader>((ref) {
  // Read at call time, so building the AI providers never touches Firebase.
  return ({bool forceRefresh = false}) async {
    if (Firebase.apps.isEmpty) {
      return null; // Not initialized (widget tests): treated as signed out.
    }
    return ref.read(firebaseAuthProvider).currentUser?.getIdToken(forceRefresh);
  };
});

final aiServerClientProvider = Provider<AiServerClient>((ref) {
  return AiServerClient(
    dio: ref.watch(aiServerDioProvider),
    readIdToken: ref.watch(idTokenReaderProvider),
  );
});

/// Talks to the AI server (repo `cvmate-api`): adds `X-App-Id` and the
/// Firebase ID token, retries once with a fresh token on 401, and turns every
/// error into an [AppException] with an [AiFailureCodes] code and a message
/// that is safe to show.
///
/// A request sent with an `Idempotency-Key` is also retried, with the same
/// key, when the connection is lost before an answer arrives (offline,
/// reset, timeout): the server then replays the first run's result instead of
/// charging another AI action. HTTP error answers are never retried this way.
///
/// Never logs the token, the request body (CV text, job posts) or the answer.
class AiServerClient {
  const AiServerClient({
    required this.dio,
    required this.readIdToken,
    this.appId = EnvConfig.aiAppId,
    this.retryDelays = defaultRetryDelays,
    this.maxRetryWindow = const Duration(minutes: 3),
  });

  /// Waits before each retry after a lost connection (3 retries).
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  final Dio dio;
  final IdTokenReader readIdToken;
  final String appId;
  final List<Duration> retryDelays;

  /// No retry starts once this much time has passed since the first attempt,
  /// so the overall wait stays bounded even when attempts time out.
  final Duration maxRetryWindow;

  /// POSTs [body]. With an [idempotencyKey] (8–128 chars of
  /// `[A-Za-z0-9_-]`) it is sent as `Idempotency-Key`, and a lost connection
  /// is retried with that same key.
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) {
    return _send(
      (options) => dio.post<Object?>(path, data: body, options: options),
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Map<String, dynamic>> getJson(String path) {
    return _send((options) => dio.get<Object?>(path, options: options));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<Object?>> Function(Options options) request, {
    String? idempotencyKey,
  }) async {
    Future<Response<Object?>> attempt({required bool forceRefresh}) async {
      final options = await _options(
        forceRefresh: forceRefresh,
        idempotencyKey: idempotencyKey,
      );
      if (idempotencyKey == null) {
        return request(options);
      }
      return _retryOnConnectionLoss(() => request(options));
    }

    try {
      return _asMap(await attempt(forceRefresh: false));
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        throw _mapError(error);
      }
    }
    // The token may have expired between reading and sending: refresh once.
    try {
      return _asMap(await attempt(forceRefresh: true));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Response<Object?>> _retryOnConnectionLoss(
    Future<Response<Object?>> Function() request,
  ) async {
    final elapsed = Stopwatch()..start();
    for (var retry = 0; ; retry++) {
      try {
        return await request();
      } on DioException catch (error) {
        final canRetry =
            isConnectionLoss(error) &&
            retry < retryDelays.length &&
            elapsed.elapsed + retryDelays[retry] <= maxRetryWindow;
        if (!canRetry) {
          rethrow;
        }
      }
      await Future<void>.delayed(retryDelays[retry]);
    }
  }

  /// True when no answer arrived at all (offline, reset, timeout), so the
  /// server may still have run the request. False for any HTTP answer and
  /// for cancels or bad certificates.
  static bool isConnectionLoss(DioException error) {
    if (error.response != null) {
      return false;
    }
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      // A reset mid-request (SocketException / HttpException on mobile).
      // dart:io is not imported (web build), so any I/O exception counts.
      DioExceptionType.unknown => error.error is Exception,
      _ => false,
    };
  }

  Future<Options> _options({
    required bool forceRefresh,
    String? idempotencyKey,
  }) async {
    final token = await readIdToken(forceRefresh: forceRefresh);
    if (token == null || token.isEmpty) {
      throw const AppException(
        AiFailureMessages.login,
        code: AiFailureCodes.authRequired,
      );
    }
    return Options(
      headers: {
        'X-App-Id': appId,
        'Authorization': 'Bearer $token',
        'Idempotency-Key': ?idempotencyKey,
      },
    );
  }

  Map<String, dynamic> _asMap(Response<Object?> response) {
    var data = response.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        data = null;
      }
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const AppException(
      AiFailureMessages.generic,
      code: AiFailureCodes.failed,
    );
  }

  AppException _mapError(DioException error) {
    final response = error.response;
    if (response == null) {
      // Offline, DNS, TLS, connect / receive timeout.
      return const AppException(
        AiFailureMessages.busy,
        code: AiFailureCodes.unavailable,
      );
    }

    final serverCode = _serverErrorCode(response.data);
    switch (response.statusCode) {
      case 401:
        return const AppException(
          AiFailureMessages.login,
          code: AiFailureCodes.authRequired,
        );
      case 402:
        return const AppException(
          AiFailureMessages.quota,
          code: AiFailureCodes.quotaExceeded,
        );
      case 429:
        return const AppException(
          AiFailureMessages.rateLimited,
          code: AiFailureCodes.rateLimited,
        );
      case 413:
        return const AppException(
          AiFailureMessages.tooLong,
          code: AiFailureCodes.tooLong,
        );
      case 400:
        return const AppException(
          AiFailureMessages.invalidInput,
          code: AiFailureCodes.invalidInput,
        );
      case 503:
        return const AppException(
          AiFailureMessages.busy,
          code: AiFailureCodes.unavailable,
        );
      case 404 when serverCode == 'app_not_found':
        // A server setup problem (app row missing or paused), not the user's.
        developer.log(
          'AI server answered 404 app_not_found for X-App-Id "$appId".',
          name: 'cvmate.ai',
        );
    }
    return const AppException(
      AiFailureMessages.generic,
      code: AiFailureCodes.failed,
    );
  }

  String? _serverErrorCode(Object? data) {
    if (data is Map && data['error'] is Map) {
      final code = (data['error'] as Map)['code'];
      return code is String ? code : null;
    }
    return null;
  }
}
