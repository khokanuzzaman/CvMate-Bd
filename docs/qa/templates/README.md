# CV template QA (17 Nov 2026)

Every template in `CvTemplate` (classic, modern, minimal, professional,
fresher) was checked with three CVs from `test/helpers/template_fixtures.dart`:

- **(a) full**: every section, photo, personal details, two custom sections,
  declaration and signature; long bullets, so the PDF runs to 3 pages.
- **(b) minimal**: only what the builder requires (name, role, email, phone,
  address, a summary, one education entry, two skills).
- **(c) non-ASCII**: Bangla name and address (`নুসরাত জাহান`, `ঢাকা, বাংলাদেশ`),
  accented Latin (`José Müller`, `Zürich, Ångström`, `Café Señor`) and an emoji
  bullet (`Shipped v2 🚀`).

`<template>.pdf` here is each template's export of the full CV on A4.

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

- **The preview looks the same for every template.** `CvPreviewContent` has one
  design. Only Fresher's default section order differs. So the four
  non-Fresher goldens are identical, and the template's look shows only in the
  PDF.
- **Paper size.** A4 and Letter are both supported (`PaperSize`, chosen on the
  style screen). Printing uses the printer's page format.

## How it is checked

| Check | Test |
|---|---|
| Preview: no overflow, every value shown, no empty headings, goldens for (a) and (b) | `test/features/cv_builder/presentation/widgets/cv_preview_templates_test.dart` |
| PDF: `pdftotext` has every value, `pdffonts` shows non-base-14 fonts embedded, page size, page count, a page-tall experience flows on | `test/shared/services/pdf/cv_pdf_templates_qa_test.dart` |
| Switching through every template keeps every stored field | `test/features/cv_builder/presentation/controllers/template_switch_test.dart` |

The PDF tests need poppler (`brew install poppler`) and skip without it. The
goldens use the real app fonts (`loadTestFonts`). They are compared on macOS
only, because Linux CI rasterises text slightly differently.

## Regenerate

```sh
# PDFs in this folder
CVMATE_QA_PDF_DIR="$PWD/docs/qa/templates" \
  flutter test test/shared/services/pdf/cv_pdf_templates_qa_test.dart

# Preview goldens (on macOS)
flutter test test/features/cv_builder/presentation/widgets/cv_preview_templates_test.dart --update-goldens
```
