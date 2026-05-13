import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';

class InterviewPrepQuestion {
  const InterviewPrepQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.whyItMatters,
    required this.answerTip,
    required this.answerText,
    required this.isFavorite,
  });

  final String id;
  final InterviewQuestionCategory category;
  final String question;
  final String whyItMatters;
  final String answerTip;
  final String answerText;
  final bool isFavorite;

  InterviewPrepQuestion copyWith({
    String? id,
    InterviewQuestionCategory? category,
    String? question,
    String? whyItMatters,
    String? answerTip,
    String? answerText,
    bool? isFavorite,
  }) {
    return InterviewPrepQuestion(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      answerTip: answerTip ?? this.answerTip,
      answerText: answerText ?? this.answerText,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
