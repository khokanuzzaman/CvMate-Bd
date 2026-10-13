# CvMate QA pass — iOS Simulator

Branch `claude/qa-pass` (off `origin/main` @ `fbadd2c`). Flutter 3.44.0 / Dart 3.12, Xcode 26.6, iOS 26.5 simulators.
`USE_MOCK_AI=true`. Every test drives the **real app** (real router, Riverpod, Hive, Firebase Auth) on a simulator.

## Result

| | |
|---|---|
| Integration suite | **21 tests, 21 passing** on iPhone 17e (390×844 pt), iPhone SE 3rd gen (375×667 pt) and iPhone 17e at 1.3× text |
| 2× text scale | 17e 20/21, SE 19/21 — the misses are harness limits plus real layout findings, see [Large text](#large-text-stress-matrix) |
| `flutter analyze` | clean |
| `flutter test` | **432 passed**, 0 failed |

### Issues by severity

| Severity | Found | Fixed in this PR | Left for you |
|---|---|---|---|
| Blocker | 2 | 2 | 0 |
| Major | 12 | 9 | 3 |
| Minor | 13 | 1 | 12 |

Every fix has a regression test (the test was run red without the fix, green with it).

## Follow-up (this PR, stacked on #16)

All four items from the "Needs your decision" list were decided and are fixed here, each with a regression test:

| Item | Change | Tests |
|---|---|---|
| Text scale | App-wide clamp at **1.5×** (`TextScaleClamp` in the `MaterialApp` builder). Above 1.3× side-by-side button pairs stack vertically (`AdaptiveButtonRow`: builder Back/Continue, Tailor Cover letter/Save & export, Cover letter Regenerate/Export, Preview Template/Export PDF) and `SegmentedToggle` (the cover-letter **Tone** control) stacks its options. Also: long keyword chips wrap instead of overflowing (43 px on SE, 28 px on 17e at 1.5×). | `text_scale_clamp_test`, `adaptive_button_row_test`, `segmented_toggle_test`, `app_chip_test`; integration: a strict *no layout overflow anywhere in the run* test at 1.5× and 2× on both devices |
| Paywall | Only the call-to-action is pinned; the "not available" note and footer line scroll with the page. On short screens (< 700 pt) the header and cards tighten so Monthly, Yearly and the one-time option are all on the first screen of an iPhone SE. | `paywall_small_phone_test` (375×667, real fonts); integration assertion on the device |
| Cover letter | Reopening still shows the last letter; the ⋮ menu has **New letter** (asks first only when the letter was never saved as a draft). | `cover_letter_screen_test` ×3; integration flow |
| Tailor | **Start over** asks first on every page whenever there is something to lose (pasted post, title/company, match or tailored CV); on a still-empty paste page there is nothing to lose, so it does not ask. | `tailoring_screen_test`; integration flow |
| Export name | `staff_nurse_cv.pdf`, not `staff_nurse_cv_cv.pdf` (no suffix when the title already has a `cv` word). Closes Q-26. | `cv_pdf_service_test` |

Result: the integration suite (now 24 tests with the strict overflow check) passes at **1.0× and 1.5× on iPhone 17e and iPhone SE**, and at 2.0× on both (the app sees 1.5×; an integration test asserts that).

## How to run it

The suite uses the **Firebase Auth emulator** only — it refuses to start without `QA_AUTH_EMULATOR_HOST`, so it cannot create users in the production project. Cloud sync (Firestore) and analytics are stubbed in the test app, because the Firestore emulator needs Java 21 (only 17 is installed here) and the Auth emulator was what was asked for.

```sh
# 1. emulator (demo- project id: cannot reach production)
firebase emulators:start --only auth --project demo-cvmate

# 2. one flow-by-flow run on a simulator; screenshots land in build/qa/<flow>/<step>.png
flutter drive -d <simulator-id> \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1 \
  --dart-define=QA_RUN=main --dart-define=QA_TEXT_SCALE=1.0 \
  --dart-define=QA_HOST_OUT="$PWD/build/qa"
```

`QA_RUN` prefixes the screenshot folder (`build/qa/stress-se-2.0/…`), `QA_TEXT_SCALE` sets the system text size. Screenshots and exported PDFs (`build/qa/cv-builder/export-1.pdf`, `build/qa/stress-long/extreme.pdf`) are written to `build/`, which is gitignored.

`integration_test/qa_app_main.dart` is a **test-only** entrypoint (the real app wired to the same emulator) for exploring by hand. It lives outside `lib/`, so it can never be part of a release build.

### What the tests cover

| Flow (`integration_test/flows/`) | Covers |
|---|---|
| `auth_flow` | splash → onboarding → register (8-char rule, 7 rejected) → home; logout → login (6 chars ok, 5 rejected, wrong password); onboarding shows once (relaunch) |
| `cv_builder_flow` | all 7 steps with validation, preview, template switch, export #1 free (PDF captured), export #2 → paywall; leave mid-way, cold restart, reopen (auto-save) |
| `tailoring_flow` | nurse job post → match → tailor → edit → cover letter pre-filled → copy → Start over asks first (and on the Match page) |
| `cover_letter_flow` | validation, generate, tone, regenerate, edit, export, recent drafts, delete asks first |
| `ats_flow` | report, CV picker, **every Fix opens the right builder step** (10/10), ⋮ actions, check-against-job-post, AI sheet |
| `interview_flow` | setup, questions, practice sheet, favorite, Generate more, বাংলায় দেখো asks first, ⋮ menu, no-CV path |
| `tracker_flow` | empty, add (validation), edit, status chip, filter, search, no-match, delete asks first |
| `profile_nav_flow` | plan badge, Go Pro → paywall, language, theme, privacy & terms, settings, logout; guest profile; forgot password; every bottom-nav tab and back button; Home quick actions |
| `stress_flow` | extreme values + Bangla (preview, PDF, Tailor, tracker), **forced AI outage on every AI surface**, empty states |

Not exercised by the tests, so checked by hand: the native iOS share sheet (see [Manual checks](#manual-checks)).

---

## Fixed in this PR

| ID | Sev | Screen | Problem | Steps | Fix + regression test |
|---|---|---|---|---|---|
| Q-01 | **Blocker** | iOS build | `flutter run/build` for iOS fails at `pod install`: `cloud_firestore` needs iOS 15, the app targeted 13. The app could not run on any iPhone from `main`. | `flutter build ios --simulator` | Deployment target → 15.0 (`Podfile`, `project.pbxproj`). Flutter 3.44 also auto-migrated `AppDelegate`/`Info.plist` to the UIScene lifecycle; those are included. The whole integration suite is the regression test. |
| Q-02 | **Blocker** | Any release build | A release build with the default config silently ships the **mock AI** (canned tailoring, cover letters, interview questions). | `flutter build apk --release` (no defines) | `EnvConfig.aiConfigurationProblem`: `main()` throws a `StateError` in release unless `USE_FIREBASE_AI=true`; `aiCareerServiceProvider` also refuses to hand out the mock. `test/core/config/env_config_test.dart`. README + `.env.example` document it. |
| Q-03 | Major | CV builder · Personal | After a failed **Continue** the full-width snackbar covers **Back / Continue** for ~4 s, so the primary buttons can't be tapped. `shots: build/qa/cv-builder/03-step1-validation.png` | Open a new CV, tap Continue with nothing filled in | Footer moved to `Scaffold.bottomNavigationBar` (snackbars lay out above it). `cv_builder_screen_test`: "the validation snackbar never covers Back / Continue". |
| Q-04 | Major | Tailor 2/3 | An AI error snackbar covers **Tailor my CV**, the button you need to retry. | Force an AI failure, tap Tailor my CV | `TailorPageScaffold` footer in `bottomNavigationBar`. `tailoring_screen_test`: "an AI error snackbar does not cover Tailor my CV". |
| Q-05 | Major | Interview prep | A failed first **Generate questions** shows **nothing**: the error text is at the end of the setup form, below the fold, and the Generate button hides any snackbar. | Force an AI failure, tap Generate questions | Failure now also shown as a snackbar; footer in `bottomNavigationBar`. `interview_prep_screen_test`: "a failed first generation…". |
| Q-06 | Major | Cover letter (setup) | Same as Q-05: failed **Generate** is invisible. | Force an AI failure, tap Generate | Same fix, both views. `cover_letter_screen_test`: "a failed Generate is announced…". |
| Q-07 | Major | CV export (PDF) | A project description typed with the builder's own "•" bullets prints as an **empty box** in the exported PDF (Helvetica has no glyph; experience bullets were already converted). `build/qa/cv-builder/export-1.pdf` | Add a project with "• …", export | `CvPdfTemplateBuilders.pdfSafeText`. `cv_pdf_service_test`. |
| Q-08 | Major | AI Improve | At 1.3× text (and with any long CV title) the "Improvement type"/CV dropdowns overflow (6.3 px at 1.3×, 137 px at 2×) and "Open CV Builder" wraps to 3 lines. `build/qa/stress-17e-1.3/nav/07-quick-improve-cv.png` | Home → Improve CV at text size 1.3 | `isExpanded` + ellipsis on the dropdowns. `ai_improve_screen_test` (1.0/1.3/2.0, long title). |
| Q-09 | Major | Bottom nav (every tab screen) | At 2× text the fixed 64 px bar overflows by 26 px and breaks "Tracker" into "Tracke / r". | Set text size 2×, open Home | Labels capped at 1.3× and single-line. `bottom_nav_bar_test`. |
| Q-10 | Major | Profile | At 2× the "Theme" label is squeezed to one letter per line ("Th / e / m") beside the selector. | Text size 2×, Profile | `SettingsRow` wraps the trailing widget under the label; the Theme selector scales down instead of overflowing. `profile_screen_test`. |
| Q-25 | Major | Every empty state (Tracker, ATS, Preview, CV list…) | At large text on a small phone the shared `CustomEmptyState` was taller than its box: on iPhone SE at 2× the Tracker empty state **overflowed 115 px and its "Add application" button was cut off and untappable**. Seen in the first iPhone SE 2× run (screenshot not kept; the rerun passes) | Shared widget is now centered when it fits and scrollable when it does not. `custom_empty_state_test` (SE-sized box, 2× text: no overflow, button reachable; and still centered when there is room). |
| Q-11 | Minor | ATS check | Every issue's example reads "Example: Example: 017XXXXXXXX…" (engine strings already start with "Example:"). `build/qa/ats/…` | Open ATS check | Duplicate prefix stripped in the row. `ats_checker_screen_test`. |

(Q-02 is also the P0 you asked for.)

---

## Known, not fixed — with your priorities

| Pri | ID | Sev | Issue |
|---|---|---|---|
| **P1** | Q-12 | Major | **Keyword extractor gives a nurse CV 0% and lists "Square Hospital" / "Dhaka" as missing.** The Tailor match step is the offline `AtsRuleEngine` (not the AI — it still produces the same result with the AI forced down). For a nurse job post (see `qa_seed.dart: nurseJobPost`) against a CV that lists Patient Care, Vital Signs, Wound Dressing, Infection Control and IV therapy: **0 % match, 0 matched chips**; "missing" = Registered Nurse, ICU, **Square Hospital**, **Dhaka**, Compassionate Registered Nurse, Provide Patient Care, Intensive Care Unit, Monitor Vital Signs. Causes: proper nouns/places are kept as skills; "Provide Patient Care" never matches the CV's "Patient Care" (no partial/phrase containment). PR #11 noted odd phrases ("that is the engine"); a non-tech CV makes it a core-loop problem. `build/qa/tailoring/04-step2-match.png`. Next PR. |
| **P1** | Q-13 | Major | **PDF export prints Bangla as boxes — in fact it drops it.** The PDF uses built-in Helvetica only. A CV with the language "বাংলা" exports as `Languages: - Native | English - Fluent`: the Bangla name is **missing**. The same applies to Bangla names, addresses and summaries (the primary market). `build/qa/stress-long/extreme.pdf`. Next PR: embed Noto Sans Bengali (already bundled in `assets/fonts/`) as the PDF fallback font. |
| **P2** | Q-14 | Minor | **Hardcoded English strings** not in `AppStrings`: CV list ("My CVs", "Create new CV", "Delete CV"…), AI Improve, Settings, Forgot password, Tracker add/edit/details forms. Left for the i18n phase. |

---

## Needs your decision

1. **(Resolved in the follow-up PR.)** **Large text (≥ 1.5×) degrades screens we redesigned.** At 2×: screen titles truncate ("Mat…", "You…", "Cover le…"), pinned action labels truncate ("Save …" for "Save & export", "Cove…", "Rege…"), the cover-letter **Tone** control crams into "ProfessionalFriendlyConfident" and overflows (137 px on iPhone 17e, 152 px on SE), the tracker "add" form overflows 115 px on SE, section labels break mid-word ("PROFESSI/ONAL"). Nothing crashes and Q-09/Q-10/Q-08 are fixed, but this is a pattern. Options: (a) cap the app-wide text scale at ~1.5×, (b) stack the two-button footers and the tone control when text is large. I did not do either — it changes every screen. At 1.3× nothing overflows (21/21).
2. **(Resolved in the follow-up PR.)** **Paywall on small phones.** On iPhone SE the pinned footer (note + button + footer text) leaves ~15 px of the Monthly/Yearly cards visible until you scroll; the one-time card is also clipped at 390×844. The design fits in one screen. `build/qa/stress-se-1.0/cv-builder/21-paywall-after-export-2.png`.
3. **(Reopen kept, New letter added in the follow-up PR.)** **Cover letter / Interview "reopen".** Opening Cover letter from Home shows the *last letter* (state survives), not the form; the form and Recent drafts are one tap away via the "Aligned to" chip. Fine if intended.
4. **(Resolved in the follow-up PR.)** **Start over on the Tailor Match page** discards the pasted job post without asking (it only asks once there is a tailored CV, per PR #11). Intended?

## Other minor findings (not fixed)

| ID | Screen | Finding |
|---|---|---|
| Q-15 | Tailor (mock AI) | Mock cover letter lower-cases the first word of the summary and drops its full stop ("…Hospital. registered staff nurse… control My focus…"); mock tailored summary appends a meta sentence ("Tailored to reflect the priorities…"). Mock only. |
| Q-16 | Interview (mock AI) | **Generate more questions** returns 6 → 6 with the mock ("No new questions"), so appending can't be verified in mock mode (the unit tests cover it). |
| Q-17 | ATS | Section scores don't reflect emptiness: a CV with a name and one word of summary scores **17** overall but Skills 88, Education 88, Projects 100. Example texts are developer-flavoured ("Flutter, Dart, Firebase…") even for a nurse CV. |
| Q-18 | CV builder · Personal | In the 2-column row the inline Phone error is truncated ("Phone number is req…"). `build/qa/cv-builder/03-step1-validation.png` |
| Q-19 | Home / CV list | "Edited 13 Oct 2026 · Classic" — the design shows relative dates ("Edited 2 days ago · Modern"). |
| Q-20 | Preview (iPhone SE) | Footer button reads "Templa…"; Tailor 2/3 title "Match res…" at 1.3×. |
| Q-21 | Tracker | Company/source line truncates early when the status pill is wide ("Evercare Hospital · via …"). |
| Q-22 | CV list, AI Improve, Settings | Still in the old visual style (large titles, plain chips); there is no design mock for them. |
| Q-23 | Login | A little more space between the Email and Password blocks than the design (the "Forgot?" row is taller). |
| Q-24 | Login | The auth emulator answers a wrong password with `wrong-password` ("Incorrect password. Please try again."); the app also maps `invalid-credential` ("Email or password is incorrect."). Both read fine; which one real Firebase returns depends on the project's email-enumeration-protection setting. |
| Q-26 | CV export | *(fixed in the follow-up PR)* Exported file is named `staff_nurse_cv_cv` — the title "Staff Nurse CV" plus a `_cv` suffix. Seen in the real iOS share sheet. |

## Verified OK (no issue)

Splash/onboarding (match the design), register 8-char rule and login 6-char rule, onboarding once, logout → login, auto-save across a **cold restart**, export #1 free / #2 paywall, all 10 ATS **Fix** buttons open the right step, Bangla regeneration asks before replacing edits, delete asks first (tracker, cover letter), long values (90-char names, 6,000-char job posts) wrap/ellipsize without overflow at 1.0× and 1.3× on both devices, empty states for every feature, forced AI errors never leave a spinner running (all surfaces: error visible after Q-05/Q-06), PDF layout with extreme values (2 pages, wraps correctly).

---

## Design differences (docs/design vs. the simulator)

Agreed in earlier PRs and therefore ignored: 7 builder pages (Training kept), extra Personal fields, photo upload disabled, no template filter chips, paper preview style, Paywall "Coming soon", ATS 7 real sections, no inline job-match/AI cards on ATS, Interview without "Based on", Profile without reminders / AI writing language, Cloud backup "On/Off", tracker counts.

Real differences:

| Screen | Difference |
|---|---|
| Login / Register | Eye (show/hide) icon on the Register password field (design has none, Login does); Google button is dimmed (disabled, agreed); Login Email↔Password gap larger (Q-23). |
| Home | Recent-CV subtitle uses an absolute date and the *template* name only (Q-19); otherwise matches, including the raised Tailor button. |
| CV builder | Title shows "New CV" until a title is set (data, not layout); progress "Step n of 7" (agreed). Fields, cards, footer match. |
| CV preview | The design shows the whole page scaled to fit (miniature); the app shows the page at reading size and scrolls. The "1 thing to fix" banner is data-dependent. |
| Template picker | No "All / ATS-safe / Simple" chips (agreed). |
| Paywall | Prices partly hidden behind the footer until scrolled (decision 2); button label "Coming soon" (agreed). |
| Tailor 1–3 | Match *values* differ (data); layout matches. Step 3 shows the summary with an extra meta sentence from the mock AI. |
| Cover letter | Matches. Letter text is mock text. |
| ATS | Duplicated "Example:" was a bug (Q-11). Otherwise matches. |
| Interview | Matches; the first card is HR (mock data) rather than Technical. |
| Tracker | App has a search icon in the header and an extra "Shortlisted" filter chip; the design has neither. |
| Profile | Matches (agreed omissions). A signed-in user without a display name shows the e-mail only. |

## Method notes and limits

- **Keyboard:** screenshots capture the Flutter surface only, not the iOS software keyboard, so the keyboard is dismissed before each screenshot. Layout *with* the keyboard up (form scrolled into a ~310 pt window) was seen only incidentally.
- **Native sheets:** the iOS share sheet (`Printing.sharePdf`, `SharePlus`) cannot be dismissed from Dart, so the tests mock those two channels; see Manual checks.
- **Firestore** is stubbed (no emulator available), **analytics** is silenced.
- Stress runs: iPhone 17e at 1.0× (baseline), 1.3×, 2.0×; iPhone SE at 1.0×, 2.0×.

## Large text stress matrix

Same 21 tests on every row (`QA_TEXT_SCALE` sets the system text size). Screenshots: `build/qa/<run>/…`.

| Device | Text | Result | Notes |
|---|---|---|---|
| iPhone 17e (390×844) | 1.0× (baseline) | **21/21** | no overflows recorded |
| iPhone SE 3rd gen (375×667) | 1.0× | **21/21** | no overflows recorded; paywall prices below the fold (decision 2), "Templa…" |
| iPhone 17e | 1.3× | **21/21** | no overflows; AI Improve (Q-08) fixed; titles start to truncate ("Match res…") |
| iPhone 17e | 2.0× | 20/21 | Cover-letter **Tone** control overflows 137 px; titles/pinned labels truncate ("Interview pr…", "Generate more qu…", "Save …"); Profile "Theme" and the nav bar fixed (Q-09, Q-10). The one miss is the Interview flow: at 2× the harness could not find the *Practice answer* button in the long scrolled list (not an app crash). |
| iPhone SE | 2.0× | 19/21 | Tone control overflows 152 px; Tracker title breaks mid-word ("Applicat/ions"), stat labels truncate ("App…", "Inte…"); the Tracker empty state is now scrollable (Q-25). Misses: the Interview step above, and Tracker's "No matching applications" wait (the empty state sits behind the bottom nav until scrolled). |

Forced-AI-outage results (all four AI surfaces, every device): an error is shown on each, no spinner is left running after 8 s, and since Q-04/05/06 the message is visible above the primary button.

## Manual checks

Done on the iPhone 17e with `integration_test/qa_app_main.dart` (`QA_SEED=true`), driven through the Simulator:

- **Preview → Export PDF** opens the real iOS share sheet: "staff_nurse_cv_cv · PDF Document · 5 KB" with Preview, Copy, Markup, Print and Save to Files. First export is free, as in the tests (the paywall after export #2 is covered by the integration test).
- **Cover letter → generate → Export** opens the text share sheet titled "Application for Registered Nurse" (Reminders, Copy, Save to Files).
- Typing in the real app with the keyboard (hardware keyboard attached to the Simulator): fields focus and keep their text; the snackbar for "Job title is required." now sits **above** the Generate button (Q-06 fix, seen live).

Not checked: the iOS **software** keyboard overlay (the Simulator was using the hardware keyboard), a physical device, and the cloud-sync path (Firestore stubbed).
