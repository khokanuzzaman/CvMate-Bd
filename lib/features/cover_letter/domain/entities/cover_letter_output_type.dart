enum CoverLetterOutputType {
  formalCoverLetter,
  shortCoverLetter,
  jobApplicationEmail,
  linkedInMessage,
}

extension CoverLetterOutputTypeX on CoverLetterOutputType {
  String get label => switch (this) {
    CoverLetterOutputType.formalCoverLetter => 'Formal Cover Letter',
    CoverLetterOutputType.shortCoverLetter => 'Short Cover Letter',
    CoverLetterOutputType.jobApplicationEmail => 'Job Application Email',
    CoverLetterOutputType.linkedInMessage => 'LinkedIn Message',
  };

  String get description => switch (this) {
    CoverLetterOutputType.formalCoverLetter =>
      'A full formal letter for direct job applications.',
    CoverLetterOutputType.shortCoverLetter =>
      'A shorter letter for quick applications and fresher-friendly outreach.',
    CoverLetterOutputType.jobApplicationEmail =>
      'A concise email body with subject line for CV submissions.',
    CoverLetterOutputType.linkedInMessage =>
      'A short professional networking or outreach message.',
  };

  bool get showsSubjectLine => switch (this) {
    CoverLetterOutputType.formalCoverLetter => false,
    CoverLetterOutputType.shortCoverLetter => false,
    CoverLetterOutputType.jobApplicationEmail => true,
    CoverLetterOutputType.linkedInMessage => false,
  };
}
