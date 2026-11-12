# careermatebd

A new Flutter project.

## Setup

1. Install Flutter 3.44.0 (Dart 3.12.0) — the version CI uses. The version is pinned
   in `.fvmrc`: with [FVM](https://fvm.app) run `fvm install` once and prefix commands
   with `fvm` (e.g. `fvm flutter test`). When you bump it, change `.fvmrc` and both
   `flutter-version` entries in `.github/workflows/flutter.yml` together.
2. Create your local env file (it is gitignored; never commit real keys):

   ```sh
   cp .env.example .env
   ```

   `.env` is bundled as an app asset, so Flutter will not build or test
   without it. Never put keys in it. The default keeps AI in mock mode
   (`USE_MOCK_AI=true`, canned answers, nothing sent). Set
   `USE_MOCK_AI=false` to use the real AI server in a debug build; its URL is
   a compile-time option (`--dart-define=AI_API_BASE_URL=...`, default
   `https://api.khokan.me`), see the comments in `.env.example`.
3. Install dependencies and check everything works:

   ```sh
   flutter pub get
   flutter analyze
   flutter test
   ```

CI runs the same steps on every pull request and on pushes to `main`
(`.github/workflows/flutter.yml`).

## AI server

All AI goes through our own server, the `cvmate-api` repo (checked out next
to this one as `../cvmate-api`, live at `https://api.khokan.me`): the app sends its Firebase ID token and
`X-App-Id: cvmate`, the server checks the AI quota and calls Claude. The app
never holds a model API key. Details: [`docs/AI_BACKEND.md`](docs/AI_BACKEND.md).

Run a debug build against it (with `USE_MOCK_AI=false` in `.env`):

```sh
flutter run --dart-define=AI_API_BASE_URL=https://api.khokan.me
```

## Release builds

A release build always uses the AI server and **refuses to start**
(`StateError` in `main()`) if `.env` asks for the mock or the AI server URL is
not HTTPS, so canned mock AI output can never ship:

```sh
flutter build ipa --release --dart-define=AI_API_BASE_URL=https://api.khokan.me
```

The check lives in `EnvConfig.aiConfigurationProblem`
(`lib/core/config/env_config.dart`).

## QA on the iOS Simulator

`integration_test/` taps through the real app on a simulator against the
**Firebase Auth emulator** (never the production project) and saves a
screenshot of every step to `build/qa/<flow>/<step>.png`. It is test-only: it
lives outside `lib/`, so it cannot be part of a release build. See
[`docs/QA_REPORT.md`](docs/QA_REPORT.md) for the findings and the commands.

`integration_test/qa_app_main.dart` is a test-only entrypoint that runs the real
app wired to the same emulator (no cloud sync, no analytics) so you can explore
by hand: `flutter run -t integration_test/qa_app_main.dart --dart-define=QA_AUTH_EMULATOR_HOST=127.0.0.1`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
