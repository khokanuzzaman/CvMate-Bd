import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_state.dart';

/// One page of the builder: a built-in [CvBuilderPage], or the page of a custom
/// section (identified by its id).
class BuilderPageRef {
  const BuilderPageRef.builtIn(CvBuilderPage this.page) : customId = null;
  const BuilderPageRef.custom(String this.customId) : page = null;

  final CvBuilderPage? page;
  final String? customId;

  bool get isCustom => customId != null;

  @override
  bool operator ==(Object other) =>
      other is BuilderPageRef &&
      other.page == page &&
      other.customId == customId;

  @override
  int get hashCode => Object.hash(page, customId);
}

/// The builder's pages for a CV: the seven built-in ones, with a page for each
/// custom section between Training and Summary (so Summary stays last, where the
/// "ready to preview" banner and the Preview button are).
///
/// With no custom sections this is exactly [CvBuilderFlow.pages].
abstract final class CvBuilderPages {
  static List<BuilderPageRef> forProfile(CvProfile profile) {
    final customIds = [
      for (final config in profile.sections)
        if (config.kind == CvSectionKind.custom) config.id,
    ];
    return [
      for (final page in CvBuilderFlow.pages)
        if (page == CvBuilderPage.summary) ...[
          for (final id in customIds) BuilderPageRef.custom(id),
          BuilderPageRef.builtIn(page),
        ] else
          BuilderPageRef.builtIn(page),
    ];
  }

  /// The page the builder is on, given its state.
  static BuilderPageRef current(CvBuilderState state) {
    final customId = state.currentCustomSectionId;
    if (customId != null && state.draft.customSectionById(customId) != null) {
      return BuilderPageRef.custom(customId);
    }
    return BuilderPageRef.builtIn(CvBuilderFlow.pageFor(state.currentStep));
  }

  static int indexOf(List<BuilderPageRef> pages, BuilderPageRef page) {
    final index = pages.indexOf(page);
    return index < 0 ? pages.length - 1 : index;
  }

  static BuilderPageRef? previous(
    List<BuilderPageRef> pages,
    BuilderPageRef page,
  ) {
    final index = indexOf(pages, page);
    return index <= 0 ? null : pages[index - 1];
  }

  static BuilderPageRef? next(List<BuilderPageRef> pages, BuilderPageRef page) {
    final index = indexOf(pages, page);
    return index >= pages.length - 1 ? null : pages[index + 1];
  }

  static bool isLast(List<BuilderPageRef> pages, BuilderPageRef page) =>
      indexOf(pages, page) == pages.length - 1;

  /// Progress through the flow, 0–1, counting the current page as reached.
  static double progress(List<BuilderPageRef> pages, BuilderPageRef page) =>
      (indexOf(pages, page) + 1) / pages.length;

  /// Whole-number percentage, rounded down (1 of 6 → 16, 4 of 6 → 66).
  static int percent(List<BuilderPageRef> pages, BuilderPageRef page) =>
      (progress(pages, page) * 100).floor();

  /// Label on the section chip.
  static String chipLabel(CvProfile profile, BuilderPageRef page) =>
      page.isCustom
      ? _customTitle(profile, page.customId!)
      : page.page!.chipLabel;

  /// Section name in "Step N of M · Section".
  static String sectionTitle(CvProfile profile, BuilderPageRef page) =>
      page.isCustom
      ? _customTitle(profile, page.customId!)
      : page.page!.sectionTitle;

  static String _customTitle(CvProfile profile, String id) {
    final title = profile.customSectionById(id)?.title.trim() ?? '';
    return title.isEmpty ? 'Section' : title;
  }
}
