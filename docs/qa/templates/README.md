# CV template QA (17 Nov 2026)

Every template in `CvTemplate` (classic, modern, minimal, professional,
fresher) was checked with three CVs from `test/helpers/template_fixtures.dart`:

- **(a) full**: every section, photo, personal details, two custom sections,
  declaration and signature; a realistic 2-page CV in every template.
- **(b) minimal**: only what the builder requires (name, role, email, phone,
  address, a summary, one education entry, two skills).
- **(c) non-ASCII**: Bangla name and address (`নুসরাত জাহান`, `ঢাকা, বাংলাদেশ`),
  accented Latin (`José Müller`, `Zürich, Ångström`, `Café Señor`) and an emoji
  bullet (`Shipped v2 🚀`).

`<template>.pdf` here is each template's export of the full CV on A4.

## Update, 19 Nov 2026: the preview is the PDF

The preview no longer has its own layout. `CvPreviewScreen` now shows the pages
of the PDF that Export builds (`generateCvPdf(profile: draft)`), rendered by
the platform (`Printing.raster`) into `CvPdfPagesView`. So every template's
preview looks like that template, with the same page breaks, header, photo and
fonts as the export. `CvPreviewContent` (one purple design for all five) and
its goldens are gone. What makes each template itself is in
[IDENTITY.md](IDENTITY.md); the simulator side-by-sides are in
[compare/](compare/).

Consequences to know:

- **Bangla in the preview now looks like the PDF**, including failure 1 below
  (unshaped vowel signs and conjuncts). Before, the preview shaped Bangla
  correctly and hid that the PDF does not.
- The preview pages are images, so they are not selectable text in the app.
  Each page has the screen-reader label "CV page N of M".

Results, 19 Nov (all PASS; widget tests render with poppler, the simulator
with iOS):

| Template | (a) full: widget / iPhone 17 Pro sim | (b) minimal: widget | (c) Bangla: widget / iPhone 17 Pro sim |
|---|---|---|---|
| Classic | PASS / PASS | PASS | PASS / PASS |
| Modern | PASS / PASS | PASS | PASS / PASS |
| Minimal | PASS / PASS | PASS | PASS / PASS |
| Professional | PASS / PASS | PASS | PASS / PASS |
| Fresher | PASS / PASS | PASS | PASS / PASS |

Each PASS covers identity, page count and page breaks, layout, the same PDF as
the export, and no text cut off. Switching in every order passed in the widget
test (all 20 ordered pairs) and on the simulator (Classic, Modern, Minimal,
Professional, Fresher, Classic, for (a) and (c)). Details: [compare/RESULTS.md](compare/RESULTS.md).

The rest of this file is the 17 Nov pass; its preview column described the old
preview.

## Results

All five templates give the same result in every column, because they share one
PDF engine (`CvPdfTemplateBuilders`, same fonts and section walk) and one preview
widget (`CvPreviewContent`).

| Template | Preview a / b / c | PDF text a / b / c | PDF fonts embedded | A4 / Letter | Page breaks | Template switch keeps data |
|---|---|---|---|---|---|---|
| Classic | PASS / PASS / PASS* | PASS / PASS / FAIL (1, 2) | FAIL (3) | PASS / PASS | PASS (4) | PASS |
| Modern | PASS / PASS / PASS* | PASS / PASS / FAIL (1, 2) | FAIL (3) | PASS / PASS | PASS (4) | PASS |
| Minimal | PASS / PASS / PASS* | PASS / PASS / FAIL (1, 2) | FAIL (3) | PASS / PASS | PASS (4) | PASS |
| Professional | PASS / PASS / PASS* | PASS / PASS / FAIL (1, 2) | FAIL (3) | PASS / PASS | PASS (4) | PASS |
| Fresher | PASS / PASS / PASS* | PASS / PASS / FAIL (1, 2) | FAIL (3) | PASS / PASS | PASS (4) | PASS |

\* The preview shapes Bangla correctly (Flutter's text engine with the bundled
Noto Sans Bengali). The emoji draws as a box in tests, which have no emoji font;
on a phone the system emoji font draws it. Not checked on a device.

### Failures

1. **Bangla is not shaped in the PDF.** The `pdf` package has no complex-script
   shaping: every Bangla character is drawn on its own from Noto Sans Bengali.
   Pre-base vowel signs land after their consonant (`বাংলাদেশ` prints as
   `বাংলাদশে`) and conjuncts print as consonant + hasant (`এতদ্বারা`, `প্রদত্ত`).
   The text is still selectable and extracts correctly (`pdftotext` gives the
   right Unicode), but it reads wrong on paper. This also affects the existing
   Bangla declaration. A real fix is large, so it was not built. Options:
   draw Bangla runs as images rendered by Flutter's text engine (they look right
   but are no longer selectable), render the PDF on the server with a
   HarfBuzz-based engine, or wait for shaping support in `dart_pdf`. Also,
   Bangla in bold places (such as the name) prints in the regular weight,
   because only the regular Bengali font is passed to the PDF as a fallback.
2. **Emoji are dropped from the PDF.** There is no emoji font in the PDF, so
   `🚀` prints as a blank space and is missing from the text. The rest of the
   bullet is kept, and nothing crashes. Fix: bundle a monochrome emoji font
   (Noto Emoji) as a second `fontFallback` and accept the larger app size, or
   strip emoji on export, since emoji are not ATS-friendly anyway.
3. **Helvetica is not embedded.** The base fonts are the PDF base-14 Helvetica
   and Helvetica-Bold (`pdffonts`: `emb no`). Every viewer has to substitute
   them, and the result depends on the viewer. Apple's renderer gets it right.
   Poppler on macOS swaps Helvetica-Bold for regular Helvetica, so names and
   section titles lose their bold. The fallback Noto Sans Bengali is embedded
   (`emb yes`). Fix: use the bundled Noto Sans Bengali (it has Latin glyphs)
   or a bundled Noto Sans as `base` and `bold`, and replace the hard-coded
   `pw.Font.helveticaBold()` calls with `fontWeight: bold`. This changes the
   typeface of every CV, and `test/helpers/pdf_text.dart` reads only base-14
   text, so it would need to move to `pdftotext`. The change needs a design
   decision first, so it was not made here.
4. **Cosmetic.** Lines are never cut and nothing is lost between pages. An
   experience or project can still break after its header, so the title and
   company can sit at the foot of one page with the bullets on the next.

### Fixed in this pass

- The preview left out an experience's **location** and a skill's **level**,
  though the PDF prints both. Both now show (`cv_preview_content.dart`), with
  a regression test in `cv_preview_templates_test.dart`.

### Notes

- **The preview looked the same for every template** (fixed 19 Nov, see above).
  `CvPreviewContent` had one design. Only Fresher's default section order differs. So the four
  non-Fresher goldens are identical, and the template's look shows only in the
  PDF.
- **Paper size.** A4 and Letter are both supported (`PaperSize`, chosen on the
  style screen). Printing uses the printer's page format.

## How it is checked

| Check | Test |
|---|---|
| Template identity on the preview (fails on the wrong template), photo, page count, title case, fonts; for (a), (b), (c) | `test/features/cv_builder/presentation/screens/cv_preview_templates_qa_test.dart`, group 1 |
| Switching in the picker through every ordered pair of templates: preview follows, no data lost | same file, group 2; `test/features/cv_builder/presentation/controllers/template_switch_test.dart` |
| Preview pages = exported PDF pages: same page count and page text, same layout, pixels within anti-aliasing, nothing cut off | same file, group 3 |
| PDF: `pdftotext` has every value, `pdffonts`, page size, page count, a page-tall experience flows on | `test/shared/services/pdf/cv_pdf_templates_qa_test.dart` |
| On the simulator: device preview against the exported PDF | `integration_test/template_compare_test.dart` + `test/qa/template_compare_test.dart`, see [compare/README.md](compare/README.md) |

The tests need poppler (`brew install poppler`) and skip without it. In widget
tests the preview's pages come from poppler's `pdftoppm`, since the platform
renderer does not exist there.

## Regenerate

```sh
# PDFs in this folder
CVMATE_QA_PDF_DIR="$PWD/docs/qa/templates" \
  flutter test test/shared/services/pdf/cv_pdf_templates_qa_test.dart
```

Simulator side-by-sides: see [compare/README.md](compare/README.md).
