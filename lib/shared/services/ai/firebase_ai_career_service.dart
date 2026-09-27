import 'dart:convert';

import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:cloud_functions/cloud_functions.dart' as cloud_functions;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseFunctionsProvider = Provider<cloud_functions.FirebaseFunctions>((
  ref,
) {
  return cloud_functions.FirebaseFunctions.instanceFor(
    region: EnvConfig.firebaseFunctionsRegion,
  );
});

final firebaseAiCareerServiceProvider = Provider<FirebaseAiCareerService>((
  ref,
) {
  return FirebaseAiCareerService(
    functions: ref.watch(firebaseFunctionsProvider),
    responseParser: const AiResponseParser(),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class FirebaseAiCareerService implements AiCareerService {
  const FirebaseAiCareerService({
    required this.functions,
    required this.responseParser,
    required this.authRepository,
  });

  final cloud_functions.FirebaseFunctions functions;
  final AiResponseParser responseParser;
  final AuthRepository authRepository;

  static const String _callableName = 'generateCareerAiContent';

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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
      cvData: _serializeCvProfile(profile),
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
    Map<String, dynamic>? cvData,
    String inputText = '',
    String jobPost = '',
    Map<String, dynamic>? metadata,
  }) async {
    if (authRepository.currentUser == null) {
      return const FailureResult(
        Failure('Please login to use AI features.', code: 'ai_auth_required'),
      );
    }

    try {
      final callable = functions.httpsCallable(_callableName);
      final payload = <String, dynamic>{
        'action': action,
        'language': language.code,
        'tone': tone.code,
      };
      if (cvData != null) {
        payload['cvData'] = cvData;
      }
      if (inputText.trim().isNotEmpty) {
        payload['inputText'] = inputText.trim();
      }
      if (jobPost.trim().isNotEmpty) {
        payload['jobPost'] = jobPost.trim();
      }
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }

      final result = await callable.call(payload);

      final responsePayload = result.data;
      if (responsePayload is! Map) {
        return const FailureResult(
          Failure('AI generation failed. Please try again.'),
        );
      }

      final map = Map<String, dynamic>.from(responsePayload);
      if (map['success'] != true) {
        final errorMessage = _readString(
          map['error'],
          fallback: 'AI generation failed. Please try again.',
        );
        return FailureResult(Failure(errorMessage));
      }

      final content = map['content'];
      if (content == null) {
        return const FailureResult(
          Failure('AI generation failed. Please try again.'),
        );
      }

      final rawContent = jsonEncode(content);
      final parsed = parser(rawContent);
      return Success(parsed);
    } on cloud_functions.FirebaseFunctionsException catch (error) {
      return FailureResult(Failure(_mapCallableError(error), code: error.code));
    } on AppException catch (error) {
      return FailureResult(Failure(error.message, code: error.code));
    } catch (_) {
      return const FailureResult(
        Failure('AI generation failed. Please try again.'),
      );
    }
  }

  String _mapCallableError(cloud_functions.FirebaseFunctionsException error) {
    final message = (error.message ?? '').trim();
    return switch (error.code) {
      'unauthenticated' => 'Please login to use AI features.',
      'invalid-argument' =>
        message.isEmpty ? 'Your input is too short.' : message,
      'permission-denied' => 'Please login to use AI features.',
      _ =>
        message.isEmpty ? 'AI generation failed. Please try again.' : message,
    };
  }

  String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  Map<String, dynamic> _serializeCvProfile(CvProfile profile) {
    return {
      'title': profile.title.trim(),
      'desiredRole': profile.personalInfo.desiredRole.trim(),
      'professionalSummary': profile.professionalSummary.trim(),
      'careerObjective': profile.careerObjective.trim(),
      'education': [
        for (final education in profile.education)
          {
            'institution': education.institution.trim(),
            'degree': education.degree.trim(),
            'fieldOfStudy': education.fieldOfStudy.trim(),
            'result': education.result.trim(),
            'startYear': education.startYear.trim(),
            'endYear': education.endYear.trim(),
          },
      ],
      'experiences': [
        for (final experience in profile.experiences)
          {
            'companyName': experience.companyName.trim(),
            'jobTitle': experience.jobTitle.trim(),
            'startDate': experience.startDate.trim(),
            'endDate': experience.endDate.trim(),
            'isCurrentRole': experience.isCurrentRole,
            'highlights': experience.highlights
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
          },
      ],
      'skills': [
        for (final skill in profile.skills)
          {'name': skill.name.trim(), 'level': skill.level.trim()},
      ],
      'projects': [
        for (final project in profile.projects)
          {
            'title': project.title.trim(),
            'role': project.role.trim(),
            'description': project.description.trim(),
            'technologies': project.technologies
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
          },
      ],
      'trainings': [
        for (final training in profile.trainings)
          {
            'title': training.title.trim(),
            'organization': training.organization.trim(),
            'completionYear': training.completionYear.trim(),
            'details': training.details.trim(),
          },
      ],
      'languages': [
        for (final language in profile.languages)
          {
            'name': language.name.trim(),
            'proficiency': language.proficiency.trim(),
          },
      ],
    };
  }
}
