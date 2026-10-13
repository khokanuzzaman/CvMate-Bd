import 'package:careermatebd/core/errors/failure.dart';
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
  CvProfile? lastCoverLetterProfile;

  /// When set, [tailorCvForJob] fails with it.
  Failure? tailorFailure;

  /// When set, [generateCoverLetter] fails with it.
  Failure? coverLetterFailure;

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
    if (tailorFailure != null) {
      return FailureResult(tailorFailure!);
    }
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
    if (coverLetterFailure != null) {
      return FailureResult(coverLetterFailure!);
    }
    lastCoverLetterTone = tone;
    lastCoverLetterCompany = companyName;
    lastCoverLetterJobTitle = jobTitle;
    lastCoverLetterSummary = candidateSummary;
    lastCoverLetterProfile = profile;
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

  /// What [generateInterviewQuestions] returns; tests may replace it.
  List<InterviewQuestionItem> interviewQuestions = const [
    InterviewQuestionItem(
      category: 'technical',
      question:
          'How did you improve load time when you rebuilt screens in '
          'React?',
      whyItMatters: 'Shows how you measure and improve performance.',
      answerTip: 'Name one change and the result.',
      sampleAnswer:
          'Situation: Key screens were slow on mobile. Task: Make them '
          'faster. Action: Split bundles, memoized lists. Result: [add your '
          'number].',
    ),
    InterviewQuestionItem(
      category: 'behavioral',
      question: 'Tell me about a time you disagreed with a designer.',
      whyItMatters: 'Tests collaboration and communication.',
      answerTip: 'Focus on how you reached a decision together.',
      sampleAnswer: 'I walked through the trade-offs with the designer.',
    ),
    InterviewQuestionItem(
      category: 'hr',
      question: 'Why do you want to work at Acme?',
      whyItMatters: 'Checks that your goals fit the employer.',
      answerTip: 'Connect the role to your skills and motivation.',
      sampleAnswer: 'The role matches the work I have been preparing for.',
    ),
  ];

  /// When set, [generateInterviewQuestions] fails with it.
  Failure? interviewFailure;

  int interviewCalls = 0;
  AiOutputLanguage? lastInterviewLanguage;

  @override
  Future<Result<InterviewQuestionSet>> generateInterviewQuestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobTitle = '',
    String companyName = '',
    String jobPostText = '',
    String interviewType = '',
    String answerStyle = '',
  }) async {
    interviewCalls++;
    lastInterviewLanguage = language;
    if (interviewFailure != null) {
      return FailureResult(interviewFailure!);
    }
    final bangla = language == AiOutputLanguage.bangla;
    return Success(
      InterviewQuestionSet(
        title: 'Interview prep',
        language: language,
        questions: [
          for (final item in interviewQuestions)
            InterviewQuestionItem(
              category: item.category,
              question: bangla ? '[bn] ${item.question}' : item.question,
              whyItMatters: item.whyItMatters,
              answerTip: item.answerTip,
              sampleAnswer: item.sampleAnswer,
            ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAiCareerService: ${invocation.memberName}');
}
