import 'dart:convert';

import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_input_limits.dart';
import 'package:careermatebd/shared/services/ai/ai_request_payload.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/ai/idempotency_key.dart';
import 'package:careermatebd/shared/services/ai/pending_ai_request.dart';

/// [AiCareerService] backed by the AI server (`POST /v1/ai/generate`, repo
/// `cvmate-api`). The server checks the Firebase ID token, the AI quota and
/// the budget, calls Claude and answers
/// `{success, action, content, message, usage, remainingActions}`.
class ServerAiCareerService implements AiCareerService {
  const ServerAiCareerService({
    required this.client,
    required this.responseParser,
    this.onRemainingActions,
    this.pendingStore,
    this.readUid,
    this.clock = DateTime.now,
  });

  static const String generatePath = '/v1/ai/generate';

  final AiServerClient client;
  final AiResponseParser responseParser;

  /// Keeps the last request's `Idempotency-Key` on the device until it is
  /// answered (see [PendingAiRequest]). Null: the key lives only in memory.
  final PendingAiRequestStore? pendingStore;

  /// The signed-in user's uid (null when signed out).
  final String? Function()? readUid;
  final DateTime Function() clock;

  /// Called with the AI actions left after every answered call (0 when the
  /// quota ran out), so the UI counter stays current without another request.
  final void Function(int remaining)? onRemainingActions;

  @override
  Future<Result<AiTextSuggestion>> generateProfessionalSummary({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    return _callAndParse(
      action: 'generateProfessionalSummary',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {'jobTitle': jobTitle.trim()},
      parser: responseParser.parseTextSuggestion,
    );
  }

  @override
  Future<Result<AiTextSuggestion>> generateCareerObjective({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    return _callAndParse(
      action: 'generateCareerObjective',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {'jobTitle': jobTitle.trim()},
      parser: responseParser.parseTextSuggestion,
    );
  }

  @override
  Future<Result<AiTextSuggestion>> improveExperienceBullet({
    required String bullet,
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String companyName = '',
    String jobTitle = '',
  }) {
    return _callAndParse(
      action: 'improveExperienceBullet',
      profile: profile,
      inputText: bullet,
      language: language,
      tone: tone,
      metadata: {
        'companyName': companyName.trim(),
        'jobTitle': jobTitle.trim(),
      },
      parser: responseParser.parseTextSuggestion,
    );
  }

  @override
  Future<Result<AiTextSuggestion>> improveProjectDescription({
    required ProjectInfo project,
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) {
    return _callAndParse(
      action: 'improveProjectDescription',
      profile: profile,
      inputText: project.description,
      language: language,
      tone: tone,
      metadata: {
        'projectTitle': project.title.trim(),
        'projectRole': project.role.trim(),
        'projectTechnologies': project.technologies,
      },
      parser: responseParser.parseTextSuggestion,
    );
  }

  @override
  Future<Result<List<SkillSuggestion>>> suggestSkills({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
    int maxSuggestions = 5,
  }) {
    return _callAndParse(
      action: 'suggestSkills',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {'jobTitle': jobTitle.trim(), 'maxSuggestions': maxSuggestions},
      parser: responseParser.parseSkillSuggestions,
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateCoverLetter({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    bool isShortVersion = false,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.formal,
  }) {
    return _callAndParse(
      action: 'generateCoverLetter',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {
        'companyName': companyName.trim(),
        'jobTitle': jobTitle.trim(),
        'hiringManagerName': hiringManagerName.trim(),
        'candidateSummary': candidateSummary.trim(),
        'isShortVersion': isShortVersion,
      },
      parser: responseParser.parseDocumentDraft,
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateJobApplicationEmail({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.formal,
  }) {
    return _callAndParse(
      action: 'generateJobApplicationEmail',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {
        'companyName': companyName.trim(),
        'jobTitle': jobTitle.trim(),
        'hiringManagerName': hiringManagerName.trim(),
        'candidateSummary': candidateSummary.trim(),
      },
      parser: responseParser.parseDocumentDraft,
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateLinkedInMessage({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.confident,
  }) {
    return _callAndParse(
      action: 'generateLinkedInMessage',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {
        'companyName': companyName.trim(),
        'jobTitle': jobTitle.trim(),
        'hiringManagerName': hiringManagerName.trim(),
        'candidateSummary': candidateSummary.trim(),
      },
      parser: responseParser.parseDocumentDraft,
    );
  }

  @override
  Future<Result<InterviewQuestionSet>> generateInterviewQuestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobTitle = '',
    String companyName = '',
    String jobPostText = '',
    String interviewType = '',
    String answerStyle = '',
  }) {
    return _callAndParse(
      action: 'generateInterviewQuestions',
      profile: profile,
      language: language,
      jobPost: jobPostText,
      metadata: {
        'jobTitle': jobTitle.trim(),
        'companyName': companyName.trim(),
        'interviewType': interviewType.trim(),
        'answerStyle': answerStyle.trim(),
      },
      parser: responseParser.parseInterviewQuestions,
    );
  }

  @override
  Future<Result<AtsSuggestionReport>> generateAtsSuggestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobPostText = '',
  }) {
    return _callAndParse(
      action: 'generateAtsSuggestions',
      profile: profile,
      language: language,
      jobPost: jobPostText,
      parser: responseParser.parseAtsSuggestions,
    );
  }

  @override
  Future<Result<JobPostAnalysis>> analyzeJobPost({
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    return _callAndParse(
      action: 'analyzeJobPost',
      language: language,
      jobPost: jobPostText,
      parser: responseParser.parseJobPostAnalysis,
    );
  }

  @override
  Future<Result<CvJobMatchResult>> calculateCvJobMatch({
    required CvProfile profile,
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    return _callAndParse(
      action: 'calculateCvJobMatch',
      profile: profile,
      language: language,
      jobPost: jobPostText,
      parser: responseParser.parseCvJobMatch,
    );
  }

  @override
  Future<Result<CvTailoringSuggestion>> tailorCvForJob({
    required CvProfile profile,
    required String jobPostText,
    String jobTitle = '',
    String companyName = '',
    List<String> targetKeywords = const [],
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) {
    return _callAndParse(
      action: 'tailorCvForJob',
      profile: profile,
      language: language,
      tone: tone,
      jobPost: jobPostText,
      metadata: {
        'jobTitle': jobTitle.trim(),
        'companyName': companyName.trim(),
        'targetKeywords': targetKeywords,
      },
      parser: responseParser.parseCvTailoring,
    );
  }

  Future<Result<T>> _callAndParse<T>({
    required String action,
    required T Function(String rawResponse) parser,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    CvProfile? profile,
    String inputText = '',
    String jobPost = '',
    Map<String, dynamic>? metadata,
  }) async {
    final tooLong = _tooLongFailure(jobPost: jobPost, inputText: inputText);
    if (tooLong != null) {
      return FailureResult(tooLong);
    }

    final payload = AiRequestPayload.build(
      action: action,
      language: language,
      tone: tone,
      profile: profile,
      inputText: inputText,
      jobPost: jobPost,
      metadata: metadata,
    );

    try {
      final response = await _post(action, payload);
      final remaining = response['remainingActions'];
      if (remaining is num) {
        onRemainingActions?.call(remaining.toInt());
      }

      final content = response['content'];
      if (response['success'] != true || content == null) {
        return const FailureResult(
          Failure(AiFailureMessages.generic, code: AiFailureCodes.failed),
        );
      }
      return Success(parser(jsonEncode(content)));
    } on AppException catch (error) {
      if (error.code == AiFailureCodes.quotaExceeded) {
        onRemainingActions?.call(0);
      }
      return FailureResult(Failure(error.message, code: error.code));
    } catch (_) {
      return const FailureResult(
        Failure(AiFailureMessages.generic, code: AiFailureCodes.failed),
      );
    }
  }

  /// Checked before any request (and so before any quota is used).
  Failure? _tooLongFailure({
    required String jobPost,
    required String inputText,
  }) {
    final jobPostLength = jobPost.trim().length;
    if (jobPostLength > AiInputLimits.jobPostMaxChars) {
      return Failure(
        AiFailureMessages.jobPostTooLong(jobPostLength),
        code: AiFailureCodes.tooLong,
      );
    }
    final inputLength = inputText.trim().length;
    if (inputLength > AiInputLimits.inputTextMaxChars) {
      return Failure(
        AiFailureMessages.inputTextTooLong(inputLength),
        code: AiFailureCodes.tooLong,
      );
    }
    return null;
  }

  /// Sends [payload] with an `Idempotency-Key`. The key is stored first, so
  /// the same request sent again within [PendingAiRequest.ttl] (after a lost
  /// connection or an app restart) reuses it and is not charged twice.
  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final store = pendingStore;
    final uid = readUid?.call();
    if (store == null || uid == null) {
      return client.postJson(
        generatePath,
        payload,
        idempotencyKey: newIdempotencyKey(),
      );
    }

    final bodyHash = PendingAiRequest.hashBody(payload);
    final now = clock();
    var entry = await _load(store);
    if (entry != null &&
        (entry.isExpired(now) ||
            !entry.matches(uid: uid, bodyHash: bodyHash))) {
      entry = null;
    }
    final fetched = entry?.response;
    if (fetched != null) {
      // Fetched after a restart and not used yet: free, no second request.
      await _clear(store);
      return Map<String, dynamic>.of(fetched)..remove('remainingActions');
    }

    entry ??= PendingAiRequest(
      key: newIdempotencyKey(),
      uid: uid,
      action: action,
      bodyHash: bodyHash,
      body: payload,
      createdAt: now,
    );
    await _save(store, entry);
    try {
      final response = await client.postJson(
        generatePath,
        payload,
        idempotencyKey: entry.key,
      );
      await _clear(store);
      return response;
    } on AppException catch (error) {
      if (!_mayStillRun(error)) {
        await _clear(store); // The server answered: nothing to replay.
      }
      rethrow;
    }
  }

  /// After a restart: fetches the answer to the request the app sent but
  /// never saw, with its original key, so the server replays it instead of
  /// charging again. Returns the entry with its [PendingAiRequest.response],
  /// or null when there is nothing to show.
  Future<PendingAiRequest?> recoverPending() async {
    final store = pendingStore;
    final uid = readUid?.call();
    if (store == null || uid == null) {
      return null;
    }
    final entry = await _load(store);
    if (entry == null) {
      return null;
    }
    if (entry.isExpired(clock()) || entry.uid != uid) {
      await _clear(store);
      return null;
    }
    if (entry.response != null) {
      return entry;
    }
    try {
      final response = await client.postJson(
        generatePath,
        entry.body,
        idempotencyKey: entry.key,
      );
      final remaining = response['remainingActions'];
      if (remaining is num) {
        onRemainingActions?.call(remaining.toInt());
      }
      if (response['success'] != true || response['content'] == null) {
        await _clear(store);
        return null;
      }
      final ready = entry.withResponse(response);
      await _save(store, ready);
      return ready;
    } on AppException catch (error) {
      if (!_mayStillRun(error)) {
        await _clear(store);
      }
      return null;
    }
  }

  /// Forgets the stored request with [key] once the user has seen its
  /// result. A newer request stored since then is kept.
  Future<void> dismissPending(String key) async {
    final store = pendingStore;
    if (store != null && (await _load(store))?.key == key) {
      await _clear(store);
    }
  }

  /// True when no answer arrived, so the server may still hold a result.
  static bool _mayStillRun(AppException error) =>
      error.code == AiFailureCodes.unavailable ||
      error.code == AiFailureCodes.offline;

  // Storage problems never block an AI call: the key then lives in memory.
  static Future<PendingAiRequest?> _load(PendingAiRequestStore store) async {
    try {
      return await store.load();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _save(
    PendingAiRequestStore store,
    PendingAiRequest entry,
  ) async {
    try {
      await store.save(entry);
    } catch (_) {}
  }

  static Future<void> _clear(PendingAiRequestStore store) async {
    try {
      await store.clear();
    } catch (_) {}
  }
}
