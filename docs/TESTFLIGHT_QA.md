# TestFlight QA (real iPhone)

What to check on a **TestFlight build on a real iPhone** before App Review.
It covers what the simulator cannot: the App Store sandbox, App Attest,
symbolicated crashes and production analytics. The full release list is
`docs/RELEASE_QA.md`; this file is the TestFlight subset.

Build: ____  iPhone / iOS: ____  Date: ____  Tester: ____

## Before you start

- [ ] The build was made as in *Making the build* below (Release,
      `--split-debug-info`, Dart symbols uploaded, `.env` with
      `USE_MOCK_AI=false`).
- [ ] Server: `curl -s https://api.khokan.me/healthz` shows `ok: true` and the
      commit you expect, with cvmate-api#14 deployed (database
      `user_version` 8).
- [ ] **Sandbox Apple ID:** on the iPhone, open Settings > App Store >
      Sandbox Account and sign in with a sandbox tester from App Store Connect
      (Users and Access > Sandbox). Your real Apple ID stays signed in for
      everything else.
- [ ] Use a **new CvMate test account** for each purchase test (sign up in
      the app). Delete it at the end (section 7).

Sandbox subscriptions run on a faster clock: the 1-week free trial lasts
about **3 minutes**, and a year renews about every **hour**.

## 1. Buy Yearly

- [ ] Profile > See plans > **Yearly** > Start free trial. The sheet says
      *[Environment: Sandbox]*. Confirm with the sandbox account.
- [ ] Within about **5 seconds** Profile shows **Pro** and *AI actions left:
      100*, with the "You're Pro" message. This comes from the app calling
      `POST /v1/me/entitlement/sync` (PR #49 / cvmate-api#13), not from the
      webhook.
- [ ] Server log (optional): `docker compose logs api | grep -E
      "entitlement_sync|revenuecat_event"` shows the sync, then the
      `INITIAL_PURCHASE` webhook a little later. No uid or email in the line.

## 2. Buy one CV (separate test account)

Use a **second** new account that is not Pro.

- [ ] Build a short CV, then Preview > Export PDF. The first export is
      free; export **a second CV** to reach the paywall. It must say
      "You've used your free export" (PR #53).
- [ ] Choose **Just this CV — $3.99**, confirm in the sandbox sheet.
- [ ] Within about **5 seconds** the app says "Purchase complete", the
      export continues and the share sheet opens; *AI actions left* went up
      by 5. This comes from purchase sync reading the one-time purchase
      (cvmate-api#14), not from the webhook.
- [ ] Server log: `entitlement_sync` with `oneTimeGranted: 1`, then the
      `NON_RENEWING_PURCHASE` webhook a little later with outcome
      `one_time_already_granted`: granted **once**. Profile still shows
      *AI actions left* up by exactly 5, not 10.
- [ ] Export the **same** CV again: no paywall. Export a **different** CV:
      the paywall again (the unlock is for one CV only).

## 3. Restore

- [ ] Delete the app, install it again from TestFlight, sign in with the
      account from section 1.
- [ ] Profile already shows **Pro** (the plan is on the server). Then
      Profile > Restore purchases > **Restore purchases**: done within a few
      seconds, still Pro, no error.
- [ ] Sign in to a **different** new account on the same iPhone and Restore:
      no crash, a clear message. The subscription stays with the account that
      bought it.

## 4. Cancel: the plan drops to Free through the webhook

- [ ] On the iPhone: Settings > App Store > Sandbox Account > Manage >
      **CvMate Pro** > Cancel Subscription. (Or, from the app: Settings >
      Delete account > *Manage subscriptions*, without deleting.)
- [ ] Still **Pro** right after cancelling: Pro lasts to the end of the
      period.
- [ ] When the period ends (about 3 minutes into the trial, or the next
      sandbox "hour"), RevenueCat sends `EXPIRATION`. Within a few minutes of
      that, pull Profile down or reopen the app: **Free**, and *AI actions left*
      back to the free allowance.
- [ ] Server log: `revenuecat_event` with `type: EXPIRATION`, `outcome:
      pro_ended`.

If the plan does not drop within 15 minutes, check RevenueCat > Customer
history for the EXPIRATION event and the webhook delivery status.

## 5. App Check (App Attest, server in monitor mode)

The server stays in **monitor** mode: a missing or bad App Check token is
logged as `app_check_failed` but the request still goes through.

- [ ] Use the app normally for a few minutes: one AI action, a purchase or
      Restore, Report a problem.
- [ ] Server log: `docker compose logs api --since 30m | grep
      app_check_failed` shows **no** lines for this iPhone. (Lines from the
      simulator without a debug token are expected; check the time.)
- [ ] Firebase console > App Check > APIs: the share of verified requests
      goes up after the TestFlight session.
- [ ] Only switch the server to `enforce` after several days with no
      failures from real devices (see `docs/APP_CHECK.md`).

## 6. Crash reports and analytics

**Forced crash, symbolicated.** Release builds have no crash button. Use a
Release-configuration run of the same commit from Xcode on the iPhone
(Product > Scheme > Edit Scheme > Run > Build Configuration: **Release**),
with a temporary uncommitted `throw StateError('test')` behind a button,
then take it out again.

- [ ] Launch, trigger the crash, launch again (Crashlytics sends on the next
      launch).
- [ ] Within about 5 minutes, Firebase > Crashlytics shows the issue: title
      `StateError`, **no message text**, the user id is a 64-character hash.
- [ ] The **Dart** frames show file and line (`lib/...dart:NN`), not bare
      addresses. If they don't, run `scripts/upload_dart_symbols.sh` for
      that build and wait a few minutes.
- [ ] Native frames are symbolicated too (the "Upload Crashlytics dSYMs"
      build phase ran during Archive).

**Analytics.** DebugView needs debug mode, which a TestFlight build can't
turn on. On TestFlight use **Analytics > Realtime**; for event-by-event
checks use DebugView with an Xcode run as described in
`docs/ANALYTICS_EVENTS.md` ("Checking it").

- [ ] Realtime shows the TestFlight session: `app_open`, `screen_view`,
      `ai_action_start` / `ai_action_result`, `paywall_view` (with `source`),
      `purchase_result`.
- [ ] Settings > Privacy > *Share usage analytics* **off**, then use the app:
      no new events from this device in Realtime.

## 7. Delete each test account

- [ ] Settings > Delete account > Delete. If the sign-in is older than
      5 minutes the app asks for the password.
- [ ] The app goes back to onboarding. Firebase > Authentication no longer
      lists the email.
- [ ] **Every** Delete ends in exactly one of: *"Your account was deleted."*
      and onboarding, the *Confirm your password* prompt, or a red error on
      Settings. Never a silent jump to Home, My CVs or login with the
      account still there. Try it once right after signing in and once with
      a sign-in older than 5 minutes; also double-tap *Delete account*
      (only one dialog opens). The simulator runs the same 10 cases:
      `integration_test/delete_account_test.dart` (see `docs/QA_REPORT.md`
      for the emulator command).
- [ ] Deleting does not cancel a sandbox subscription: cancel it in section 4
      first, or let the sandbox subscription run out.

## Making the build

From the project root on the `main` you want to ship:

1. `.env`: `USE_MOCK_AI=false`, the RevenueCat **iOS public SDK key** filled
   in, and the other keys as for any release. The Archive refuses to build if
   `USE_MOCK_AI=true`.
2. Raise the build number in `pubspec.yaml` (`version: 1.0.0+N`). App Store
   Connect rejects a build number it has seen before for this version.
3. Build the archive and the App Store IPA:
   ```bash
   flutter build ipa --release --split-debug-info=build/debug-info --dart-define=AI_API_BASE_URL=https://api.khokan.me
   ```
   No `--obfuscate`: crash reports send only the exception's type name, and
   obfuscation would make it unreadable (see `scripts/upload_dart_symbols.sh`).
4. Upload the Dart symbols for this exact build:
   ```bash
   scripts/upload_dart_symbols.sh
   ```
5. Upload to App Store Connect (pick one):
   - **Xcode:** open `build/ios/archive/Runner.xcarchive` (it opens the
     Organizer), select it, **Distribute App** > **App Store Connect** >
     **Upload**, keep automatic signing, then **Upload**.
   - **Transporter app:** sign in with the Apple ID of the team, drag
     `build/ios/ipa/*.ipa` in, then **Deliver**.
6. App Store Connect > the app > TestFlight: the build shows as *Processing*
   for 5–30 minutes. Export compliance is answered by
   `ITSAppUsesNonExemptEncryption = NO` in `Info.plist` (only standard
   HTTPS), so no questions should appear. Then add it to an internal testing
   group.
