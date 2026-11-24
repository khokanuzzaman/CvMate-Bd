# What makes each template itself

Written from the PDF builders as they are today
(`lib/shared/services/pdf/cv_pdf_template_builders.dart`). The preview shows
the exported PDF's own pages (`CvPdfPagesView`), so the preview and the PDF
look the same by construction.

## Shared by all five

| | |
|---|---|
| Layout | One column. Page margins 30 pt left/right, 28 pt top/bottom. |
| Colour | Greyscale only. No accent colour. |
| Fonts | Helvetica and Helvetica-Bold (PDF base fonts, not embedded), with Noto Sans Bengali (embedded) as the fallback for Bangla. |
| Photo | Top right, 64 x 82 pt, grey border, next to the header. Only when the CV has a photo and the style shows it. |
| Footer | "Page X of Y", bottom right. |
| Section order | The CV's own section layout. Without one, the style's or template's default: Fresher puts Education and Projects before Experience. |

## Per template

| Template | Header | Section titles |
|---|---|---|
| Classic | Name left, 24 pt bold. Role grey, contact line. Black rule, 1.1 pt. | UPPERCASE, bold 11 pt, grey-700 underline 0.8 pt. |
| Modern | Dark (grey-900) band, white name 24 pt and role. Contact in a box with a light grey border. | Dark bar with white bold 11 pt text, not uppercase. |
| Minimal | Name, role and contact **centred**. Grey-700 rule, 0.9 pt. | UPPERCASE, bold 10 pt, letter-spaced. **No rule.** |
| Professional | Name left, 22 pt. Role UPPERCASE and letter-spaced. Thick grey-900 rule, 1.6 pt. | UPPERCASE, letter-spaced, grey-900 rule 1 pt. |
| Fresher | Like Classic, lighter: name 23 pt, grey-600 rule 0.9 pt. | UPPERCASE 10.5 pt, light grey-500 underline 0.8 pt. |

## How the tests read it

`test/helpers/template_look.dart` reads page 1 of the preview as pixels:

- **Dark bars** (at least 8 pt tall and 40 pt wide): only Modern.
- **Rules across the column**, and how dark they are: the header rule is black
  in Classic, grey-900 in Professional, grey-700 in Minimal, grey-600 in
  Fresher. The section-title rules tell them apart again: grey-700 (Classic),
  grey-900 (Professional), none (Minimal), grey-500 (Fresher).
- **Where the name starts**: at the margin, except Minimal (centred).
- **Photo**: a photo-coloured block in the top-right corner.

These features match exactly one template each, so a preview that draws the
wrong template fails. The tests also check the PDF text (titles in capitals
except Modern) and the fonts (`pdffonts`).
