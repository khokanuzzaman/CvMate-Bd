import 'dart:convert';

import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_request_payload.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';

/// [AiCareerService] backed by the AI server (`POST /v1/ai/generate`, repo
/// `cvmate-api`). The server checks the Firebase ID token, the AI quota and
/// the budget, calls Claude and answers
/// `{success, action, content, message, usage, remainingActions}`.
class ServerAiCareerService implements AiCareerService {
  const ServerAiCareerService({
    required this.client,
    required this.responseParser,
    this.onRemainingActions,
  });

  static const String generatePath = '/v1/ai/generate';

  final AiServerClient client;
  final AiResponseParser responseParser;

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
      final response = await client.postJson(generatePath, payload);
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
}
