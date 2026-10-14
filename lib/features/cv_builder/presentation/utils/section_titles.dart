import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';

/// What a section is called on screen unless the user renamed it. (The PDF has
/// its own default wording, kept as it always was.)
String defaultSectionTitle(CvSectionKind kind) => switch (kind) {
  CvSectionKind.summary => AppStrings.previewSummary,
  CvSectionKind.objective => AppStrings.previewObjective,
  CvSectionKind.experience => AppStrings.previewExperience,
  CvSectionKind.skills => AppStrings.previewSkills,
  CvSectionKind.education => AppStrings.previewEducation,
  CvSectionKind.projects => AppStrings.previewProjects,
  CvSectionKind.training => AppStrings.previewTraining,
  CvSectionKind.languages => AppStrings.previewLanguages,
  CvSectionKind.custom => AppStrings.sectionsCustomDefaultTitle,
};
