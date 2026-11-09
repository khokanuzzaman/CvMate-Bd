import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_consent_guard.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';

/// Wraps the real (or mock) [AiCareerService] so every AI entry point gets the
/// same rules in one place:
/// - no consent: the consent sheet; "Not now" means no request is sent;
/// - out of AI actions ([AiFailureCodes.quotaExceeded]): the paywall opens
///   with source `ai_quota` (the caller still gets the failure to show).
class GuardedAiCareerService implements AiCareerService {
  const GuardedAiCareerService({
    required this.inner,
    required this.consentGuard,
    required this.port,
  });

  static const String consentDeclinedMessage =
      'AI features are off. You can turn them on in Settings.';

  final AiCareerService inner;
  final AiConsentGuard consentGuard;
  final AiInteractionPort port;

  Future<Result<T>> _guarded<T>(Future<Result<T>> Function() call) async {
    if (!await consentGuard.ensureConsent()) {
      return const FailureResult(
        Failure(consentDeclinedMessage, code: AiFailureCodes.consentRequired),
      );
    }
    final result = await call();
    if (result case FailureResult(:final error)
        when error.code == AiFailureCodes.quotaExceeded) {
      port.openPaywall('ai_quota');
    }
    return result;
  }

  @override
  Future<Result<AiTextSuggestion>> generateProfessionalSummary({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    return _guarded(
      () => inner.generateProfessionalSummary(
        profile: profile,
        language: language,
        tone: tone,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
      ),
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
    return _guarded(
      () => inner.generateCareerObjective(
        profile: profile,
        language: language,
        tone: tone,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
      ),
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
    return _guarded(
      () => inner.improveExperienceBullet(
        bullet: bullet,
        profile: profile,
        language: language,
        tone: tone,
        companyName: companyName,
        jobTitle: jobTitle,
      ),
    );
  }

  @override
  Future<Result<AiTextSuggestion>> improveProjectDescription({
    required ProjectInfo project,
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) {
    return _guarded(
      () => inner.improveProjectDescription(
        project: project,
        profile: profile,
        language: language,
        tone: tone,
      ),
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
    return _guarded(
      () => inner.suggestSkills(
        profile: profile,
        language: language,
        tone: tone,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
        maxSuggestions: maxSuggestions,
      ),
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
    return _guarded(
      () => inner.generateCoverLetter(
        profile: profile,
        companyName: companyName,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
        hiringManagerName: hiringManagerName,
        candidateSummary: candidateSummary,
        isShortVersion: isShortVersion,
        language: language,
        tone: tone,
      ),
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
    return _guarded(
      () => inner.generateJobApplicationEmail(
        profile: profile,
        companyName: companyName,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
        hiringManagerName: hiringManagerName,
        candidateSummary: candidateSummary,
        language: language,
        tone: tone,
      ),
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
    return _guarded(
      () => inner.generateLinkedInMessage(
        profile: profile,
        companyName: companyName,
        jobTitle: jobTitle,
        jobPostText: jobPostText,
        hiringManagerName: hiringManagerName,
        candidateSummary: candidateSummary,
        language: language,
        tone: tone,
      ),
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
    return _guarded(
      () => inner.generateInterviewQuestions(
        profile: profile,
        language: language,
        jobTitle: jobTitle,
        companyName: companyName,
        jobPostText: jobPostText,
        interviewType: interviewType,
        answerStyle: answerStyle,
      ),
    );
  }

  @override
  Future<Result<AtsSuggestionReport>> generateAtsSuggestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobPostText = '',
  }) {
    return _guarded(
      () => inner.generateAtsSuggestions(
        profile: profile,
        language: language,
        jobPostText: jobPostText,
      ),
    );
  }

  @override
  Future<Result<JobPostAnalysis>> analyzeJobPost({
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    return _guarded(
      () => inner.analyzeJobPost(
        jobPostText: jobPostText,
        language: language,
      ),
    );
  }

  @override
  Future<Result<CvJobMatchResult>> calculateCvJobMatch({
    required CvProfile profile,
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    return _guarded(
      () => inner.calculateCvJobMatch(
        profile: profile,
        jobPostText: jobPostText,
        language: language,
      ),
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
    return _guarded(
      () => inner.tailorCvForJob(
        profile: profile,
        jobPostText: jobPostText,
        jobTitle: jobTitle,
        companyName: companyName,
        targetKeywords: targetKeywords,
        language: language,
        tone: tone,
      ),
    );
  }
}
