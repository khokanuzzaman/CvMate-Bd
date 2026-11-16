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
  - [ ] The app asks for your password if the sign-in is old.
  - [ ] You land on onboarding.
  - [ ] Logging in with the old email fails: the user is gone.
  - [ ] Server: the plan, unlocks and feedback are deleted, and later requests
        with that uid get 401.
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
