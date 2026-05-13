enum AtsAiTarget { professionalSummary, careerObjective }

extension AtsAiTargetX on AtsAiTarget {
  String get label => switch (this) {
    AtsAiTarget.professionalSummary => 'Professional Summary',
    AtsAiTarget.careerObjective => 'Career Objective',
  };
}
