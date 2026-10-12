import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';

/// A scripted [AiCareerService] for the tailoring and cover-letter screens:
/// deterministic output shaped like the design mocks, plus a record of the
/// calls it received. Anything else is not expected and throws.
class FakeAiCareerService implements AiCareerService {
  int tailorCalls = 0;
  int coverLetterCalls = 0;
  AiTone? lastCoverLetterTone;
  String? lastCoverLetterCompany;
  String? lastCoverLetterJobTitle;
  String? lastCoverLetterSummary;

  static const String tailoredSummary =
      'Front-end developer focused on building accessible, performant React '
      'and TypeScript interfaces. Comfortable owning features from design '
      'system to shipped UI, working in Agile teams and integrating REST APIs.';

  static const String rewrittenBullet =
      'Rebuilt key screens in React + TypeScript, improving load time by '
      '[add %] and cutting UI bugs.';

  @override
  Future<Result<CvTailoringSuggestion>> tailorCvForJob({
    required CvProfile profile,
    required String jobPostText,
    String jobTitle = '',
    String companyName = '',
    List<String> targetKeywords = const [],
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) async {
    tailorCalls++;
    final experience = profile.experiences.first;
    return Success(
      CvTailoringSuggestion(
        tailoredSummary: tailoredSummary,
        emphasizedSkills: const [
          'TypeScript',
          'Next.js',
          'Accessibility',
          'React',
          'REST API',
          'Git',
        ],
        rewrittenBullets: [
          TailoredBulletSuggestion(
            experienceId: experience.id,
            original: experience.highlights.first,
            suggested: rewrittenBullet,
          ),
        ],
        language: language,
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
  }) async {
    coverLetterCalls++;
    lastCoverLetterTone = tone;
    lastCoverLetterCompany = companyName;
    lastCoverLetterJobTitle = jobTitle;
    lastCoverLetterSummary = candidateSummary;
    return Success(
      AiDocumentDraft(
        title: 'Cover letter',
        subjectLine: '',
        body:
            'Dear Hiring Manager,\n\n'
            "I'm excited to apply for the $jobTitle role at $companyName "
            '(${tone.code} tone). Building accessible, high-performance React '
            'and TypeScript interfaces is exactly the work I enjoy most.\n\n'
            'In my current role I own features end to end and collaborate '
            'closely with designers in an Agile team.\n\n'
            "I'd welcome the chance to talk further.\n"
            'Sincerely,\n'
            '[Your name]',
        highlights: const [],
        language: language,
        tone: tone,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAiCareerService: ${invocation.memberName}');
}
