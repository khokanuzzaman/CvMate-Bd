enum CvBuilderStep {
  personalInfo,
  summaryObjective,
  education,
  experience,
  skills,
  projects,
  training,
  languages,
  template,
  preview,
}

extension CvBuilderStepX on CvBuilderStep {
  String get title => switch (this) {
    CvBuilderStep.personalInfo => 'Personal Info',
    CvBuilderStep.summaryObjective => 'Summary / Objective',
    CvBuilderStep.education => 'Education',
    CvBuilderStep.experience => 'Experience',
    CvBuilderStep.skills => 'Skills',
    CvBuilderStep.projects => 'Projects',
    CvBuilderStep.training => 'Training / Certifications',
    CvBuilderStep.languages => 'Languages',
    CvBuilderStep.template => 'Template',
    CvBuilderStep.preview => 'Preview',
  };

  String get description => switch (this) {
    CvBuilderStep.personalInfo =>
      'Add the contact details recruiters should see first.',
    CvBuilderStep.summaryObjective =>
      'Write a short summary and a clear career objective.',
    CvBuilderStep.education =>
      'Education is especially important for fresh graduates.',
    CvBuilderStep.experience =>
      'Add experience if you have it. Freshers can skip this step.',
    CvBuilderStep.skills =>
      'List practical, job-relevant skills for ATS-friendly scanning.',
    CvBuilderStep.projects =>
      'Highlight projects to show proof of work, especially for freshers.',
    CvBuilderStep.training =>
      'Include certifications, bootcamps, or short trainings if relevant.',
    CvBuilderStep.languages =>
      'Mention Bangla, English, or other working languages clearly.',
    CvBuilderStep.template => 'Choose a clean CV layout before final review.',
    CvBuilderStep.preview =>
      'Review the full CV structure before export is added later.',
  };

  bool get isPreview => this == CvBuilderStep.preview;
}
