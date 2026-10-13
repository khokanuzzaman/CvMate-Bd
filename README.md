# careermatebd

A new Flutter project.

## Setup

1. Install Flutter 3.38.8 (Dart 3.10.7) — the version CI uses.
2. Create your local env file (it is gitignored; never commit real keys):

   ```sh
   cp .env.example .env
   ```

   `.env` is bundled as an app asset, so Flutter will not build or test
   without it. The defaults keep AI in mock mode (`USE_MOCK_AI=true`). The
   compile-time options (`OPENAI_PROXY_URL`, `USE_FIREBASE_AI`,
   `FIREBASE_FUNCTIONS_REGION`) are passed with `--dart-define`, not set in
   `.env` — see the comments in `.env.example`.
3. Install dependencies and check everything works:

   ```sh
   flutter pub get
   flutter analyze
   flutter test
   ```

CI runs the same steps on every pull request and on pushes to `main`
(`.github/workflows/flutter.yml`).

## Release builds

A release build **refuses to start** (`StateError` in `main()`) unless AI goes
through the Firebase proxy, so canned mock AI output can never ship:

```sh
flutter build apk --release --dart-define=USE_FIREBASE_AI=true
```

Debug builds and `flutter test` keep using the mock by default. The check lives
in `EnvConfig.aiConfigurationProblem` (`lib/core/config/env_config.dart`).

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
