# CvMate — Design Tokens
Single source of truth for implementing the approved UI design. Pair this with the screenshots
in `docs/design/`. All values are the exact ones used in the design canvas (light theme).

---

## Fonts
- **Display / headings:** Sora — weights 600, 700 (use for h1/h2/titles, app-bar titles, numbers/scores, brand wordmark)
- **Body / UI:** Plus Jakarta Sans — weights 400, 500, 600, 700 (everything else)
- Load via `google_fonts`. Fallback stack: system-ui, sans-serif.

## Colors — light theme
| Token | Hex | Use |
|---|---|---|
| bg | `#F4F2FC` | screen background (soft indigo ground) |
| surface | `#FFFFFF` | cards, sheets |
| surfaceAlt | `#FAF9FE` | inputs inside cards, subtle fills |
| previewBg | `#EBE8F6` | CV preview backdrop |
| ink | `#1B1533` | primary text |
| inkSoft | `#2A2440` | body text on cards |
| muted | `#6E6890` | secondary text |
| muted2 | `#8A85A6` | captions, hints |
| placeholder | `#A29DBB` | input placeholders |
| line | `#EAE6F6` | hairline borders |
| lineStrong | `#E2DDF1` | dividers, track backgrounds |
| primary | `#5A44D6` | brand indigo — buttons, active, links |
| primaryDeep | `#3D2FA0` | text/detail on soft indigo |
| primarySoft | `#ECE9FB` | icon tiles, soft chips, avatar bg |
| accent | `#F2994A` | warm amber — hero CTA, key highlights, center nav |
| accentSoft | `#FCE8D2` | amber chips/pills bg |
| onAccent | `#3A2A12` | text/icon on amber (never white on amber) |
| accentInk | `#9A5B15` | amber text on accentSoft |
| success | `#16A06B` | success fills |
| successText | `#0F7A50` | matched/success text |
| successSoft | `#DDF3EA` | matched chips bg |
| danger | `#E5533D` | errors / removed |

> Contrast rule: white text on `primary` = OK. On `accent` use `onAccent` (dark), never white.

## Typography scale
| Style | Font / weight | Size | Notes |
|---|---|---|---|
| h1 | Sora 700 | 26 | onboarding/auth headlines |
| h2 | Sora 700 | 23 | section headlines |
| title | Sora 700 | 20 | hero card title |
| appBar | Sora 700 | 17 | screen titles |
| body | Plus Jakarta 400–500 | 14 | default |
| bodySm | Plus Jakarta 400–500 | 13.5 | dense text, inputs |
| caption | Plus Jakarta 400 | 12 | helper text |
| hint | Plus Jakarta 400 | 11.5 | fine print |
| label | Plus Jakarta 700 | 11.5 | UPPERCASE, letter-spacing .06em, color muted/muted2 |

## Spacing scale (px)
`4, 6, 8, 10, 12, 14, 16, 18, 20, 22` — screen padding usually 18 horizontal; card padding 16.

## Radius (px)
| Element | Radius |
|---|---|
| card | 18–20 |
| button | 15 (14–16) |
| input | 12 |
| icon tile / small square | 11–12 |
| chip / pill / segmented | 999 (full) |
| artboard corner (device) | 34 |

## Elevation
Soft shadow only (no heavy drop shadows, no glows except the amber nav button):
`color rgba(40,30,90,0.16), blurRadius 30, offset (0,14), spreadRadius -20`

## Layout
- Mobile frame: **390 wide** (design at 390×844 baseline; screens grow taller as needed).
- Min touch target: **48**.
- Bottom nav: 5 items; center "Tailor" is a raised amber circle (50px) with white border, negative top margin.

---

## Component specs
- **PrimaryButton** — fill `primary`, text white 700 @15, radius 15, padding 16, optional trailing arrow icon.
- **SecondaryButton** — surface bg, 1.5px `primary` border, text `primary` 700.
- **AmberCtaButton** — fill `accent`, text `onAccent` 700, radius 14–16.
- **AppCard** — `surface`, 1px `line` border, radius 18–20, optional soft shadow.
- **SectionLabel** — label style (UPPERCASE, muted, 11.5/700, spacing .06em).
- **AppChip** variants:
  - neutral: `surfaceAlt`/white bg, `lineStrong` border, `primaryDeep` text
  - selected: `primary` bg, white text
  - matched: `successSoft` bg, `successText` text
  - missing: `accentSoft` bg, `accentInk` text, leading "+" icon
  - removable: trailing "×" icon
- **QuickActionTile** — white card, 40px `primarySoft` icon square (primary icon), label 12/600, centered.
- **AppTextField / AppTextArea** — label (12/600 muted) + field: white/`surfaceAlt` bg, 1px `line`, radius 12, padding 13–15, placeholder `placeholder`.
- **ProgressBar / Steps** — track `lineStrong`, fill `primary` (or `success` at 100%), height 5–6, full radius. Segmented variant = equal segments with gap 6.
- **ScoreRing** — SVG/CustomPaint: track `#EEEBF8` width 9, arc `accent` width 9 rounded cap, centered % in Sora 700.
- **BottomNavBar** — white, top border `line`, 5 items; active `primary`, inactive `muted2`; center raised amber action.
- **AppTopBar** — 40px back button (white card, `line` border) + Sora 700 @17 title + optional trailing action; step pill (`primarySoft` bg, `primary` text) on flows.

---

## Screen inventory (screenshot filename → app screen)
Row 1 — core loop: `Main` (Home), `Tailor1_Paste`, `Tailor2_Match`, `Tailor3_Result`
Row 2: `Onboarding`, `CvBuilder` (Experience), `Templates`, `CoverLetter`, `Paywall`
Row 3: `Splash`, `Login`, `Register`, `CvBuilder_Personal`, `CvBuilder_Education`, `CvBuilder_Skills`
Row 4: `CvBuilder_Projects`, `CvBuilder_Summary`, `CvPreview`
*(Still to design: ATS Checker standalone, Interview Prep, Job Tracker, Settings, dark theme.)*

## Prototype / navigation flow
Splash → Login ↔ Register → Onboarding → Home.
Home hero "Tailor to a Job" → Tailor1 → Tailor2 → Tailor3 → (Cover letter / Save & export).
Home → CV Builder (Personal → Education → Experience → Skills → Projects → Summary) → CV Preview → Export.
Export when free quota used → Paywall.

## Principles baked into the design (keep in code)
- **Fair export:** first clean export free; paywall is honest — no countdowns, no auto-renew traps.
- **Templates are ATS-safe:** single-column reading order, selectable text, no critical info in images.
- **Truthful AI:** tailoring/summary never invents experience; unknown metrics shown as `[add %]` placeholders.
- **PPP pricing** shown in local currency on the paywall (BDT in the mock).

## TODO
- Dark theme token set (design is light-only so far) — derive and add before shipping dark mode.
