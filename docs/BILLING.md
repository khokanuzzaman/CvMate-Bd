# Billing: RevenueCat

Purchases go through RevenueCat (`purchases_flutter`); the plan they buy is
applied by **our server** (repo `cvmate-api`, RevenueCat webhook
`/v1/webhooks/revenuecat/cvmate`). The app never decides Pro by itself: after
a purchase it refreshes `GET /v1/me/entitlement` until the server reports the
change (`docs/AI_BACKEND.md`).

## Products (prices are set in the stores, never in code)

| Product | Type | RevenueCat package | Gives |
| --- | --- | --- | --- |
| `cvmate_pro_monthly` | auto-renewable, group "CvMate Pro" | `$rc_monthly` | entitlement `pro` |
| `cvmate_pro_yearly` | auto-renewable, same group, 7-day free trial | `$rc_annual` | entitlement `pro` |
| `cvmate_one_cv` | consumable | custom `one_cv` | +1 CV export unlock, +5 AI actions |

Offering `default` (the paywall falls back to the current offering).

## Identity

The RevenueCat app user id is the Firebase uid: `billingIdentitySyncProvider`
(watched by the app root) calls `logIn(uid)` after sign-in and `logOut()` after
sign-out, and every purchase / restore first makes sure the RevenueCat user is
the signed-in uid. Buying needs a Firebase user (guest accounts count).

## Code

| Where | What |
| --- | --- |
| `lib/shared/services/billing/` | `BillingService` seam: RevenueCat, a fake (debug/tests), "unavailable" (no key) |
| `lib/features/subscription/presentation/controllers/paywall_controller.dart` | load offering, buy, restore, wait for the server |
| `lib/features/subscription/presentation/screens/paywall_screen.dart` | store prices, trial, Restore, Terms / Privacy, auto-renew terms |
| `lib/shared/services/entitlement/entitlement_service.dart` | the single export gate |
| `lib/app/constants/app_links.dart` | Terms and Privacy Policy URLs (default https://api.khokan.me/cvmate/terms and /privacy, served by cvmate-api) |

## Export gate

`runGatedExport(cvId: …)` → `EntitlementService.checkExport`, in this order:
server Pro → this CV already unlocked → the one free export (device counter)
→ a purchased unlock is claimed for this CV (`POST /v1/me/cv-export-unlocks`)
→ else the paywall. When the paywall reports a purchase, the export continues
without another tap. A tailored copy is its own CV (its own unlock).

## Keys and builds

The RevenueCat **public** SDK key (`appl_…`) is not a secret, but it is never
hard-coded: `--dart-define=REVENUECAT_IOS_API_KEY=…`, else `.env`.
A release iOS build refuses to start without it, or with
`USE_FAKE_BILLING=true`. `REVENUECAT_ANDROID_API_KEY` may stay empty: Android
then shows "Purchases aren't available on this device". Debug builds use the
fake purchase service unless `.env` says `USE_FAKE_BILLING=false`; the fake
never reaches the server, so it never makes anyone Pro (make a tester Pro by
hand, see `cvmate-api/DEPLOY.md`).

```sh
# sandbox purchases on a device or simulator with a StoreKit sandbox account
flutter run --dart-define=REVENUECAT_IOS_API_KEY=appl_xxx   # USE_FAKE_BILLING=false in .env
# release
flutter build ipa --dart-define=REVENUECAT_IOS_API_KEY=appl_xxx
```

The paywall's Terms and Privacy links default to
https://api.khokan.me/cvmate/terms and https://api.khokan.me/cvmate/privacy
(cvmate-api serves them); `--dart-define=TERMS_URL=…` /
`PRIVACY_POLICY_URL=…` override them. Deploy those pages before release.
