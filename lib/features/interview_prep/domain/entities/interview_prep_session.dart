import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class InterviewPrepSession {
  const InterviewPrepSession({
    required this.id,
    required this.cvId,
    required this.targetJobTitle,
    required this.companyName,
    required this.jobPost,
    required this.interviewType,
    required this.language,
    required this.answerStyle,
    required this.generatedQuestions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? cvId;
  final String targetJobTitle;
  final String companyName;
  final String jobPost;
  final InterviewType interviewType;
  final AiOutputLanguage language;
  final InterviewAnswerStyle answerStyle;
  final List<InterviewPrepQuestion> generatedQuestions;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    final role = targetJobTitle.trim();
    if (role.isNotEmpty) {
      return role;
    }
    return interviewType.label;
  }

  String get displaySubtitle {
    final company = companyName.trim();
    if (company.isNotEmpty) {
      return '$company • ${interviewType.label}';
    }
    return interviewType.label;
  }

  InterviewPrepSession copyWith({
    String? id,
    Object? cvId = _unsetValue,
    String? targetJobTitle,
    String? companyName,
    String? jobPost,
    InterviewType? interviewType,
    AiOutputLanguage? language,
    InterviewAnswerStyle? answerStyle,
    List<InterviewPrepQuestion>? generatedQuestions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterviewPrepSession(
      id: id ?? this.id,
      cvId: identical(cvId, _unsetValue) ? this.cvId : cvId as String?,
      targetJobTitle: targetJobTitle ?? this.targetJobTitle,
      companyName: companyName ?? this.companyName,
      jobPost: jobPost ?? this.jobPost,
      interviewType: interviewType ?? this.interviewType,
      language: language ?? this.language,
      answerStyle: answerStyle ?? this.answerStyle,
      generatedQuestions: generatedQuestions ?? this.generatedQuestions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const Object _unsetValue = Object();
