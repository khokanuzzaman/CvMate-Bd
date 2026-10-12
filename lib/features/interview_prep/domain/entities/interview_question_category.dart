enum InterviewQuestionCategory {
  hr,
  technical,
  behavioral,
  cvBased,
  companyBased,
  general,
}

extension InterviewQuestionCategoryX on InterviewQuestionCategory {
  String get code => switch (this) {
    InterviewQuestionCategory.hr => 'hr',
    InterviewQuestionCategory.technical => 'technical',
    InterviewQuestionCategory.behavioral => 'behavioral',
    InterviewQuestionCategory.cvBased => 'cv_based',
    InterviewQuestionCategory.companyBased => 'company_based',
    InterviewQuestionCategory.general => 'general',
  };

  String get label => switch (this) {
    InterviewQuestionCategory.hr => 'HR Questions',
    InterviewQuestionCategory.technical => 'Role / Technical Questions',
    InterviewQuestionCategory.behavioral => 'Behavioral Questions',
    InterviewQuestionCategory.cvBased => 'CV-based Questions',
    InterviewQuestionCategory.companyBased => 'Company / Job-post Questions',
    InterviewQuestionCategory.general => 'General Questions',
  };

  /// Short name for filter chips and question labels.
  String get shortLabel => switch (this) {
    InterviewQuestionCategory.hr => 'HR',
    InterviewQuestionCategory.technical => 'Technical',
    InterviewQuestionCategory.behavioral => 'Behavioral',
    InterviewQuestionCategory.cvBased => 'CV-based',
    InterviewQuestionCategory.companyBased => 'Company',
    InterviewQuestionCategory.general => 'General',
  };

  static InterviewQuestionCategory fromCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'hr' => InterviewQuestionCategory.hr,
      'technical' => InterviewQuestionCategory.technical,
      'behavioral' => InterviewQuestionCategory.behavioral,
      'cv_based' => InterviewQuestionCategory.cvBased,
      'company_based' => InterviewQuestionCategory.companyBased,
      _ => InterviewQuestionCategory.general,
    };
  }
}
