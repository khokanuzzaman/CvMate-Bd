# Next session: iOS launch, week 2 (billing)

Done: the app talks to our own AI server (`cvmate-api`, https://api.khokan.me),
see `docs/AI_BACKEND.md`. AI consent, "AI actions left", the `ai_quota`
paywall and the release guard are in. The Cloud Function, `cloud_functions`
and the direct OpenAI client are removed.

Still open before the App Store submission:

- **Billing.** RevenueCat in the app (Pro monthly + a credit pack), Restore
  purchases on Profile and the paywall. The server already has the webhook
  stub `POST /v1/webhooks/revenuecat/cvmate`; the billing PR on the server
  sets `plan` / `proExpiresAt` / `bonusCredits`. The app then only refreshes
  `aiEntitlementProvider` after a purchase. Keep the export gate local until
  the server owns it too.
- **Privacy policy.** Publish it (mention the AI server and Anthropic, what is
  never sent) and point the consent sheet link and Settings → Privacy Policy
  at the URL (needs `url_launcher`); fill in the App Store privacy labels.
- **Account deletion** (App Store 5.1.1(v)): delete Firestore `users/{uid}`,
  the Auth user, and ask the server to drop the entitlement row.

```
iOS launch, week 2: RevenueCat billing in the app. ONE PR off main. Follow
the lean testing rules in CLAUDE.md. Read docs/AI_BACKEND.md and
../cvmate-api/README.md first.

1. purchases_flutter, configured with the Firebase uid as app user id.
2. Paywall: real products (Pro monthly, a credit pack), purchase + restore,
   loading/error states. After a purchase refresh aiEntitlementProvider.
3. Profile: Restore purchases (replaces "Coming soon").
4. EntitlementService.isPro reads the server plan (aiEntitlementProvider)
   instead of the local flag; the export gate keeps its rule.

TESTS (lean)
- Paywall purchase success refreshes the entitlement; a cancelled purchase
  changes nothing.
- Integration: paywall from ai_quota → purchase (sandbox mock) → AI works.
```
