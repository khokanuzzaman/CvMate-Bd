# Preview vs PDF on a simulator

One image per template and fixture: **left**, the preview screen on the
simulator (page 1 at the top); **right**, page 1 of the PDF that the app
exported in the same run, drawn by macOS Quick Look. The pass/fail table is in
[RESULTS.md](RESULTS.md). The images themselves are kept off `main`, on the
branch [`qa/template-compare`](https://github.com/khokanuzzaman/CvMate-Bd/tree/qa/template-compare/docs/qa/templates/compare).

Fixtures (`test/helpers/template_fixtures.dart`): **(a) full**, a realistic
2-page CV with a photo and every section; **(c) Bangla**, a Bangla name,
address and bullets. Fixture (b) minimal is checked in widget tests only.

## How it is made

1. The Auth emulator, then the template flow on a booted simulator. For each
   fixture it seeds the CV, opens the preview, switches through every template
   in the picker (Classic, Modern, Minimal, Professional, Fresher, back to
   Classic), and for each template saves a screenshot, the preview pages as
   the device rendered them, and the exported PDF to `build/qa/templates/`:

   ```bash
   firebase emulators:start --only auth --project demo-cvmate
   ```

   ```bash
   flutter drive -d <simulator-id> --driver=test_driver/integration_test.dart --target=integration_test/template_compare_test.dart --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1 --dart-define=QA_HOST_OUT="$PWD/build/qa"
   ```

2. On the Mac, compare and write the images and `RESULTS.md` here:

   ```bash
   TEMPLATE_QA_DIR=build/qa TEMPLATE_QA_DEVICE="iPhone 17 Pro, iOS 26.5" flutter test test/qa/template_compare_test.dart
   ```

## What is compared

| Check | How |
|---|---|
| Identity | Page 1 of the device preview reads as the chosen template (`test/helpers/template_look.dart`, see [../IDENTITY.md](../IDENTITY.md)). |
| Pages | The preview has as many pages as the exported PDF (same page breaks). |
| Layout per page | Page 1: same header band / bars, rules, photo and name position as Quick Look's page 1, within 1.5 pt. Later pages: same rules, photo and bars as the exported page rasterized by poppler (which substitutes Helvetica, so text-split bars are not compared there). |
| Same PDF as export | Quick Look draws the preview's PDF and the exported PDF identically (under 0.1% of pixels differ; the files differ only in their creation time). |
| iOS vs macOS page 1 (info) | Device preview page 1 against Quick Look's page 1. Reported, not pass/fail: Helvetica is not embedded in the PDF (README failure 3), so iOS and macOS each use their own copy and glyph widths differ slightly. Layout is checked separately and matches. |
| All text in PDF | Every value of the CV is in the exported PDF's text (nothing cut off). |
