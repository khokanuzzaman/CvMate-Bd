enum InterviewType {
  hrInterview,
  technicalInterview,
  behavioralInterview,
  fresherInterview,
  finalInterview,
}

extension InterviewTypeX on InterviewType {
  String get code => switch (this) {
    InterviewType.hrInterview => 'hr_interview',
    InterviewType.technicalInterview => 'technical_interview',
    InterviewType.behavioralInterview => 'behavioral_interview',
    InterviewType.fresherInterview => 'fresher_interview',
    InterviewType.finalInterview => 'final_interview',
  };

  String get label => switch (this) {
    InterviewType.hrInterview => 'HR Interview',
    InterviewType.technicalInterview => 'Technical Interview',
    InterviewType.behavioralInterview => 'Behavioral Interview',
    InterviewType.fresherInterview => 'Fresher Interview',
    InterviewType.finalInterview => 'Final Interview',
  };

  static InterviewType fromCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'technical_interview' => InterviewType.technicalInterview,
      'behavioral_interview' => InterviewType.behavioralInterview,
      'fresher_interview' => InterviewType.fresherInterview,
      'final_interview' => InterviewType.finalInterview,
      _ => InterviewType.hrInterview,
    };
  }
}
