# Firebase App Check

The app proves to our server (api.khokan.me) that a request comes from a
genuine CvMate build on a real device. The server checks it per app, in
`off`, `monitor` or `enforce` mode (cvmate-api, README > App Check).

| Build | Provider |
|---|---|
| Release / Profile (TestFlight, App Store) | App Attest, with DeviceCheck as the fallback |
| Debug, simulator | Debug provider |
| Android release / debug | Play Integrity / debug provider |

- **Code:** `lib/shared/services/app_check/app_check_service.dart`.
- **Activation:** `activateAppCheck()` runs in `main.dart`.
- **The header:** `AppCheckInterceptor` adds `X-Firebase-AppCheck` to every
  request the app makes to our server. The SDK caches the token and refreshes
  it before it expires.
- **No token:** if the app cannot get one (offline on the first
  attestation, or a failure), the request still goes out without the header,
  and the server's mode decides what happens.
- **Entitlement:** `ios/Runner/Runner.entitlements` sets
  `com.apple.developer.devicecheck.appattest-environment` to
  `$(APP_ATTEST_ENVIRONMENT)`. That is `development` in the Debug
  configuration and `production` in Release and Profile.

## What you click (once)

### 1. Apple Developer: App Attest capability

1. Open Xcode > Runner target > Signing & Capabilities. **App Attest** should
   now be listed, because the entitlement file is in place.
2. With automatic signing, Xcode adds the capability to the App ID
   `com.khokan.careermatebd` itself.
3. If signing complains, open developer.apple.com > Certificates, IDs &
   Profiles > Identifiers > `com.khokan.careermatebd`. Tick **App Attest** and
   save. Then let Xcode refresh the profiles.

### 2. Firebase console: register the iOS app with App Attest

1. Open console.firebase.google.com and the project **careermatebd**.
2. Go to **Build > App Check** (or **Security > App Check**) and open the
   **Apps** tab.
3. Click the iOS app **com.khokan.careermatebd** and choose **App Attest**.
4. Enter your **Team ID**. It is on developer.apple.com > Membership details.
5. Leave the token time-to-live at 1 hour and click **Save**.
6. Optional, for the DeviceCheck fallback: on the same app, choose
   **DeviceCheck**.
   1. Upload a DeviceCheck private key (`.p8`). Create it at
      developer.apple.com > Keys > **+** > tick *DeviceCheck*.
   2. Enter its **Key ID** and click **Save**.

   The `.p8` file is a secret. Keep it out of the repo, and do not paste it
   anywhere but the Firebase console.

### 3. Firebase console: add the simulator debug token

Run a **debug** build on the simulator, from Xcode or with `flutter run`.

1. The iOS App Check SDK prints a line like this once per install:
   `[AppCheckCore][I-GAC004001] App Check debug token: '…'`
   - In **Xcode**, search the console (bottom pane) for
     `App Check debug token`.
   - With **`flutter run`**, the same line appears in the terminal output.
     You can also find it in Console.app: select the simulator, search
     `App Check debug token`.
2. Copy only the token between the quotes.
3. In the Firebase console, open App Check > Apps.
4. On **com.khokan.careermatebd**, click **⋮ > Manage debug tokens > Add
   debug token**.
5. Give it a name (for example "MacBook iPhone 17e simulator"), paste the
   token and click **Save**.
6. The token is new for every fresh install on a simulator. To keep one fixed
   token, register it once and run the app with
   `--dart-define=APP_CHECK_DEBUG_TOKEN=<that token>`.

Treat the debug token like a password. Anyone who has it can pass App Check.
Delete it in *Manage debug tokens* when you no longer need it.

### 4. Leave Firebase's own App Check enforcement off (for now)

The **APIs** tab (Cloud Firestore, Authentication, …) has its own
**Enforce** buttons. Leave them **Unenforced**, because this change does not
cover Firestore or Auth. Our server's mode is separate. It is set with the
admin CLI, not in the console.

## Rollout

1. Deploy cvmate-api with migration 6. Every app starts in **monitor** mode:
   failures are logged and nothing is rejected.
2. Ship a TestFlight build and use it. Then check the server log:

   ```sh
   docker compose logs api --since 24h | grep app_check_failed
   ```

   Each line has a reason: `missing` (no header) or `invalid`. Debug builds
   without a registered debug token show up here too.
3. When TestFlight shows no failures for a few days, switch to enforce:

   ```sh
   docker compose exec api npm run admin -- app:app-check --app cvmate --mode enforce
   ```

   Going back is the same command with `--mode monitor`.

Android: Play Integrity needs the app's SHA-256 signing certificate
registered in Firebase (Project settings > Your apps) and App Check > Apps >
Android > Play Integrity. Do this when Android ships.
