import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';

/// The builder as the approved design presents it: an ordered list of pages,
/// each editing one or more of the existing [CvBuilderStep]s.
///
/// This is a presentation-level mapping only. The controller still owns the
/// current step, validation and persistence; the UI navigates by calling
/// `goToStep(page.entryStep.index)` and validates with `validateStep`.
///
/// The design shows six pages; the app also has a Training / Certifications
/// step the design omits, which is kept as its own page before the summary so
/// no data field is lost. Template and Preview are no longer builder pages:
/// the template is chosen from the preview screen, and the last page opens it.
enum CvBuilderPage {
  personal([CvBuilderStep.personalInfo]),
  education([CvBuilderStep.education]),
  experience([CvBuilderStep.experience]),
  skills([CvBuilderStep.skills, CvBuilderStep.languages]),
  projects([CvBuilderStep.projects]),
  training([CvBuilderStep.training]),
  summary([CvBuilderStep.summaryObjective]);

  const CvBuilderPage(this.steps);

  /// Existing builder steps this page edits (validated together).
  final List<CvBuilderStep> steps;

  /// The step the controller should be moved to when this page opens.
  CvBuilderStep get entryStep => steps.first;

  /// Short label for the section chips.
  String get chipLabel => switch (this) {
    CvBuilderPage.personal => AppStrings.builderChipPersonal,
    CvBuilderPage.education => AppStrings.builderChipEducation,
    CvBuilderPage.experience => AppStrings.builderChipExperience,
    CvBuilderPage.skills => AppStrings.builderChipSkills,
    CvBuilderPage.projects => AppStrings.builderChipProjects,
    CvBuilderPage.training => AppStrings.builderChipTraining,
    CvBuilderPage.summary => AppStrings.builderChipSummary,
  };

  /// Section name used in "Step N of M · Section".
  String get sectionTitle => switch (this) {
    CvBuilderPage.personal => AppStrings.builderSectionPersonal,
    CvBuilderPage.education => AppStrings.builderSectionEducation,
    CvBuilderPage.experience => AppStrings.builderSectionExperience,
    CvBuilderPage.skills => AppStrings.builderSectionSkills,
    CvBuilderPage.projects => AppStrings.builderSectionProjects,
    CvBuilderPage.training => AppStrings.builderSectionTraining,
    CvBuilderPage.summary => AppStrings.builderSectionSummary,
  };
}

/// Navigation and progress rules over [CvBuilderPage]s. Pure Dart.
abstract final class CvBuilderFlow {
  static const List<CvBuilderPage> pages = CvBuilderPage.values;

  static int get total => pages.length;

  static int indexOf(CvBuilderPage page) => pages.indexOf(page);

  /// The page that edits [step]. The template / preview steps no longer have a
  /// page of their own and map to the last one.
  static CvBuilderPage pageFor(CvBuilderStep step) {
    for (final page in pages) {
      if (page.steps.contains(step)) {
        return page;
      }
    }
    return pages.last;
  }

  static CvBuilderPage? previous(CvBuilderPage page) {
    final index = indexOf(page);
    return index <= 0 ? null : pages[index - 1];
  }

  static CvBuilderPage? next(CvBuilderPage page) {
    final index = indexOf(page);
    return index >= pages.length - 1 ? null : pages[index + 1];
  }

  static bool isFirst(CvBuilderPage page) => indexOf(page) == 0;

  static bool isLast(CvBuilderPage page) => indexOf(page) == pages.length - 1;

  /// Progress through the flow, 0–1, counting the current page as reached.
  static double progress(CvBuilderPage page) => (indexOf(page) + 1) / total;

  /// Whole-number percentage, rounded down (1 of 6 → 16, 4 of 6 → 66).
  static int percent(CvBuilderPage page) => (progress(page) * 100).floor();

  /// The first validation error among the steps [page] edits, or null.
  static String? firstError(
    CvBuilderPage page,
    String? Function(CvBuilderStep step) validate,
  ) {
    for (final step in page.steps) {
      final error = validate(step);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
