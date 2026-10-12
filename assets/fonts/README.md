# Bundled fonts

**Noto Sans Bengali** (`NotoSansBengali-Regular.ttf`, `NotoSansBengali-Bold.ttf`)
is declared in `pubspec.yaml` and used only as `fontFamilyFallback` in
`AppTextStyles` (`lib/core/theme/app_text_styles.dart`), so the taka sign ৳ and
Bangla text render with a real font on every device and in tests — Sora and
Plus Jakarta Sans have no Bengali glyphs.

These are the exact static files the `google_fonts` package downloads for
Noto Sans Bengali (weights 400 and 700); each file's SHA-256 matches the hash in
the package, which is also its file name on `fonts.gstatic.com`.

Licence: SIL Open Font License 1.1, © The Noto Project Authors
(<https://github.com/notofonts/bengali>). The full text is in `OFL.txt`.
