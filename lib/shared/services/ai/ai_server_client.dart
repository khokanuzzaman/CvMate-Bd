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
/// Never logs the token, the request body (CV text, job posts) or the answer.
class AiServerClient {
  const AiServerClient({
    required this.dio,
    required this.readIdToken,
    this.appId = EnvConfig.aiAppId,
  });

  final Dio dio;
  final IdTokenReader readIdToken;
  final String appId;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) {
    return _send(
      (options) => dio.post<Object?>(path, data: body, options: options),
    );
  }

  Future<Map<String, dynamic>> getJson(String path) {
    return _send((options) => dio.get<Object?>(path, options: options));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<Object?>> Function(Options options) request,
  ) async {
    try {
      return _asMap(await request(await _options(forceRefresh: false)));
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        throw _mapError(error);
      }
    }
    // The token may have expired between reading and sending: refresh once.
    try {
      return _asMap(await request(await _options(forceRefresh: true)));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Options> _options({required bool forceRefresh}) async {
    final token = await readIdToken(forceRefresh: forceRefresh);
    if (token == null || token.isEmpty) {
      throw const AppException(
        AiFailureMessages.login,
        code: AiFailureCodes.authRequired,
      );
    }
    return Options(
      headers: {'X-App-Id': appId, 'Authorization': 'Bearer $token'},
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
