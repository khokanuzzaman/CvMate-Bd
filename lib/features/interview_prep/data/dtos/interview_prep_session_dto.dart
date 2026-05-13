import 'dart:convert';

import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class InterviewPrepSessionDto {
  const InterviewPrepSessionDto(this.session);

  final InterviewPrepSession session;

  Map<String, dynamic> toJson() {
    return {
      'id': session.id,
      'cvId': session.cvId,
      'targetJobTitle': session.targetJobTitle,
      'companyName': session.companyName,
      'jobPost': session.jobPost,
      'interviewType': session.interviewType.code,
      'language': session.language.code,
      'answerStyle': session.answerStyle.code,
      'generatedQuestions': session.generatedQuestions
          .map(
            (question) => {
              'id': question.id,
              'category': question.category.code,
              'question': question.question,
              'whyItMatters': question.whyItMatters,
              'answerTip': question.answerTip,
              'answerText': question.answerText,
              'isFavorite': question.isFavorite,
            },
          )
          .toList(),
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
    };
  }

  static InterviewPrepSessionDto fromJson(String rawJson) {
    final map = Map<String, dynamic>.from(_decode(rawJson));
    return InterviewPrepSessionDto(
      InterviewPrepSession(
        id: map['id'] as String? ?? '',
        cvId: map['cvId'] as String?,
        targetJobTitle: map['targetJobTitle'] as String? ?? '',
        companyName: map['companyName'] as String? ?? '',
        jobPost: map['jobPost'] as String? ?? '',
        interviewType: InterviewTypeX.fromCode(
          map['interviewType'] as String? ?? '',
        ),
        language: switch ((map['language'] as String? ?? '').toLowerCase()) {
          'bangla' => AiOutputLanguage.bangla,
          _ => AiOutputLanguage.english,
        },
        answerStyle: InterviewAnswerStyleX.fromCode(
          map['answerStyle'] as String? ?? '',
        ),
        generatedQuestions:
            (map['generatedQuestions'] as List<dynamic>? ?? const [])
                .map(
                  (item) => InterviewPrepQuestion(
                    id: (item as Map<String, dynamic>)['id'] as String? ?? '',
                    category: InterviewQuestionCategoryX.fromCode(
                      item['category'] as String? ?? '',
                    ),
                    question: item['question'] as String? ?? '',
                    whyItMatters: item['whyItMatters'] as String? ?? '',
                    answerTip: item['answerTip'] as String? ?? '',
                    answerText: item['answerText'] as String? ?? '',
                    isFavorite: item['isFavorite'] as bool? ?? false,
                  ),
                )
                .toList(),
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  static dynamic _decode(String rawJson) {
    return rawJson.isEmpty ? <String, dynamic>{} : jsonDecode(rawJson);
  }
}
