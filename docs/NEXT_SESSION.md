# Next session: CV control, PR 2 of 2

Designs in `docs/design/`: `CV style · market preset@2x.png`,
`Personal details · Gulf style@2x.png`, `Declaration & signature@2x.png`.
PR 1 (flexible sections) is merged; build on its section layout.

```
CV control, PR 2 of 2: market styles, regional details, declaration, signature, photo, paper
size, Bangla in PDF. ONE PR off main. Follow the lean testing rules in CLAUDE.md.

DESIGN: the three PNGs above + DESIGN_TOKENS.md, built from lib/core widgets.

1. CV style preset (per CV): international | gulf | southAsia, chosen on a "CV style" screen
   (from the builder top bar and when creating a CV). Changing style only flips field and
   section visibility defaults; it never deletes data.
   - international: no photo, no DOB/nationality/passport/visa/marital/religion/gender,
     no declaration or signature.
   - gulf: photo, DOB, nationality, passport no. + expiry, visa status, driving licence on.
   - southAsia: photo, DOB, nationality, marital status, declaration, signature on.
   The user can still toggle any single field after choosing a style.
2. Personal details: add optional fields, each with its own "show on CV" switch: date of birth,
   nationality, passport number + expiry, visa status (free text), driving licence, marital
   status, religion, gender, plus user-added custom rows (label + value). Show the safety note
   about not posting passport numbers publicly.
3. Photo: take or pick, crop to a passport ratio (35x45), stored locally and synced like the
   rest of the CV. Only rendered when the photo field is visible.
4. Declaration + signature: declaration toggle, editable text with English and Bangla
   defaults, place, date (default "date of export"). Signature: draw on a pad or upload an
   image, stored as a PNG. Label it honestly as an image, not a digital certificate.
5. Paper size per CV: A4 (default) or Letter, used by every PDF template and the preview.
6. PDF: all 5 templates render the visible personal fields, photo, declaration and signature
   in a sensible place. International style stays ATS-safe (single column, no photo).
   Embed Noto Sans Bengali (already in assets/fonts) as a PDF fallback font so Bangla text
   never disappears or prints as boxes.
7. Storage: additive schema change (bump version, old CVs load with style = international and
   all new fields hidden). Never throws on old or odd data.
8. AI and ATS: never send passport number, DOB, religion, marital status, gender or photo to
   the AI. ATS ignores these fields.

TESTS (lean)
- One migration test: an old CV loads as international with new fields hidden.
- One PDF test: gulf style with photo + passport fields, and a Bangla string that renders.
- One test that the AI prompt excludes the private fields.
- Integration: only create CV -> choose Gulf -> fill personal details -> preview -> export.
```
