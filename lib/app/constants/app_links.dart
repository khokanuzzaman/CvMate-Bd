/// Public legal links shown on the paywall (App Store guideline 3.1.2).
abstract final class AppLinks {
  /// Terms of Use: Apple's standard EULA unless a custom one is passed with
  /// `--dart-define=TERMS_OF_USE_URL=https://…`.
  static const String termsOfUse = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue:
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  /// The published privacy policy, `--dart-define=PRIVACY_POLICY_URL=https://…`.
  /// TODO(launch): no policy is published yet; while this is empty the
  /// in-app privacy text is shown instead.
  static const String privacyPolicy = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
}
