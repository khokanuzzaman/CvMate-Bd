import 'package:careermatebd/features/feedback/data/feedback_diagnostics.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/analytics/analytics_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server path that stores feedback (cvmate-api).
const String feedbackPath = '/v1/feedback';

/// The longest message the server accepts.
const int feedbackMaxLength = 2000;

class FeedbackSubmission {
  const FeedbackSubmission({
    required this.category,
    required this.message,
    required this.allowReply,
    this.diagnostics,
  });

  final FeedbackCategory category;
  final String message;

  /// The user ticked "You may reply to me at my sign-in email". The server
  /// then stores the email from the verified sign-in token, never one the
  /// app sends.
  final bool allowReply;
  final FeedbackDiagnostics? diagnostics;

  Map<String, Object> toJson() => {
    'category': category.wire,
    'message': message,
    'allowReply': allowReply,
    'diagnostics': ?diagnostics?.toJson(),
  };
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(aiServerClientProvider));
});

/// Sends feedback to our server with the same auth as AI requests (the
/// Firebase ID token; guests have an anonymous one).
class FeedbackRepository {
  const FeedbackRepository(this._client);

  final AiServerClient _client;

  /// Throws an `AppException` with an [AiFailureCodes] code on failure.
  Future<void> send(FeedbackSubmission submission) async {
    await _client.postJson(feedbackPath, submission.toJson());
  }
}
