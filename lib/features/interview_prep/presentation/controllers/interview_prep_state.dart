import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

const Object _interviewPrepUnset = Object();

class InterviewPrepState {
  const InterviewPrepState({
    required this.hasInitialized,
    required this.isLoading,
    required this.isGenerating,
    required this.isSavingSession,
    required this.availableCvs,
    required this.recentSessions,
    required this.activeSessionId,
    required this.activeSessionCreatedAt,
    required this.selectedCvId,
    required this.targetJobTitle,
    required this.companyName,
    required this.jobPostText,
    required this.interviewType,
    required this.language,
    required this.answerStyle,
    required this.questions,
    required this.errorMessage,
  });

  factory InterviewPrepState.initial() => const InterviewPrepState(
    hasInitialized: false,
    isLoading: false,
    isGenerating: false,
    isSavingSession: false,
    availableCvs: [],
    recentSessions: [],
    activeSessionId: null,
    activeSessionCreatedAt: null,
    selectedCvId: null,
    targetJobTitle: '',
    companyName: '',
    jobPostText: '',
    interviewType: InterviewType.hrInterview,
    language: AiOutputLanguage.english,
    answerStyle: InterviewAnswerStyle.professional,
    questions: [],
    errorMessage: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final bool isGenerating;
  final bool isSavingSession;
  final List<CvProfile> availableCvs;
  final List<InterviewPrepSession> recentSessions;
  final String? activeSessionId;
  final DateTime? activeSessionCreatedAt;
  final String? selectedCvId;
  final String targetJobTitle;
  final String companyName;
  final String jobPostText;
  final InterviewType interviewType;
  final AiOutputLanguage language;
  final InterviewAnswerStyle answerStyle;
  final List<InterviewPrepQuestion> questions;
  final String? errorMessage;

  CvProfile? get selectedCv {
    final id = selectedCvId;
    if (id == null) {
      return null;
    }

    for (final profile in availableCvs) {
      if (profile.id == id) {
        return profile;
      }
    }

    return null;
  }

  bool get hasSavedCvs => availableCvs.isNotEmpty;
  bool get hasRecentSessions => recentSessions.isNotEmpty;
  bool get hasGeneratedQuestions => questions.isNotEmpty;
  bool get isEditingSession => activeSessionId != null;
  bool get canGenerate =>
      selectedCv != null ||
      targetJobTitle.trim().isNotEmpty ||
      jobPostText.trim().isNotEmpty;

  InterviewPrepState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    bool? isGenerating,
    bool? isSavingSession,
    List<CvProfile>? availableCvs,
    List<InterviewPrepSession>? recentSessions,
    Object? activeSessionId = _interviewPrepUnset,
    Object? activeSessionCreatedAt = _interviewPrepUnset,
    Object? selectedCvId = _interviewPrepUnset,
    String? targetJobTitle,
    String? companyName,
    String? jobPostText,
    InterviewType? interviewType,
    AiOutputLanguage? language,
    InterviewAnswerStyle? answerStyle,
    List<InterviewPrepQuestion>? questions,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return InterviewPrepState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isSavingSession: isSavingSession ?? this.isSavingSession,
      availableCvs: availableCvs ?? this.availableCvs,
      recentSessions: recentSessions ?? this.recentSessions,
      activeSessionId: identical(activeSessionId, _interviewPrepUnset)
          ? this.activeSessionId
          : activeSessionId as String?,
      activeSessionCreatedAt:
          identical(activeSessionCreatedAt, _interviewPrepUnset)
          ? this.activeSessionCreatedAt
          : activeSessionCreatedAt as DateTime?,
      selectedCvId: identical(selectedCvId, _interviewPrepUnset)
          ? this.selectedCvId
          : selectedCvId as String?,
      targetJobTitle: targetJobTitle ?? this.targetJobTitle,
      companyName: companyName ?? this.companyName,
      jobPostText: jobPostText ?? this.jobPostText,
      interviewType: interviewType ?? this.interviewType,
      language: language ?? this.language,
      answerStyle: answerStyle ?? this.answerStyle,
      questions: questions ?? this.questions,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
