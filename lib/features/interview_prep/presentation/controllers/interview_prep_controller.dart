import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final interviewPrepControllerProvider =
    NotifierProvider<InterviewPrepController, InterviewPrepState>(
      InterviewPrepController.new,
    );

class InterviewPrepController extends Notifier<InterviewPrepState> {
  @override
  InterviewPrepState build() => InterviewPrepState.initial();

  Future<void> initialize({bool force = false}) async {
    if (state.hasInitialized && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final sessions = await ref
          .read(interviewPrepSessionRepositoryProvider)
          .getAllSessions();
      final activeBuilderState = ref.read(cvBuilderControllerProvider);
      final activeCvId = activeBuilderState.hasActiveDraft
          ? activeBuilderState.draft.id
          : null;
      final nextSelectedCvId = _resolveSelectedCvId(
        cvs: cvs,
        preferredCvId: state.selectedCvId,
        activeBuilderCvId: activeCvId,
      );
      final selectedCv = _findCv(cvs, nextSelectedCvId);

      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        availableCvs: cvs,
        recentSessions: sessions,
        selectedCvId: nextSelectedCvId,
        targetJobTitle: state.targetJobTitle.trim().isNotEmpty
            ? state.targetJobTitle
            : (selectedCv?.personalInfo.desiredRole ?? ''),
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        errorMessage: 'Could not load interview preparation data.',
      );
    }
  }

  Future<void> reload() => initialize(force: true);

  void selectCv(String? cvId) {
    if (cvId == state.selectedCvId) {
      return;
    }

    final nextCv = _findCv(state.availableCvs, cvId);
    state = state.copyWith(
      selectedCvId: cvId,
      targetJobTitle: state.targetJobTitle.trim().isNotEmpty
          ? state.targetJobTitle
          : (nextCv?.personalInfo.desiredRole ?? ''),
      clearErrorMessage: true,
    );
  }

  void updateTargetJobTitle(String value) {
    if (value == state.targetJobTitle) {
      return;
    }
    state = state.copyWith(targetJobTitle: value, clearErrorMessage: true);
  }

  void updateCompanyName(String value) {
    if (value == state.companyName) {
      return;
    }
    state = state.copyWith(companyName: value, clearErrorMessage: true);
  }

  void updateJobPostText(String value) {
    if (value == state.jobPostText) {
      return;
    }
    state = state.copyWith(jobPostText: value, clearErrorMessage: true);
  }

  void selectInterviewType(InterviewType value) {
    if (value == state.interviewType) {
      return;
    }
    state = state.copyWith(interviewType: value, clearErrorMessage: true);
  }

  void selectLanguage(AiOutputLanguage value) {
    if (value == state.language) {
      return;
    }
    state = state.copyWith(language: value, clearErrorMessage: true);
  }

  void selectAnswerStyle(InterviewAnswerStyle value) {
    if (value == state.answerStyle) {
      return;
    }
    state = state.copyWith(answerStyle: value, clearErrorMessage: true);
  }

  void updateAnswer(String questionId, String value) {
    state = state.copyWith(
      questions: [
        for (final question in state.questions)
          if (question.id == questionId)
            question.copyWith(answerText: value)
          else
            question,
      ],
      clearErrorMessage: true,
    );
  }

  void toggleFavorite(String questionId) {
    state = state.copyWith(
      questions: [
        for (final question in state.questions)
          if (question.id == questionId)
            question.copyWith(isFavorite: !question.isFavorite)
          else
            question,
      ],
      clearErrorMessage: true,
    );
  }

  Future<void> generateQuestions() async {
    final profile = _buildGenerationProfile();
    if (profile == null) {
      state = state.copyWith(
        errorMessage:
            'Select a CV or enter at least a target role before generating questions.',
      );
      return;
    }

    state = state.copyWith(isGenerating: true, clearErrorMessage: true);

    final result = await ref
        .read(aiCareerServiceProvider)
        .generateInterviewQuestions(
          profile: profile,
          language: state.language,
          jobTitle: state.targetJobTitle.trim(),
          companyName: state.companyName.trim(),
          jobPostText: state.jobPostText.trim(),
          interviewType: state.interviewType.label,
          answerStyle: state.answerStyle.label,
        );

    result.when(
      success: (data) {
        final nowSeed = DateTime.now().microsecondsSinceEpoch;
        final questions = <InterviewPrepQuestion>[
          for (var index = 0; index < data.questions.length; index++)
            InterviewPrepQuestion(
              id: '${nowSeed}_$index',
              category: InterviewQuestionCategoryX.fromCode(
                data.questions[index].category,
              ),
              question: data.questions[index].question,
              whyItMatters: data.questions[index].whyItMatters,
              answerTip: data.questions[index].answerTip,
              answerText: data.questions[index].sampleAnswer,
              isFavorite: false,
            ),
        ];

        state = state.copyWith(
          isGenerating: false,
          questions: questions,
          clearErrorMessage: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<String?> copyQuestion(String questionId) async {
    final question = _findQuestion(questionId);
    if (question == null) {
      return 'Question not found.';
    }

    await Clipboard.setData(ClipboardData(text: question.question));
    return 'Question copied.';
  }

  Future<String?> copyAnswer(String questionId) async {
    final question = _findQuestion(questionId);
    if (question == null || question.answerText.trim().isEmpty) {
      return 'Answer not ready yet.';
    }

    await Clipboard.setData(ClipboardData(text: question.answerText.trim()));
    return 'Answer copied.';
  }

  Future<String?> copyAllQuestions() async {
    if (state.questions.isEmpty) {
      return 'Generate interview questions first.';
    }

    final text = state.questions.map((item) => '- ${item.question}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    return 'All questions copied.';
  }

  Future<String?> copyAllAnswers() async {
    if (state.questions.isEmpty) {
      return 'Generate interview questions first.';
    }

    final text = state.questions
        .map((item) => '${item.question}\n${item.answerText.trim()}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    return 'All answers copied.';
  }

  Future<String?> saveSession() async {
    if (state.questions.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Generate interview questions first before saving.',
      );
      return state.errorMessage;
    }

    state = state.copyWith(isSavingSession: true, clearErrorMessage: true);
    final wasEditing = state.isEditingSession;

    try {
      final now = DateTime.now();
      final session = InterviewPrepSession(
        id: state.activeSessionId ?? now.microsecondsSinceEpoch.toString(),
        cvId: state.selectedCvId,
        targetJobTitle: state.targetJobTitle.trim(),
        companyName: state.companyName.trim(),
        jobPost: state.jobPostText.trim(),
        interviewType: state.interviewType,
        language: state.language,
        answerStyle: state.answerStyle,
        generatedQuestions: state.questions,
        createdAt: state.activeSessionCreatedAt ?? now,
        updatedAt: now,
      );
      final saved = await ref
          .read(interviewPrepSessionRepositoryProvider)
          .saveSession(session);
      final nextSessions = [
        for (final item in state.recentSessions)
          if (item.id != saved.id) item,
        saved,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        isSavingSession: false,
        recentSessions: nextSessions,
        activeSessionId: saved.id,
        activeSessionCreatedAt: saved.createdAt,
        clearErrorMessage: true,
      );
      return wasEditing
          ? 'Interview prep session updated.'
          : 'Interview prep session saved.';
    } catch (_) {
      state = state.copyWith(
        isSavingSession: false,
        errorMessage: 'Could not save this interview prep session.',
      );
      return state.errorMessage;
    }
  }

  void loadSession(String sessionId) {
    InterviewPrepSession? session;
    for (final item in state.recentSessions) {
      if (item.id == sessionId) {
        session = item;
        break;
      }
    }

    if (session == null) {
      state = state.copyWith(
        errorMessage: 'Could not open this saved interview prep session.',
      );
      return;
    }

    state = state.copyWith(
      activeSessionId: session.id,
      activeSessionCreatedAt: session.createdAt,
      selectedCvId: _findCv(state.availableCvs, session.cvId)?.id,
      targetJobTitle: session.targetJobTitle,
      companyName: session.companyName,
      jobPostText: session.jobPost,
      interviewType: session.interviewType,
      language: session.language,
      answerStyle: session.answerStyle,
      questions: session.generatedQuestions,
      clearErrorMessage: true,
    );
  }

  void startOver() {
    final selectedCv = state.selectedCv;
    state = state.copyWith(
      activeSessionId: null,
      activeSessionCreatedAt: null,
      targetJobTitle: selectedCv?.personalInfo.desiredRole ?? '',
      companyName: '',
      jobPostText: '',
      interviewType: InterviewType.hrInterview,
      language: AiOutputLanguage.english,
      answerStyle: InterviewAnswerStyle.professional,
      questions: const [],
      clearErrorMessage: true,
    );
  }

  CvProfile? _buildGenerationProfile() {
    final selectedCv = state.selectedCv;
    if (selectedCv != null) {
      return selectedCv;
    }

    final role = state.targetJobTitle.trim();
    final jobPost = state.jobPostText.trim();
    if (role.isEmpty && jobPost.isEmpty) {
      return null;
    }

    return CvProfile.empty().copyWith(
      title: role.isEmpty ? 'Manual Interview Prep' : role,
      personalInfo: PersonalInfo(
        desiredRole: role,
        fullName: '',
        email: '',
        phone: '',
      ),
      professionalSummary: '',
      careerObjective: '',
    );
  }

  CvProfile? _findCv(List<CvProfile> cvs, String? id) {
    if (id == null) {
      return null;
    }

    for (final cv in cvs) {
      if (cv.id == id) {
        return cv;
      }
    }
    return null;
  }

  String? _resolveSelectedCvId({
    required List<CvProfile> cvs,
    required String? preferredCvId,
    required String? activeBuilderCvId,
  }) {
    if (preferredCvId != null && _findCv(cvs, preferredCvId) != null) {
      return preferredCvId;
    }
    if (activeBuilderCvId != null && _findCv(cvs, activeBuilderCvId) != null) {
      return activeBuilderCvId;
    }
    return cvs.isEmpty ? null : cvs.first.id;
  }

  InterviewPrepQuestion? _findQuestion(String id) {
    for (final question in state.questions) {
      if (question.id == id) {
        return question;
      }
    }
    return null;
  }
}
