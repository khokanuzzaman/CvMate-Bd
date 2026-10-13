import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';

/// The builder step an ATS issue's "Fix" button opens.
///
/// Thin-section and length issues are filed under `formatting`; they are
/// resolved by adding role-relevant detail, so they land on Experience.
CvBuilderStep atsFixStep(AtsCheckCategory category) => switch (category) {
  AtsCheckCategory.contact => CvBuilderStep.personalInfo,
  AtsCheckCategory.summary => CvBuilderStep.summaryObjective,
  AtsCheckCategory.education => CvBuilderStep.education,
  AtsCheckCategory.experience => CvBuilderStep.experience,
  AtsCheckCategory.skills => CvBuilderStep.skills,
  AtsCheckCategory.projects => CvBuilderStep.projects,
  AtsCheckCategory.formatting => CvBuilderStep.experience,
  AtsCheckCategory.jobMatch => CvBuilderStep.summaryObjective,
};
