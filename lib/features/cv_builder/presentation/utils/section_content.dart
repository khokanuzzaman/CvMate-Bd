import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';

/// Whether the CV has anything to show in [section] (used to tag empty
/// sections on the Sections screen; renderers skip empty sections anyway).
bool sectionHasContent(CvProfile profile, CvSection section) {
  return switch (section.config.kind) {
    CvSectionKind.summary => profile.professionalSummary.trim().isNotEmpty,
    CvSectionKind.objective => profile.careerObjective.trim().isNotEmpty,
    CvSectionKind.education => profile.education.isNotEmpty,
    CvSectionKind.experience => profile.experiences.isNotEmpty,
    CvSectionKind.skills => profile.skills.isNotEmpty,
    CvSectionKind.projects => profile.projects.isNotEmpty,
    CvSectionKind.training => profile.trainings.isNotEmpty,
    CvSectionKind.languages => profile.languages.isNotEmpty,
    CvSectionKind.custom => section.custom?.hasContent ?? false,
  };
}
