import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';

/// The kinds of CV section the layout can order, hide and rename. The content
/// of each built-in kind stays in its own typed field on `CvProfile`; the
/// layout only controls where it appears, whether it appears, and its title.
enum CvSectionKind {
  summary,
  objective,
  education,
  experience,
  skills,
  projects,
  training,
  languages,
  custom;

  bool get isBuiltIn => this != CvSectionKind.custom;

  /// Parses a stored name; null for anything unknown (e.g. a kind added by a
  /// newer app version), so reading never fails.
  static CvSectionKind? tryParse(Object? value) {
    for (final kind in values) {
      if (kind.name == value) {
        return kind;
      }
    }
    return null;
  }
}

/// How a custom section lays out its items.
enum CustomSectionLayout {
  /// Each item is a bold title with an optional description under it.
  titledRows,

  /// Each item is one bullet line.
  bullets;

  static CustomSectionLayout parse(Object? value) {
    for (final layout in values) {
      if (layout.name == value) {
        return layout;
      }
    }
    return CustomSectionLayout.titledRows;
  }
}

/// One entry of the section layout: which section, whether it is shown, and an
/// optional title the user typed instead of the default.
///
/// A built-in section's [id] is its kind's name; a custom section's [id] is the
/// id of its `CustomSection`. The list order of configs is the render order.
class SectionConfig {
  const SectionConfig({
    required this.id,
    required this.kind,
    this.titleOverride,
    this.visible = true,
  });

  factory SectionConfig.builtIn(
    CvSectionKind kind, {
    String? titleOverride,
    bool visible = true,
  }) {
    assert(kind.isBuiltIn, 'use SectionConfig.custom for custom sections');
    return SectionConfig(
      id: kind.name,
      kind: kind,
      titleOverride: titleOverride,
      visible: visible,
    );
  }

  factory SectionConfig.custom(String id, {bool visible = true}) =>
      SectionConfig(id: id, kind: CvSectionKind.custom, visible: visible);

  final String id;
  final CvSectionKind kind;
  final String? titleOverride;
  final bool visible;

  /// [titleOverride] trimmed; null when it is empty (use the default title).
  String? get cleanTitleOverride {
    final value = titleOverride?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  SectionConfig copyWith({
    String? titleOverride,
    bool clearTitleOverride = false,
    bool? visible,
  }) {
    return SectionConfig(
      id: id,
      kind: kind,
      titleOverride: clearTitleOverride
          ? null
          : titleOverride ?? this.titleOverride,
      visible: visible ?? this.visible,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SectionConfig &&
      other.id == id &&
      other.kind == kind &&
      other.titleOverride == titleOverride &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(id, kind, titleOverride, visible);
}

/// One row of a custom section.
///
/// In a `titledRows` section [title] is the bold heading and [description] the
/// text under it; in a `bullets` section the bullet text is [title] (with the
/// optional [description] appended after a dash).
class CustomSectionItem {
  const CustomSectionItem({
    required this.id,
    this.title = '',
    this.description = '',
  });

  factory CustomSectionItem.empty({String? id}) => CustomSectionItem(
    id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
  );

  final String id;
  final String title;
  final String description;

  bool get isEmpty => title.trim().isEmpty && description.trim().isEmpty;

  /// The single line a bullet shows: title, then description after " — ".
  String get bulletText => [
    title.trim(),
    description.trim(),
  ].where((part) => part.isNotEmpty).join(' — ');

  CustomSectionItem copyWith({String? title, String? description}) {
    return CustomSectionItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

/// A section the user added: a title, a layout, and its items.
class CustomSection {
  const CustomSection({
    required this.id,
    required this.title,
    this.layout = CustomSectionLayout.titledRows,
    this.items = const [],
  });

  factory CustomSection.create({
    required String title,
    required CustomSectionLayout layout,
    String? id,
  }) => CustomSection(
    id: id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
    title: title,
    layout: layout,
  );

  final String id;
  final String title;
  final CustomSectionLayout layout;
  final List<CustomSectionItem> items;

  /// Items that have any text.
  List<CustomSectionItem> get filledItems => [
    for (final item in items)
      if (!item.isEmpty) item,
  ];

  bool get hasContent => filledItems.isNotEmpty;

  /// All the text of the section (title, then every item), for scoring.
  String get plainText => [
    title,
    for (final item in filledItems) ...[item.title, item.description],
  ].where((part) => part.trim().isNotEmpty).join(' ');

  CustomSection copyWith({
    String? title,
    CustomSectionLayout? layout,
    List<CustomSectionItem>? items,
  }) {
    return CustomSection(
      id: id,
      title: title ?? this.title,
      layout: layout ?? this.layout,
      items: items ?? this.items,
    );
  }
}

/// A [SectionConfig] together with the custom section it points at (custom
/// kinds only). What renderers iterate over, in order.
class CvSection {
  const CvSection({required this.config, this.custom});

  final SectionConfig config;
  final CustomSection? custom;

  CvSectionKind get kind => config.kind;
  bool get visible => config.visible;

  /// The title to print: the user's rename, else [defaultTitle] — except for a
  /// custom section, whose own title is the default.
  String titleOr(String defaultTitle) =>
      config.cleanTitleOverride ??
      (custom != null && custom!.title.trim().isNotEmpty
          ? custom!.title.trim()
          : defaultTitle);
}

/// Pure rules for turning a stored layout into the list a renderer walks.
abstract final class CvSectionLayout {
  /// Order every template but Fresher uses.
  static const List<CvSectionKind> standardOrder = [
    CvSectionKind.summary,
    CvSectionKind.objective,
    CvSectionKind.education,
    CvSectionKind.experience,
    CvSectionKind.skills,
    CvSectionKind.projects,
    CvSectionKind.training,
    CvSectionKind.languages,
  ];

  /// Fresher leads with education and projects, ahead of experience.
  static const List<CvSectionKind> fresherOrder = [
    CvSectionKind.summary,
    CvSectionKind.objective,
    CvSectionKind.education,
    CvSectionKind.projects,
    CvSectionKind.skills,
    CvSectionKind.experience,
    CvSectionKind.training,
    CvSectionKind.languages,
  ];

  /// The layout a CV without a stored one gets: today's order for its
  /// template, everything visible, no renames. Old CVs therefore render
  /// exactly as they always did.
  static List<SectionConfig> defaultFor(CvTemplate template) => [
    for (final kind
        in template == CvTemplate.fresher ? fresherOrder : standardOrder)
      SectionConfig.builtIn(kind),
  ];

  /// Cleans [stored] (or the template default when it is null) against the
  /// CV's [customs]: every built-in appears exactly once, every custom section
  /// exactly once, and entries pointing at nothing are dropped. Anything
  /// missing is appended visible, so reading odd data never fails.
  static List<SectionConfig> resolve({
    required List<SectionConfig>? stored,
    required List<CustomSection> customs,
    required CvTemplate template,
  }) {
    final customIds = {for (final custom in customs) custom.id};
    final seen = <String>{};
    final result = <SectionConfig>[];

    void add(SectionConfig config) {
      if (seen.add(config.id)) {
        result.add(config);
      }
    }

    for (final config in stored ?? defaultFor(template)) {
      if (config.kind.isBuiltIn) {
        add(
          config.id == config.kind.name
              ? config
              : SectionConfig.builtIn(
                  config.kind,
                  titleOverride: config.titleOverride,
                  visible: config.visible,
                ),
        );
      } else if (customIds.contains(config.id)) {
        add(config);
      }
    }
    for (final config in defaultFor(template)) {
      add(config);
    }
    for (final custom in customs) {
      add(SectionConfig.custom(custom.id));
    }
    return result;
  }
}
