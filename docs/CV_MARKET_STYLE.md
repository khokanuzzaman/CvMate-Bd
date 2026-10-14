# CV style: market presets, personal details, photo, declaration, paper size

Each CV has a **style** (`international` | `gulf` | `southAsia`) and a **paper
size** (`a4` | `letter`). Choosing a style only sets which personal fields are
*shown* (`CvStyle.defaultFields`); the data behind hidden fields is kept, and any
single field can still be switched on or off.

| Style | Shown by default |
|---|---|
| international | nothing (ATS-safe: no photo, personal details, declaration, signature) |
| gulf | photo, date of birth, nationality, passport + expiry, visa status, driving licence |
| southAsia | photo, date of birth, nationality, marital status, declaration, signature |

## Model

- `CvProfile.style`, `paperSize`, `shownFields` (`Set<PersonalField>`),
  `details` (`PersonalDetails`, incl. custom label/value rows), `declaration`
  (`CvDeclaration`), `photo` (35x45 JPEG bytes), `signature` (PNG bytes).
- **Private by construction**: none of this lives in `PersonalInfo`, and the AI
  prompt/payload builders and the ATS engine only read whitelisted fields, so
  passport number, date of birth, religion, marital status, gender and the photo
  are never sent to the AI or scored.

## Storage (schema 3, additive)

`CvMarketDto` adds `style`, `paperSize`, `shownFields`, `personalDetails`,
`declaration`, `photo`, `signature` (base64) next to the v2 keys. A CV saved
before schema 3 reads as international, A4, nothing shown. Reading never throws.
Photo and signature travel inside the same document for Hive and Firestore
(tens of KB after cropping).

## UI

- **CV style screen** (`/cvs/style`): from the builder top bar, the style pill on
  the Personal page, and right after "New" on Home / the CV list (`?from=new`).
- **Personal page**: photo (take / gallery, cropped to 35x45), the "Personal
  information" list with a "Show on CV" switch per row, more fields (religion,
  gender, custom rows), the passport safety note, and a link to
  **Declaration & signature** (`/cvs/declaration`): text (English/বাংলা
  defaults), place, date (empty = date of export), signature drawn or uploaded.
  The signature is an image, not a digital certificate.

## PDF

All five templates print the photo beside the header, a "Personal Details"
section after it, and the declaration with the signature at the end, in the CV's
paper size. International prints exactly what it always did. Noto Sans Bengali
(`assets/fonts`) is embedded as a fallback font, so Bangla text renders instead
of disappearing or printing as boxes.

## Known gap

The phone validator on the Personal page only accepts Bangladesh numbers, which
blocks Gulf-style CVs with a UAE/Saudi number. Not changed here.
