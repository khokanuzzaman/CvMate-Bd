import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/feedback/data/feedback_diagnostics.dart';
import 'package:careermatebd/features/feedback/data/feedback_repository.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedbackPhase { editing, sending, sent }

class FeedbackState {
  const FeedbackState({
    this.category,
    this.message = '',
    this.attachDiagnostics = false,
    this.allowReply = false,
    this.phase = FeedbackPhase.editing,
    this.errorMessage,
  });

  final FeedbackCategory? category;
  final String message;
  final bool attachDiagnostics;

  /// Off by default; only offered to users signed in with an email.
  final bool allowReply;
  final FeedbackPhase phase;
  final String? errorMessage;

  bool get canSend =>
      phase == FeedbackPhase.editing &&
      category != null &&
      message.trim().isNotEmpty &&
      message.length <= feedbackMaxLength;

  FeedbackState copyWith({
    FeedbackCategory? category,
    String? message,
    bool? attachDiagnostics,
    bool? allowReply,
    FeedbackPhase? phase,
    String? errorMessage,
  }) {
    return FeedbackState(
      category: category ?? this.category,
      message: message ?? this.message,
      attachDiagnostics: attachDiagnostics ?? this.attachDiagnostics,
      allowReply: allowReply ?? this.allowReply,
      phase: phase ?? this.phase,
      errorMessage: errorMessage,
    );
  }
}

/// Whether "You may reply to me" can be offered: signed in with an email
/// (guests have no email to reply to).
final feedbackCanReplyProvider = Provider.autoDispose<bool>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  return user != null && !user.isAnonymous && user.email.trim().isNotEmpty;
});

final feedbackControllerProvider =
    NotifierProvider.autoDispose<FeedbackController, FeedbackState>(
      FeedbackController.new,
    );

/// Settings > Report a problem / Send feedback.
class FeedbackController extends Notifier<FeedbackState> {
  @override
  FeedbackState build() {
    unawaited(
      ref.read(analyticsServiceProvider).log(AnalyticsEvent.feedbackOpen),
    );
    return const FeedbackState();
  }

  void selectCategory(FeedbackCategory category) =>
      state = state.copyWith(category: category);

  void updateMessage(String message) =>
      state = state.copyWith(message: message);

  void setAttachDiagnostics(bool value) =>
      state = state.copyWith(attachDiagnostics: value);

  void setAllowReply(bool value) => state = state.copyWith(allowReply: value);

  Future<void> send() async {
    final category = state.category;
    if (!state.canSend || category == null) {
      return;
    }
    state = state.copyWith(phase: FeedbackPhase.sending);
    try {
      final diagnostics = state.attachDiagnostics
          ? await ref.read(feedbackDiagnosticsReaderProvider)()
          : null;
      await ref
          .read(feedbackRepositoryProvider)
          .send(
            FeedbackSubmission(
              category: category,
              message: state.message.trim(),
              allowReply:
                  state.allowReply && ref.read(feedbackCanReplyProvider),
              diagnostics: diagnostics,
            ),
          );
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .log(
              AnalyticsEvent.feedbackSent(
                category,
                diagnostics: diagnostics != null,
              ),
            ),
      );
      if (ref.mounted) {
        state = state.copyWith(phase: FeedbackPhase.sent);
      }
    } catch (error) {
      final code = error is AppException
          ? error.code ?? AiFailureCodes.failed
          : 'feedback_failed';
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordNonFatal(CrashArea.feedback, code),
      );
      if (ref.mounted) {
        state = state.copyWith(
          phase: FeedbackPhase.editing,
          errorMessage: error is AppException
              ? error.message
              : AppStrings.feedbackSendFailed,
        );
      }
    }
  }
}
