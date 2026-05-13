enum AtsCheckCategory {
  contact,
  summary,
  experience,
  skills,
  education,
  projects,
  formatting,
  jobMatch,
}

extension AtsCheckCategoryX on AtsCheckCategory {
  String get label => switch (this) {
    AtsCheckCategory.contact => 'Contact',
    AtsCheckCategory.summary => 'Summary',
    AtsCheckCategory.experience => 'Experience',
    AtsCheckCategory.skills => 'Skills',
    AtsCheckCategory.education => 'Education',
    AtsCheckCategory.projects => 'Projects',
    AtsCheckCategory.formatting => 'Formatting',
    AtsCheckCategory.jobMatch => 'Job Match',
  };
}
