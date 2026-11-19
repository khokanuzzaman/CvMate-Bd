# Template QA: preview vs PDF side-by-sides (images only)

This branch only holds the images, so they stay off `main`. One image per
template and fixture: **left**, the CV preview on the iPhone 17 Pro simulator
(iOS 26.5); **right**, page 1 of the PDF the app exported in the same run,
drawn by macOS Quick Look. 19 Nov 2026.

- `full-<template>.png`: fixture (a), a 2-page CV with photo and every section.
- `nonAscii-<template>.png`: fixture (c), Bangla name, address and bullets.

Pass/fail table: [RESULTS.md](RESULTS.md). How they are made and what is
checked: `docs/qa/templates/compare/README.md` on the PR branch
`test/template-identity-pdf`.
