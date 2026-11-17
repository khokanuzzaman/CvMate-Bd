/// Public legal links shown on the paywall (App Store guideline 3.1.2),
/// served by our server (repo cvmate-api, `src/apps/cvmate/legal/`).
abstract final class AppLinks {
  /// Terms of Use. Override with `--dart-define=TERMS_URL=https://…`.
  static const String termsOfUse = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://api.khokan.me/cvmate/terms',
  );

  /// Privacy Policy. Override with `--dart-define=PRIVACY_POLICY_URL=https://…`.
  /// When set to an empty value, the in-app privacy text is shown instead.
  static const String privacyPolicy = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://api.khokan.me/cvmate/privacy',
  );
}
