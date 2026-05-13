enum AiImproveType {
  professionalSummary,
  careerObjective,
  experienceBullet,
  projectDescription,
  skillsSuggestion,
}

extension AiImproveTypeX on AiImproveType {
  String get label => switch (this) {
    AiImproveType.professionalSummary => 'Professional Summary',
    AiImproveType.careerObjective => 'Career Objective',
    AiImproveType.experienceBullet => 'Experience Bullet',
    AiImproveType.projectDescription => 'Project Description',
    AiImproveType.skillsSuggestion => 'Skills Suggestion',
  };

  String get description => switch (this) {
    AiImproveType.professionalSummary =>
      'Rewrite the top summary for a more professional and ATS-friendly first impression.',
    AiImproveType.careerObjective =>
      'Sharpen the career objective with clearer direction and stronger wording.',
    AiImproveType.experienceBullet =>
      'Improve one experience bullet with stronger action verbs and clearer impact.',
    AiImproveType.projectDescription =>
      'Make a project description more professional, readable, and role-relevant.',
    AiImproveType.skillsSuggestion =>
      'Generate role-relevant skill ideas and add selected ones back to the CV.',
  };

  String get inputLabel => switch (this) {
    AiImproveType.professionalSummary => 'Current summary',
    AiImproveType.careerObjective => 'Current objective',
    AiImproveType.experienceBullet => 'Current bullet',
    AiImproveType.projectDescription => 'Current project description',
    AiImproveType.skillsSuggestion => 'Role or job context',
  };

  String get outputLabel => switch (this) {
    AiImproveType.skillsSuggestion => 'Suggested skills',
    _ => 'AI suggestion',
  };

  String get emptyRequirementMessage => switch (this) {
    AiImproveType.professionalSummary =>
      'The selected CV is ready for summary improvement.',
    AiImproveType.careerObjective =>
      'The selected CV is ready for objective improvement.',
    AiImproveType.experienceBullet =>
      'Add at least one experience entry in the CV builder to improve an experience bullet.',
    AiImproveType.projectDescription =>
      'Add at least one project entry in the CV builder to improve a project description.',
    AiImproveType.skillsSuggestion =>
      'The selected CV is ready for skill suggestions.',
  };

  bool get needsExperienceSelection => this == AiImproveType.experienceBullet;
  bool get needsProjectSelection => this == AiImproveType.projectDescription;
  bool get isSkillsSuggestion => this == AiImproveType.skillsSuggestion;
}
