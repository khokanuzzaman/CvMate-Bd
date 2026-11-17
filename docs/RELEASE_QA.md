# Release QA (TestFlight, real iPhone)

Run this on a **real iPhone with the TestFlight build** before every App Store
submission.

- Tick each box. Note the build number, device and iOS version at the top of
  your copy.
- **Sandbox Apple ID:** sign out of the App Store's Sandbox Account first
  (Settings > App Store > Sandbox Account), then use the sandbox tester from
  App Store Connect.
- **Firebase DebugView:** needs a debug build with
  `--dart-define=ANALYTICS_DEBUG=true` and the `-FIRDebugEnabled` launch
  argument. TestFlight builds send analytics too, but only to the normal
  reports, which take up to 24 h.

Build: ____  Device: ____  iOS: ____  Date: ____  Tester: ____

## 1. First launch and onboarding

- [ ] Delete the app, then install it from TestFlight. The home-screen name is
      **CvMate** and the icon is the CvMate logo (PR E).
- [ ] The launch screen shows the CvMate mark with no white flash and no
      stretching (PR E).
- [ ] Onboarding shows once. **Get started** goes home, **Skip** goes home and
      **Log in** opens login.
- [ ] Kill the app and relaunch it. Onboarding does not show again.
- [ ] There is **no** "Allow tracking" (ATT) prompt at any point.

## 2. Accounts

- [ ] **Guest:** create a CV without signing in, kill the app, relaunch. The CV
      is still there.
- [ ] **Sign up:** a 7-character password is refused and 8 characters works.
      You land on home.
- [ ] **Log out**, then **log in** again: a wrong password shows an error; the
      correct one works. The CVs come back from the backup.
- [ ] **Forgot password** sends the email.

## 3. Create a CV in each style

For each style, **International**, **Gulf** and **South Asia**:

- [ ] New CV > choose the style. The right personal fields are shown by
      default (Gulf: photo, date of birth, nationality, passport, visa,
      licence; International: none).
- [ ] Fill every step and tap Next through the builder. Validation messages
      are clear.
- [ ] Add a photo (camera and library). The permission prompts read well.
- [ ] Pick each template. The preview matches.
- [ ] Bangla text (name, summary, a bullet) shows correctly in the editor,
      the preview and the PDF.

## 4. AI (when the Anthropic key is back on the server)

Before the first AI action, the **AI consent** sheet shows.

- [ ] **Not now** sends nothing: there is no request in the server log.
- [ ] **Allow AI** continues.

Run each AI action once and check the result makes sense, with nothing
invented:

- [ ] Professional summary
- [ ] Career objective
- [ ] Improve experience bullet
- [ ] Project description
- [ ] Suggest skills
- [ ] ATS suggestions
- [ ] Analyze job post
- [ ] CV/job match
- [ ] Tailor CV to a job post
- [ ] Cover letter
- [ ] Application email
- [ ] LinkedIn message
- [ ] Interview questions

Also check:

- [ ] "AI actions left" goes down by one after each action.
- [ ] A very long job post gets a clear "too long" message.
- [ ] Settings > AI features off: the next AI action asks for consent again.

## 5. Quota and paywall

- [ ] As a **free** user, use all 3 AI actions. The 4th shows "You've used all
      your AI actions" and opens the paywall (source `ai_quota`).
- [ ] The paywall shows store prices (not hard-coded), with no plan
      pre-selected.
- [ ] The paywall shows the trial wording on yearly, the auto-renew terms,
      Terms, Privacy and Restore.
- [ ] Terms and Privacy open https://api.khokan.me/cvmate/terms and /privacy.
- [ ] There are no countdowns or fake urgency.
- [ ] Close returns to where you came from.

## 6. Purchases (Sandbox)

- [ ] **Monthly:** the purchase sheet shows the right price. After paying, the
      paywall closes within about 10 s and the app shows Pro. The profile
      badge shows Pro.
- [ ] **Yearly:** the trial is shown in the sheet. After paying, the app shows
      Pro.
- [ ] **Just this CV** (one-time):
  - [ ] After paying, the export continues on that CV.
  - [ ] "AI actions left" goes up by 5.
  - [ ] Another CV is still locked.
- [ ] **Cancel** in the Apple sheet: the paywall says it was cancelled and
      nothing changes.
- [ ] **Restore** on a fresh install, signed in to the same account: Pro comes
      back. On an account with nothing to restore, it says so.
- [ ] **Cancel the subscription** in Settings > Apple ID > Subscriptions. Pro
      stays until the period ends, then turns Free. In sandbox a month is a
      few minutes.
- [ ] Server log: the RevenueCat events are applied, and `billing_events` show
      `sandbox`.

## 7. Export

- [ ] **Free:** the first export (share and print) works. The second opens the
      paywall.
- [ ] **Pro:** unlimited exports, with no paywall.
- [ ] **One CV:** the unlocked CV exports any number of times. Other CVs still
      hit the paywall.
- [ ] The PDF opens in Files and Mail with the correct layout and page breaks,
      and Bangla text is correct.

## 8. Ratings prompt rules

- [ ] **First launch:** after a successful export, no rating prompt.
- [ ] **Second launch or later:** after a successful export, the iOS rating
      sheet may appear. In TestFlight it never appears, so check that
      `review_prompt_requested` shows in DebugView instead.
- [ ] There is no prompt within 10 minutes of an AI error, a failed export or
      the paywall.
- [ ] There is no prompt after the 1st tailoring; the 2nd successful tailoring
      may ask.
- [ ] There is never a "Do you like CvMate?" question before the system sheet.
- [ ] Settings > **Rate CvMate** opens the App Store page.

## 9. Feedback

Settings > **Report a problem / Send feedback**:

- [ ] Send is disabled until you pick a category and write a message.
- [ ] Send with **Attach diagnostics** off and **reply** off. The thank-you
      screen shows. On the server, `feedback:list` shows the message, with
      no email and no diagnostics.
- [ ] Send with both ticked. The server shows the sign-in email and the app,
      iOS and device versions with the last event names. No CV text.
- [ ] As a guest, the "reply to me" box is not offered.
- [ ] The 6th message within an hour is refused politely.

## 10. Analytics (Firebase DebugView, debug build with `ANALYTICS_DEBUG=true`)

- [ ] DebugView shows the events listed in `docs/ANALYTICS_EVENTS.md` as you
      walk through the app.
- [ ] Every parameter is an enum or a bucket. No names, emails, CV text or job
      post text anywhere.
- [ ] `screen_view` uses route names such as `cv-preview`, never paths with
      ids.
- [ ] Settings > Privacy > **Share usage analytics** off: events stop at once.
      Back on: they resume.
- [ ] A normal debug build without `ANALYTICS_DEBUG` sends nothing to
      DebugView.

## 11. Crashlytics

- [ ] Force a test crash: in a debug build run with `ANALYTICS_DEBUG=true`,
      trigger an uncaught error, for example from a temporary debug button.
      Relaunch the app.
- [ ] Within about 5 minutes the crash shows in Firebase > Crashlytics. It
      has the error **type** and the stack, but **no message text**. The user
      id is a 64-character hash, not an email.
- [ ] A TestFlight build symbolicates: the dSYMs were uploaded by the "Upload
      Crashlytics dSYMs" build phase.
- [ ] Analytics switch off, then force another crash: no new report arrives.

## 12. App Check

- [ ] The server is in **monitor** mode. For the TestFlight build, check that
      the log has no `app_check_failed` lines:
      `docker compose logs api --since 24h | grep app_check_failed`
- [ ] A debug build on the simulator **without** a registered debug token
      shows `app_check_failed reason=invalid` or `missing`. That is expected.
      With the token registered (docs/APP_CHECK.md), there are none.

## 13. Account deletion

- [ ] **Signed in:** Settings > **Delete account**. The confirmation shows the
      subscription note and the *Manage subscriptions* link.
  - [ ] With a sign-in older than 5 minutes the server answers
        `reauth_required` and the app asks for your password; nothing is
        deleted before you enter it. A fresh sign-in is not asked.
  - [ ] You land on onboarding.
  - [ ] Logging in with the old email fails: the user is gone.
  - [ ] Server: the plan, unlocks and feedback are deleted, and later requests
        with that uid get 401.
  - [ ] Firestore: `users/<uid>` and its `cvs` are gone (Firebase console).
- [ ] **Guest:** Delete account removes the local data only, and you land on
      onboarding.
- [ ] After deletion, DebugView shows a new app instance.

## 14. Offline

- [ ] Airplane mode on:
  - [ ] CVs open and edit, and export works if allowed.
  - [ ] AI shows "You are offline…".
  - [ ] The paywall shows its retry.
  - [ ] Feedback shows an error and keeps the message.
- [ ] Airplane mode off: everything works again without restarting the app.

## 15. Devices, text and accessibility

- [ ] **Small iPhone** (SE or mini) and **large iPhone** (Pro Max): no clipped
      or overlapping text on onboarding, the builder, the paywall, Settings or
      Feedback.
- [ ] **Larger text** (Settings > Accessibility > Larger Text, near maximum):
      the layouts still fit, because the app caps text at 1.5×.
- [ ] **Dark mode**: every screen is readable, including the paywall, feedback
      and dialogs.
- [ ] **VoiceOver basics:**
  - [ ] Onboarding, home, the builder Next/Back, the paywall plans and buy
        button, the Settings switches and the Feedback form are announced
        with sensible labels.
  - [ ] You can buy and go back using VoiceOver alone.
- [ ] Rotation: the app stays in portrait as expected on iPhone. It is
      iPhone-only, so the iPad simply runs the iPhone build.

## 16. Store listing sanity

- [ ] The App Store name reads "CvMate: AI CV & Resume". The home-screen name
      is "CvMate".
- [ ] The App Privacy answers match `docs/APP_PRIVACY_LABEL.md`.
- [ ] The privacy policy and terms URLs work, and the policy mentions
      analytics, crash reports, feedback and App Check.
- [ ] The review notes give a sandbox account and say that AI needs consent
      first.

## Results

### 17 Nov 2026: simulator billing run (Xcode StoreKit testing)

- **Build:** Debug, from Xcode, PR #27 branch (includes #24–#26). Run with
  `ANALYTICS_DEBUG=true` and `-FIRDebugEnabled`.
- **Setup:** `USE_MOCK_AI=true`, `USE_FAKE_BILLING=false`, RevenueCat iOS key
  from `.env`.
- **Device and store:** iPhone 17 Pro simulator, iOS 26.5. Purchases go
  through Xcode's local store (`ios/Runner/CvMate.storekit`, attached to the
  Runner scheme's Run action only), with the StoreKit test certificate
  uploaded to RevenueCat.
- **Account:** a throwaway test account.

**How to repeat it:** select the iPhone simulator in Xcode and press Run. The
StoreKit file only works when Xcode launches the app, not with `flutter run`.
The file is not part of any target, so it never ships in the app.

| Item | Result | Evidence |
|---|---|---|
| Yearly (trial): StoreKit transaction | PASS | The test sheet shows "1-week free trial, then $29.99 per year starting Nov 24", then "Your purchase was successful [Environment: Xcode]". |
| Yearly: RevenueCat CustomerInfo | PASS | `pro` is active from `cvmate_pro_yearly`, period type `trial`, expires 2026-11-24, `is_sandbox`. |
| Yearly: `GET /v1/me/entitlement` shows Pro | PASS, slow | RevenueCat *does* send webhooks for Xcode StoreKit purchases, but late. The plan was still Free 3½ min after the purchase, and Pro by 4½ min. The app's 15 s poll ended with "Payment received. Activating can take a minute", and the plan updated on a later refresh. |
| One CV: StoreKit transaction and RevenueCat | PASS | "Just this CV, $3.99, one-time charge", then success. `non_subscriptions.cvmate_one_cv` in CustomerInfo. |
| One CV: +5 AI actions | PASS | "AI actions left" went from 3 (Free) to 105 (Pro 100 + 5). |
| One CV: export unlock | NOT TESTED, needs TestFlight | Pro was already active, so exports pass the Pro gate before the unlock. Retest with a separate account that buys only one CV. |
| Restore after a fresh install | PASS (see notes) | After the reinstall, Profile > Restore purchases opens the paywall. Restore there gives `restore_result = restored`, then Pro and 105 actions. |
| Expire/cancel in Transaction Manager, plan drops to Free | NEEDS TESTFLIGHT | Uninstalling the app removed Xcode's local transactions, so Transaction Manager showed "No Transactions". RevenueCat's docs also say cancellations and refunds made there do not reach RevenueCat, so our server would never get the EXPIRATION. |
| Feedback (no diagnostics, no reply) | PASS (app side) | Send stays disabled until a category and message are given. The thank-you screen shows, and `feedback_sent` has `category=other`, `diagnostics=no`. Check `feedback:list` on the server. |
| Feedback with both boxes ticked | NOT RUN | |
| Test crash in Crashlytics | PASS (app side) | An uncaught `StateError` was thrown in the running app through the Dart debug service, with no code change. Crashlytics uploaded at once (HTTP 200 from `crashlyticsreports-pa`). The test message is in none of the local Crashlytics files. Check in the console that the issue shows the type, the stack and no message. |
| Events in Firebase DebugView | PASS (app side) | Debug mode was on. See below for what was sent. Check that DebugView shows them. |
| Account deletion: confirmation dialog | PASS | Shows the subscription note and the *Manage subscriptions* link. |
| Account deletion: password re-check | PASS | Sign-in older than 5 minutes gives `needs_password`, then "Confirm your password". |
| Account deletion: first attempt | FAIL | The server data was deleted, then the Firestore step failed ("Couldn't delete your CV backup"). The deployed Firestore rules were the default deny-all; the repo's `firestore.rules` had never been deployed. The Firebase user was left in place, still signed in. |
| Account deletion: retry after deploying the rules | PASS | `account_delete_result = deleted`; the app lands on onboarding. |
| After deletion: `GET /v1/me/entitlement` with the old token | PASS | 401 `unauthenticated`, "This account was deleted." |
| After deletion: Firebase Auth | PASS | `accounts:lookup` gives 400 `USER_NOT_FOUND`. It gave 200 before. |
| After deletion: Firestore `users/<uid>` and `users/<uid>/cvs` | PASS, but weak | 404 and 0 documents. They were already empty, because no backup was ever written under the deny-all rules. Re-test with a backed-up CV. |

**Events sent:**
- `app_open`, `onboarding_step`, `onboarding_complete(choice=log_in)`;
- `sign_up(method=email)`;
- `paywall_view(source=profile|restore)`;
- `purchase_start` and `purchase_result(result=success)` for `yearly` and
  `one_cv`;
- `restore_result(result=restored)`;
- `feedback_open`, `feedback_sent`;
- `screen_view` with route names (`onboarding`, `login`, `register`, `home`,
  `profile`, `paywall`, `settings`, `feedback`).

Every parameter is an enum.

**Native SDK checks, all as designed:**
- Analytics collection starts disabled and is enabled at runtime.
- The log says "IDFA will not be accessible".
- Ad storage consent is denied.

#### Findings

1. **Wrong paywall subtitle.** The paywall says "You've used your **free
   export**" when it is opened from Profile (*See plans*) or *Restore
   purchases*, where no export happened.
2. **Old branding in About.** Settings > About still says "CareerMate BD —
   AI Career Assistant for Bangladesh … helps Bangladeshi job seekers".
3. **Placeholder support text.** Settings > Support / contact opens a
   placeholder dialog ("Add your future support email or help center before
   release"). Fix this before submission.
4. **Profile > Restore purchases goes through the paywall.** It opens the
   paywall instead of restoring directly, so restoring takes one extra tap.
5. **Sign-in survives deleting the app.** Firebase keeps it in the iOS
   Keychain, so a reinstall opens straight to Home, signed in. This is normal
   iOS behaviour. Decide whether a reinstall should sign out.
6. **Pro activation takes minutes.** Server activation after an Xcode
   StoreKit purchase took 3–5 minutes. Measure it again on TestFlight. If
   sandbox is just as slow, consider a longer poll or a "Refresh" action on
   the paywall's "Activating…" message.
7. **Expected App Check rejections.** Without a registered debug token,
   `firebaseappcheck.googleapis.com` answers 403 on the simulator. This is
   expected; the server is in monitor mode.
8. **Firestore rules were never deployed (root cause of the deletion
   failure).** Production still had the default deny-all rules, so every
   Cloud backup read and write failed and account deletion stopped at the
   Firestore step. The rules in `firestore.rules` were deployed on 17 Nov
   2026. See the new pre-release check below.
9. **Cloud backup showed "On" while every write failed.** Surface backup
   errors in the UI, for example a "Backup failed, tap to retry" state on the
   Cloud backup row and in the builder, instead of a silent failure.
10. **Account deletion must not depend on Firestore access from the app.**
    Move the Firestore cleanup (`users/<uid>/**`) and the Firebase Auth user
    deletion into the server's `DELETE /v1/me` handler, using the Admin SDK.
    The app then makes one call. Apple's guideline 5.1.1(v) needs deletion to
    always work, whatever the state of the client rules or App Check.
    *Fix in review:* cvmate-api `DELETE /v1/me` now does all three steps with
    the Admin SDK (needs the project's service-account key on the server,
    see its DEPLOY.md). The app makes the one call, then signs out and wipes
    the device. The server asks for a sign-in from the last 5 minutes
    (`reauth_required`); the app then asks for the password and retries once.
11. **A failed deletion leaves a half-deleted account.** The server data was
    gone (401 on every request) while the user stayed signed in with a
    Firebase account. Retrying finishes the job. Finding 10 removes this
    state. *Fix in review:* if a server step fails the app stays signed in
    with its device data and shows a retry message; the retry finishes.
12. **Google sign-in placeholder removed; adding Google later needs Apple
    too.** The disabled "Continue with Google" / "Sign up with Google"
    button ("coming soon") was removed from Login and Register, since App
    Review rejects placeholder features. If Google sign-in is added later,
    Sign in with Apple is required as well (guideline 4.8), and the
    delete-account re-authentication must support both: on
    `reauth_required` it re-authenticates with the user's own provider
    (Google or Apple credential), not the password, with a test per
    provider on the app and the server.

#### Run before every release

- [ ] Deploy the Firestore rules from the repo:
      `firebase deploy --only firestore:rules --project careermatebd`.
- [ ] Then open Firebase console > Firestore Database > **Rules**. The
      published rules should match `firestore.rules`: owner-only access under
      `users/{userId}/**`, everything else denied. The publish time should be
      the deploy you just ran.
- [ ] Open Firebase console > App Check > **APIs**. Cloud Firestore and
      Authentication should be **Unenforced** (see `docs/APP_CHECK.md`),
      unless you have decided to enforce them.
- [ ] Sign in on a test build, create a CV and check that it appears under
      `users/<uid>/cvs` in the Firestore console.
