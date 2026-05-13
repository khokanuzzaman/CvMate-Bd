import 'dart:convert';

import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_prompt_builder.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final directOpenAiDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.openai.com/v1',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
});

final directOpenAiCareerServiceProvider = Provider<DirectOpenAiCareerService>((
  ref,
) {
  return DirectOpenAiCareerService(
    dio: ref.watch(directOpenAiDioProvider),
    promptBuilder: const AiPromptBuilder(),
    responseParser: const AiResponseParser(),
  );
});

/// Development-only direct OpenAI client.
///
/// Remove this path before Play Store release and use the Firebase Cloud
/// Functions AI proxy instead so the API key never ships in the client.
class DirectOpenAiCareerService implements AiCareerService {
  const DirectOpenAiCareerService({
    required this.dio,
    required this.promptBuilder,
    required this.responseParser,
  });

  final Dio dio;
  final AiPromptBuilder promptBuilder;
  final AiResponseParser responseParser;

  @override
  Future<Result<AiTextSuggestion>> generateProfessionalSummary({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    final prompt = promptBuilder.generateProfessionalSummary(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.textSuggestion,
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
    final prompt = promptBuilder.generateCareerObjective(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.textSuggestion,
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
    final trimmedBullet = bullet.trim();
    if (trimmedBullet.isEmpty) {
      return Future.value(
        const FailureResult(
          Failure(
            'AI generation failed. Please provide an experience bullet first.',
            code: 'ai_validation_error',
          ),
        ),
      );
    }

    final prompt = promptBuilder.improveExperienceBullet(
      bullet: trimmedBullet,
      profile: profile,
      language: language,
      tone: tone,
      companyName: companyName,
      jobTitle: jobTitle,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.textSuggestion,
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
    final trimmedDescription = project.description.trim();
    if (trimmedDescription.isEmpty) {
      return Future.value(
        const FailureResult(
          Failure(
            'AI generation failed. Please provide a project description first.',
            code: 'ai_validation_error',
          ),
        ),
      );
    }

    final prompt = promptBuilder.improveProjectDescription(
      project: project,
      profile: profile,
      language: language,
      tone: tone,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.textSuggestion,
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
    final prompt = promptBuilder.suggestSkills(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
      maxSuggestions: maxSuggestions,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.skillSuggestions,
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
    final prompt = promptBuilder.generateCoverLetter(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
      isShortVersion: isShortVersion,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.documentDraft,
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
    final prompt = promptBuilder.generateJobApplicationEmail(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.documentDraft,
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
    final prompt = promptBuilder.generateLinkedInMessage(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.documentDraft,
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
    final prompt = promptBuilder.generateInterviewQuestions(
      profile: profile,
      language: language,
      jobTitle: jobTitle,
      companyName: companyName,
      jobPostText: jobPostText,
      interviewType: interviewType,
      answerStyle: answerStyle,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.interviewQuestionSet,
      parser: responseParser.parseInterviewQuestions,
    );
  }

  @override
  Future<Result<AtsSuggestionReport>> generateAtsSuggestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobPostText = '',
  }) {
    final prompt = promptBuilder.generateAtsSuggestions(
      profile: profile,
      language: language,
      jobPostText: jobPostText,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.atsSuggestionReport,
      parser: responseParser.parseAtsSuggestions,
    );
  }

  @override
  Future<Result<JobPostAnalysis>> analyzeJobPost({
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    final trimmedJobPost = jobPostText.trim();
    if (trimmedJobPost.length < 20) {
      return Future.value(
        const FailureResult(
          Failure('Your input is too short.', code: 'ai_validation_error'),
        ),
      );
    }

    final prompt = promptBuilder.analyzeJobPost(
      jobPostText: trimmedJobPost,
      language: language,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.jobPostAnalysis,
      parser: responseParser.parseJobPostAnalysis,
    );
  }

  @override
  Future<Result<CvJobMatchResult>> calculateCvJobMatch({
    required CvProfile profile,
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    final trimmedJobPost = jobPostText.trim();
    if (trimmedJobPost.length < 20) {
      return Future.value(
        const FailureResult(
          Failure('Your input is too short.', code: 'ai_validation_error'),
        ),
      );
    }

    final prompt = promptBuilder.calculateCvJobMatch(
      profile: profile,
      jobPostText: trimmedJobPost,
      language: language,
    );

    return _executePrompt(
      prompt: prompt,
      schema: _AiJsonSchema.cvJobMatchResult,
      parser: responseParser.parseCvJobMatch,
    );
  }

  Future<Result<T>> _executePrompt<T>({
    required String prompt,
    required _AiJsonSchema schema,
    required T Function(String rawResponse) parser,
  }) async {
    final apiKey = EnvConfig.openAiApiKey;
    if (apiKey.isEmpty) {
      return const FailureResult(
        Failure(
          'OpenAI API key is missing. Add OPENAI_API_KEY to .env or re-enable mock AI.',
          code: 'ai_missing_key',
        ),
      );
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/responses',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
        data: {
          'model': EnvConfig.directOpenAiModel,
          'store': false,
          'input': prompt,
          'text': {
            'format': {
              'type': 'json_schema',
              'name': schema.name,
              'strict': true,
              'schema': schema.definition,
            },
          },
        },
      );

      final responseData = response.data;
      if (responseData == null) {
        return const FailureResult(
          Failure('AI generation failed. Please try again.'),
        );
      }

      final rawJson = _extractJsonText(responseData);
      final normalizedJson = schema.normalize(rawJson);
      final parsed = parser(normalizedJson);
      return Success(parsed);
    } on DioException catch (error) {
      return FailureResult(
        Failure(
          _mapOpenAiError(error),
          code: error.response?.statusCode?.toString(),
        ),
      );
    } on AppException catch (error) {
      return FailureResult(Failure(error.message, code: error.code));
    } catch (_) {
      return const FailureResult(
        Failure('AI generation failed. Please try again.'),
      );
    }
  }

  String _extractJsonText(Map<String, dynamic> responseData) {
    final directText = responseData['output_text'];
    if (directText is String && directText.trim().isNotEmpty) {
      return directText.trim();
    }

    final output = responseData['output'];
    if (output is List<dynamic>) {
      for (final item in output) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final content = item['content'];
        if (content is! List<dynamic>) {
          continue;
        }

        for (final part in content) {
          if (part is! Map<String, dynamic>) {
            continue;
          }

          if (part['type'] == 'output_text') {
            final text = part['text'];
            if (text is String && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }
    }

    throw const AppException(
      'AI response format was invalid.',
      code: 'ai_parse_error',
    );
  }

  String _mapOpenAiError(DioException error) {
    final statusCode = error.response?.statusCode;
    final apiMessage = _readApiErrorMessage(error.response?.data);

    return switch (statusCode) {
      400 => apiMessage.isNotEmpty ? apiMessage : 'Your input is too short.',
      401 || 403 =>
        'OpenAI API key is missing or invalid. Check your local .env file.',
      429 => 'OpenAI request limit reached. Please try again later.',
      _
          when error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout =>
        'Network error. Please check your internet connection.',
      _ =>
        apiMessage.isNotEmpty
            ? apiMessage
            : 'AI generation failed. Please try again.',
    };
  }

  String _readApiErrorMessage(Object? data) {
    if (data is! Map<String, dynamic>) {
      return '';
    }

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String) {
        return message.trim();
      }
    }

    return '';
  }
}

class _AiJsonSchema {
  const _AiJsonSchema({
    required this.name,
    required this.definition,
    this.normalize = _defaultNormalize,
  });

  final String name;
  final Map<String, dynamic> definition;
  final String Function(String rawJson) normalize;

  static String _defaultNormalize(String rawJson) => rawJson;

  static String _normalizeSkillList(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is List<dynamic>) {
      return rawJson;
    }

    if (decoded is Map<String, dynamic>) {
      return jsonEncode(decoded['items'] ?? const []);
    }

    throw const AppException(
      'AI response format was invalid.',
      code: 'ai_parse_error',
    );
  }

  static const textSuggestion = _AiJsonSchema(
    name: 'career_text_suggestion',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'title',
        'originalText',
        'suggestedText',
        'guidancePoints',
        'language',
      ],
      'properties': {
        'title': {'type': 'string'},
        'originalText': {'type': 'string'},
        'suggestedText': {'type': 'string'},
        'guidancePoints': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'language': {
          'type': 'string',
          'enum': ['english', 'bangla'],
        },
      },
    },
  );

  static const skillSuggestions = _AiJsonSchema(
    name: 'career_skill_suggestions',
    normalize: _normalizeSkillList,
    definition: {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['name', 'reason'],
        'properties': {
          'name': {'type': 'string'},
          'reason': {'type': 'string'},
        },
      },
    },
  );

  static const documentDraft = _AiJsonSchema(
    name: 'career_document_draft',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'title',
        'subjectLine',
        'body',
        'highlights',
        'language',
        'tone',
      ],
      'properties': {
        'title': {'type': 'string'},
        'subjectLine': {'type': 'string'},
        'body': {'type': 'string'},
        'highlights': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'language': {
          'type': 'string',
          'enum': ['english', 'bangla'],
        },
        'tone': {
          'type': 'string',
          'enum': ['professional', 'formal', 'simple', 'confident'],
        },
      },
    },
  );

  static const interviewQuestionSet = _AiJsonSchema(
    name: 'career_interview_questions',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['title', 'language', 'questions'],
      'properties': {
        'title': {'type': 'string'},
        'language': {
          'type': 'string',
          'enum': ['english', 'bangla'],
        },
        'questions': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'category',
              'question',
              'whyItMatters',
              'answerTip',
              'sampleAnswer',
            ],
            'properties': {
              'category': {
                'type': 'string',
                'enum': [
                  'hr',
                  'technical',
                  'behavioral',
                  'cv_based',
                  'company_based',
                  'general',
                ],
              },
              'question': {'type': 'string'},
              'whyItMatters': {'type': 'string'},
              'answerTip': {'type': 'string'},
              'sampleAnswer': {'type': 'string'},
            },
          },
        },
      },
    },
  );

  static const atsSuggestionReport = _AiJsonSchema(
    name: 'career_ats_suggestions',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['headline', 'strengths', 'suggestions'],
      'properties': {
        'headline': {'type': 'string'},
        'strengths': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'suggestions': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['title', 'description', 'severity'],
            'properties': {
              'title': {'type': 'string'},
              'description': {'type': 'string'},
              'severity': {
                'type': 'string',
                'enum': ['high', 'medium', 'low'],
              },
            },
          },
        },
      },
    },
  );

  static const jobPostAnalysis = _AiJsonSchema(
    name: 'career_job_post_analysis',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'roleTitle',
        'companyName',
        'summary',
        'requiredSkills',
        'preferredSkills',
        'keywords',
      ],
      'properties': {
        'roleTitle': {'type': 'string'},
        'companyName': {'type': 'string'},
        'summary': {'type': 'string'},
        'requiredSkills': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'preferredSkills': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'keywords': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    },
  );

  static const cvJobMatchResult = _AiJsonSchema(
    name: 'career_cv_job_match',
    definition: {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'matchScore',
        'assessment',
        'matchedSkills',
        'missingSkills',
        'suggestedSummary',
        'priorityActions',
      ],
      'properties': {
        'matchScore': {'type': 'integer'},
        'assessment': {'type': 'string'},
        'matchedSkills': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'missingSkills': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'suggestedSummary': {'type': 'string'},
        'priorityActions': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    },
  );
}
