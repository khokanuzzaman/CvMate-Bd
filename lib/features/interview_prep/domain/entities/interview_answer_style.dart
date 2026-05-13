enum InterviewAnswerStyle { short, professional, detailed }

extension InterviewAnswerStyleX on InterviewAnswerStyle {
  String get code => switch (this) {
    InterviewAnswerStyle.short => 'short',
    InterviewAnswerStyle.professional => 'professional',
    InterviewAnswerStyle.detailed => 'detailed',
  };

  String get label => switch (this) {
    InterviewAnswerStyle.short => 'Short',
    InterviewAnswerStyle.professional => 'Professional',
    InterviewAnswerStyle.detailed => 'Detailed',
  };

  static InterviewAnswerStyle fromCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'short' => InterviewAnswerStyle.short,
      'detailed' => InterviewAnswerStyle.detailed,
      _ => InterviewAnswerStyle.professional,
    };
  }
}
