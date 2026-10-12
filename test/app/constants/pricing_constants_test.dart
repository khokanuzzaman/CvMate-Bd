import 'package:careermatebd/app/constants/pricing_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the yearly saving is computed from the prices, not typed in', () {
    // ৳799 a year vs 12 × ৳149 = ৳1788 → 55% cheaper.
    expect(PricingConstants.yearlySavingsPercent, 55);
  });

  test('prices are formatted with the currency symbol', () {
    expect(
      PricingConstants.format(149),
      '${PricingConstants.currencySymbol}149',
    );
    expect(PricingConstants.currencySymbol, '৳');
  });

  test('the yearly plan is actually cheaper than twelve months', () {
    expect(
      PricingConstants.yearlyPrice,
      lessThan(PricingConstants.monthlyPrice * 12),
    );
    expect(
      PricingConstants.singleCvPrice,
      lessThan(PricingConstants.monthlyPrice),
    );
  });
}
