/// Display prices for the paywall — the single place to change them.
///
/// Billing is not wired yet, so these are shown, never charged. Prices are
/// shown in the local currency (BDT) — "PPP pricing" in DESIGN_TOKENS.md.
abstract final class PricingConstants {
  /// Taka sign.
  static const String currencySymbol = '৳';

  static const int monthlyPrice = 149;
  static const int yearlyPrice = 799;

  /// One-time price to unlock just the CV being exported.
  static const int singleCvPrice = 99;

  /// How much cheaper the yearly plan is than twelve monthly payments, in
  /// whole percent (computed, so it cannot drift from the prices above).
  static int get yearlySavingsPercent =>
      ((1 - yearlyPrice / (monthlyPrice * 12)) * 100).round();

  static String format(int amount) => '$currencySymbol$amount';
}
