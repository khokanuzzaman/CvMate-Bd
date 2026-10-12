# Next session: remaining feature screens

Paste the block below into the coding agent (local, real Flutter toolchain). Designs are in
`docs/design/`: `ATS Checker@2x.png`, `Interview Prep@2x.png`, `Job Tracker@2x.png`,
`Profile & Settings@2x.png`.

```
Implement the remaining feature screens to match the design. ONE PR off main.

DESIGN REFERENCE
- docs/design/: "ATS Checker@2x.png", "Interview Prep@2x.png", "Job Tracker@2x.png",
  "Profile & Settings@2x.png". If any is missing, STOP and tell me.
- DESIGN_TOKENS.md; reuse lib/core/theme + lib/core/widgets and the patterns from earlier screens.

KEEP ALL LOGIC: ats_checker (rule engine, AI target, controller), interview_prep (controller,
sessions, answer styles), job_tracker (controller, repository, statuses, message templates),
settings (app preferences controller), auth logout, entitlement service. Only the UI changes,
except where noted below.

BUILD
- ATS Checker: CV picker, ScoreRing with the real score, sub-scores ONLY if the rule engine
  already reports per-category scores (if not, show the category list without numbers, don't
  invent them), issues grouped by severity with HIGH/MED/LOW pills, "Fix" opens the relevant
  builder step, "Check against a job post" goes to Tailor 1 with the CV pre-selected.
- Interview Prep: context chip, category filter chips, question cards with the existing answer
  style shown as STAR, Practice + "বাংলায় দেখো" (use the existing Bangla output option if there
  is one; if not, leave the button out and tell me), Generate more.
- Job Tracker: status counts, filter chips, application cards with status pill and next-action
  hint derived from existing data (interview date, days since applied). Keep the add/edit/details
  flows, restyled. Tracker becomes the bottom-nav Tracker tab.
- Profile & Settings: account card with plan badge from EntitlementService, Go Pro -> paywall,
  language rows (keep existing preferences), theme selector, reminders toggle only if a reminder
  preference exists, cloud backup status from the sync layer, Restore purchase (disabled),
  Privacy & terms, Log out. This becomes the bottom-nav Profile tab.
  Theme: Light only is wired; show Dark/Auto disabled with "coming soon" until dark tokens exist.

TESTS
- Extend the screenshot test with these 4 screens; flutter analyze clean, all tests green locally
  and in CI.
```

## After that
1. Run the app on a device or simulator end to end (register -> CV -> export twice -> tailor ->
   cover letter -> copy) and note anything broken.
2. Dark theme: design the dark token set first, then implement.
