# Analytics events

CvMate logs a small, fixed set of events to **Firebase Analytics** and sends crash
reports to **Firebase Crashlytics**. This file is the catalogue. The code that
enforces it is in `lib/shared/services/analytics/`:

- `analytics_events.dart`: the event factories and `AnalyticsSchema`, which
  lists every allowed parameter and value.
- `analytics_params.dart`: the enums every parameter value comes from.
- `analytics_service.dart`: the only class that talks to Firebase Analytics.
  No screen calls Firebase directly.

## Rules

- **No content, ever.** Events never contain CV text, names, emails, phone
  numbers, job post text or any other free text. They contain only enum
  values, small ints and buckets.
- Every event must match `AnalyticsSchema`. An event with an unknown parameter
  or a value outside the allowed set fails an assert, so tests catch it. In
  release builds the event is dropped. `test/shared/services/analytics/analytics_schema_test.dart`
  builds every event with every value, and checks that free text is refused.
- **Screen views** use the GoRoute *name* (`cv-preview`), never the path or
  the query, which can carry ids.
- **No advertising ID.**
  - iOS uses `FirebaseAnalytics/Core` without IdentitySupport
    (`$FirebaseAnalyticsWithoutAdIdSupport` in the Podfile), so AdSupport is
    not linked.
  - Android removes the `AD_ID` permission.
  - Ad storage, ad user data and ad personalisation consent are always
    denied.
  - There is no App Tracking Transparency prompt, because we do not track
    across apps. IDFV collection stays on.
- **When anything is sent**: only in release builds, or in debug builds run
  with `--dart-define=ANALYTICS_DEBUG=true`, **and** only while Settings >
  Privacy > *Share usage analytics* is on (the default).
  - Native collection starts **off**: the `Info.plist` and
    `AndroidManifest.xml` flags are false. The app turns it on at runtime, so
    nothing is sent before Dart starts.
  - Turning the switch off takes effect at once: the Dart side drops every
    event and crash report, and unsent crash reports are deleted.
- **Crashlytics**:
  - A crash sends the exception *type* and the stack trace, never the
    message, because a message can quote user text.
  - Non-fatals send `area:code` only, for example `ai:ai_unavailable` or
    `billing:purchase_failed`.
  - The user id is a SHA-256 hash of the Firebase uid, never the email.
- **Account deletion** resets the Analytics instance id
  (`resetAnalyticsData`), so the device becomes a new, unlinked user.
- **"Report a problem" diagnostics** can include the names of the last 20
  events, never their parameters. This is only sent when the user ticks
  *Attach diagnostics*.

## User property

| Property | Values | Set when | Answers |
|---|---|---|---|
| `plan` | `free`, `pro` | The server entitlement loads or changes | How behaviour differs between free and Pro users |

## Events

### App and onboarding

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `app_open` | – | Once per launch, after the analytics switch is read | How many people open the app (DAU/MAU, retention) |
| `onboarding_step` | `step` (1) | The onboarding screen is shown | How many first-run users see onboarding |
| `onboarding_complete` | `choice`: `get_started` \| `skip` \| `log_in` | A button on onboarding is tapped | Do new users start as guests, skip, or log in? |
| `screen_view` | `screen_name` (route name) | Every page route shown (not dialogs or sheets) | Where do users spend time and drop off? |

### Account

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `sign_up` | `method`: `email` | An account is created | How many guests become accounts? |
| `login` | `method`: `email` | A login succeeds | Do people come back on new devices? |
| `logout` | – | A logout succeeds | How often do people sign out? |
| `account_delete_start` | `account`: `guest` \| `signed_in` | *Delete account* is confirmed (not on the password retry) | How many users try to delete their account? |
| `account_delete_result` | `account`, `result`: `deleted` \| `failed` | Deletion ends | Does deletion work, or does it fail? |

### CV building and ATS

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `cv_created` | `style`: `international` \| `gulf` \| `south_asia` | A new CV's market style is chosen (or its first step is completed) | Which markets do users write CVs for? |
| `cv_section_completed` | `section`: `personal_info` \| `summary_objective` \| `education` \| `experience` \| `skills` \| `projects` \| `training` \| `languages` \| `template` \| `preview` | A builder step passes validation and *Next* is tapped (once per step per CV in a session) | Where in the builder do people give up? |
| `template_selected` | `template_id`: `classic` \| `modern` \| `minimal` \| `professional` \| `fresher` | A template is confirmed | Which templates are worth keeping? |
| `ats_check_run` | `kind`: `cv` \| `job_match`, `score_bucket`: `0_39` \| `40_59` \| `60_79` \| `80_100` | The ATS screen opens or the CV changes (`cv`), or *Check job match* is tapped (`job_match`) | How good are users' CVs, and does the score improve? |

### AI

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `ai_consent_shown` | – | The AI consent sheet opens | How many users are asked for AI consent? |
| `ai_consent_result` | `result`: `allowed` \| `not_now` | The sheet is answered | What share of users allow AI? |
| `ai_action_start` | `action` | An AI request starts (after consent) | Which AI features are used? |
| `ai_action_result` | `action`, `result`: `ok` \| `quota` \| `rate_limited` \| `unavailable` \| `too_long` \| `offline` \| `error`, `latency_bucket`: `lt_1s` \| `1_3s` \| `3_10s` \| `10_30s` \| `30_60s` \| `gt_60s` | An AI request ends | Is AI reliable and fast enough? |
| `quota_exhausted` | `action` | The server answers "out of AI actions" | How often do free users hit the limit, and on what? |

`action` is one of: `professional_summary`, `career_objective`,
`experience_bullet`, `project_description`, `suggest_skills`, `cover_letter`,
`application_email`, `linkedin_message`, `interview_questions`,
`ats_suggestions`, `analyze_job_post`, `cv_job_match` or `tailor_cv`.

### Paywall and purchases

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `paywall_view` | `source`: `cv_preview` \| `cv_pdf_preview` \| `tailoring` \| `profile` \| `restore` \| `ai_quota` \| `other` | The paywall opens | Which moments lead people to the paywall? |
| `purchase_start` | `package`: `monthly` \| `yearly` \| `one_cv` | The buy button is tapped | Which plans do people try to buy? |
| `purchase_result` | `result`: `success` \| `cancelled` \| `pending` \| `failed`, `package` | The store answers | Conversion rate per plan, and failure rate |
| `restore_result` | `result`: `restored` \| `nothing_to_restore` \| `cancelled` \| `failed` | *Restore purchases* ends | Does restore work? |

### Export

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `export_start` | `source`: `cv_preview` \| `cv_pdf_preview` \| `tailoring`, `format`: `share` \| `print` | Share or print is tapped | How many people try to export? |
| `export_result` | `source`, `format`, `result`: `ok` \| `paywall_closed` \| `failed`, `gate` (only when `ok`): `pro` \| `unlock` \| `free` \| `purchased` | The export ends | How do exports get through (Pro, unlock, free, bought just now), and how many stop at the paywall? |

### Ratings and feedback

| Event | Params | Fires when | Question it answers |
|---|---|---|---|
| `review_prompt_requested` | `trigger`: `export` \| `tailoring` | CvMate asks iOS or Android for the rating sheet. The OS decides whether it actually appears, and does not tell us. | How often do we ask, and after which success? |
| `feedback_open` | – | *Report a problem* opens | How many people look for help? |
| `feedback_sent` | `category`: `bug` \| `ai_result` \| `payment` \| `other`, `diagnostics`: `yes` \| `no` | Feedback is stored on the server | What do people report most? |

## Rating rules

`ReviewPrompter` asks for a rating only when all of these hold:

- It is a success moment: an export succeeded, or the user's 2nd or later
  successful AI tailoring.
- It is not the first launch.
- There has been no request in the last 60 days. iOS also caps the sheet at
  3 times a year.
- There has been no error, failed export or paywall view in the last 10
  minutes.
- There is no pre-question. Everyone gets the system sheet, which is no
  review gating.

*Settings > Rate CvMate* always opens the App Store page (id 6835302052).

## Removed events

These were renamed or folded into the events above before launch:

| Old event | Replaced by |
|---|---|
| `cv_exported` | `export_start` / `export_result` |
| `tailoring_started` / `tailoring_completed` | `ai_action_start` / `ai_action_result` with `action=tailor_cv` |
| `ai_action_used` | `ai_action_result` |
| `paywall_viewed` | `paywall_view` |

## Checking it

- **DebugView**: run
  `flutter run --dart-define=ANALYTICS_DEBUG=true`, then add the Xcode launch
  argument `-FIRDebugEnabled`. Open Firebase console > Analytics > DebugView.
- **Test crash**: with `ANALYTICS_DEBUG=true`, throw an error from a debug
  button, then relaunch the app. Reports are sent on the next launch.
