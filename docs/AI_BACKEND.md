# AI backend: the cvmate-api server

All AI goes through our own server, repo **`cvmate-api`** (checked out next to
this repo as `../cvmate-api`), live at **https://api.khokan.me**. Its
`README.md` documents the API and `DEPLOY.md` the server (Contabo VPS behind
CloudPanel, Docker, SQLite, daily backups). The app never holds a model API
key; the Firebase Cloud Function and the direct OpenAI client are gone.

Firebase is still used for **Auth** (the server verifies the Firebase ID
token) and **Firestore CV sync** (`users/{uid}/**`). Plan and AI quota live on
the server, not in Firestore.

## Flow

1. A feature calls `aiCareerServiceProvider` (`lib/shared/services/ai/`).
2. `GuardedAiCareerService` asks `AiConsentGuard`: without consent the AI
   consent sheet is shown, and on "Not now" **no request is sent**.
3. `ServerAiCareerService` builds the body with `AiRequestPayload`
   (`{action, language, tone, cvData, inputText, jobPost, metadata}`; only
   whitelisted CV fields, incl. `experiences[].id`; never passport, date of
   birth, religion, marital status, gender or photo).
4. `AiServerClient` (Dio) sends `POST /v1/ai/generate` with
   `X-App-Id: cvmate` and `Authorization: Bearer <Firebase ID token>`. On 401
   it refreshes the token (`getIdToken(true)`) and retries once. Timeouts:
   connect 10 s, receive 120 s. It never logs the token or CV text.
5. The answer `{success, action, content, message, usage, remainingActions}`
   is parsed by `AiResponseParser`; `remainingActions` updates the
   "AI actions left" counter.

## Errors

| Server | App `Failure.code` | What the user sees |
| --- | --- | --- |
| 402 `ai_quota` | `ai_quota_exceeded` | Paywall opens (source `ai_quota`) |
| 429 `rate_limit` | `ai_rate_limited` | Snackbar: wait a minute |
| 503 `ai_unavailable` / `budget_exceeded`, offline, timeout | `ai_unavailable` | "AI is busy, please try again." |
| 413 `payload_too_large` | `ai_payload_too_large` | "This text is too long." |
| 400 `invalid_input` | `ai_invalid_input` | "Please check your input and try again." |
| 401 after the retry | `ai_auth_required` | Sign in again |
| 404 `app_not_found`, 500 | `ai_failed` (404 is logged) | Generic error |

## Quota and plan

`GET /v1/me/entitlement` →
`{plan, proExpiresAt, actionsLeft, resetsAt, cvExportUnlocks, unlockedCvIds}`
(epoch ms; `resetsAt` is null on the free plan). The server is the **only**
source of truth for Pro: the app has no local Pro flag. Free: 3 AI actions in
total. Pro: 100 per calendar month (UTC). Bonus credits (5 per one-CV
purchase) are used last. `aiEntitlementProvider` shows the cached value
(Hive, per uid) first, then refreshes on start, on app resume, after every
AI call and after a purchase. Profile and the Tailor button show "AI actions
left: N". Billing (RevenueCat) and the export gate: see `docs/BILLING.md`.

To make a user Pro or change the budget, see `cvmate-api/DEPLOY.md`.

## Consent (App Store guideline 5.1.2)

The first AI action shows the consent sheet once. The choice is stored
locally (`AppPreferences.aiConsent`, Hive) and can be changed in Settings →
"AI features". Its "Privacy policy" link opens the in-app privacy text; point
it at the published privacy policy before launch.

## Running

- Debug, mock AI (default `.env`): `flutter run`
- Debug, real server: `USE_MOCK_AI=false` in `.env`, then
  `flutter run --dart-define=AI_API_BASE_URL=https://api.khokan.me`
- Release: always the server; `main()` refuses to start if `.env` asks for the
  mock or the URL is not HTTPS (`EnvConfig.aiConfigurationProblem`).
- Tests: `test/helpers/fake_ai_server.dart` is a Dio adapter that stands in
  for the server; `integration_test/flows/ai_server_flow.dart` runs the
  tailoring flow against it.
