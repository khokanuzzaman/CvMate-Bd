# CV sections: order, visibility, titles, custom sections

A CV's **section layout** controls what the preview, the PDF (all 5 templates),
the ATS checker and the AI tailoring see. The typed fields (`education`,
`experiences`, …) are unchanged; the layout only says *which sections, in which
order, under which title*.

## Model (`cv_builder/domain/entities/cv_section.dart`)

- `SectionConfig {id, kind, titleOverride?, visible}` — one per section.
  Built-in kinds: summary, objective, education, experience, skills, projects,
  training, languages. A custom section uses kind `custom` and its own id.
- `CustomSection {id, title, layout (titledRows | bullets), items[{title, description}]}`.
- `CvProfile.sectionLayout` is **null** until the user first edits the layout.
  Null means "the template's default order, everything shown", so an old CV
  renders exactly as before. `CvSectionLayout.resolve` cleans any stored list
  (dedupes, appends built-ins that are missing, drops dangling custom ids).
- `CvProfile.visibleSections` is what every renderer walks. A hidden section is
  not rendered, not scored as "missing" by the ATS checker, and not sent to AI.

## Storage (`CvProfileDto`, schema version 2)

Hive and Firestore share one map. Writes are additive: `schemaVersion: 2`,
`customSections` (always), `sectionLayout` (only when the user set one). All
old keys keep their shape, so an older app version still reads the document and
simply ignores the new keys. Reads are tolerant: missing keys, unknown kinds,
duplicate or id-less custom sections and wrongly-typed values are skipped or
defaulted, never thrown. Fixtures: `test/fixtures/cv_v1_*.json`.

## UI

- **Sections screen** (`/cvs/sections`): reachable from the builder top bar and
  the preview ⋮ menu. Drag handles, a switch per section, tap/⋮ to rename
  (sheet with "Reset to default"), "Add custom section" (title + layout), and
  delete for custom sections only (asks first). Top-bar reset restores the
  template order and default titles and keeps custom sections.
- **Builder**: each custom section gets a chip and a page (before Summary, which
  stays last). `CvBuilderPages` builds the page list from the draft;
  `CvBuilderFlow` keeps the seven fixed pages.

## Behaviour change to know about

The on-screen preview now follows the same order as the PDF. Before, the
preview used its own fixed order for some templates.

## Tests

`test/features/cv_builder/data/dtos/cv_profile_dto_test.dart` (migration, round
trips), `.../repositories/cv_repository_sync_test.dart` (cloud sync),
`test/shared/services/pdf/cv_pdf_sections_test.dart` (5 templates × order /
hidden / renamed / custom), `test/features/ats_checker/.../ats_rule_engine_sections_test.dart`,
`.../controllers/cv_builder_sections_test.dart`, `.../screens/cv_sections_screen_test.dart`,
`.../screens/cv_builder_custom_section_test.dart`, and the integration flow
`integration_test/flows/sections_flow.dart`.
