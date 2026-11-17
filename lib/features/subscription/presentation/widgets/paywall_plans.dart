import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plan_card.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "7-day free trial" for [trial].
String trialLabel(BillingTrial trial) {
  final unit = switch (trial.unit) {
    BillingPeriodUnit.day => 'day',
    BillingPeriodUnit.week => 'week',
    BillingPeriodUnit.month => 'month',
    BillingPeriodUnit.year => 'year',
  };
  return AppStrings.paywallTrial(trial.count, unit);
}

/// The plans from the store offering, with loading and error states.
class PaywallPlans extends StatelessWidget {
  const PaywallPlans({
    super.key,
    required this.offering,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    required this.compact,
  });

  final AsyncValue<BillingOffering> offering;
  final BillingPlan? selected;
  final ValueChanged<BillingPlan>? onSelect;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? AppSpacing.s18 : AppSpacing.s20),
      child: switch (offering) {
        AsyncData(:final value) => _Options(
          offering: value,
          selected: selected,
          onSelect: onSelect,
          compact: compact,
        ),
        AsyncError(:final error) => CustomErrorView(
          title: AppStrings.paywallLoadFailed,
          message: error is BillingException
              ? error.message
              : AppStrings.paywallUnavailable,
          onRetry: onRetry,
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s20),
          child: CustomLoadingView(message: AppStrings.paywallLoading),
        ),
      },
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.offering,
    required this.selected,
    required this.onSelect,
    required this.compact,
  });

  final BillingOffering offering;
  final BillingPlan? selected;
  final ValueChanged<BillingPlan>? onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final monthly = offering.package(BillingPlan.monthly);
    final yearly = offering.package(BillingPlan.yearly);
    final oneCv = offering.package(BillingPlan.oneCv);
    final savings = offering.yearlySavingsPercent;
    final yearlyTrial = yearly?.freeTrial;
    VoidCallback? pick(BillingPlan plan) =>
        onSelect == null ? null : () => onSelect!(plan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (monthly != null || yearly != null)
          Row(
            children: [
              if (monthly != null)
                Expanded(
                  child: PaywallPlanCard(
                    name: AppStrings.paywallMonthly,
                    price: monthly.priceLabel,
                    unit: AppStrings.paywallPerMonth,
                    selected: selected == BillingPlan.monthly,
                    onTap: pick(BillingPlan.monthly),
                    compact: compact,
                  ),
                ),
              if (monthly != null && yearly != null)
                const SizedBox(width: AppSpacing.s12),
              if (yearly != null)
                Expanded(
                  child: PaywallPlanCard(
                    name: AppStrings.paywallYearly,
                    price: yearly.priceLabel,
                    unit: AppStrings.paywallPerYear,
                    selected: selected == BillingPlan.yearly,
                    onTap: pick(BillingPlan.yearly),
                    compact: compact,
                    badge: yearlyTrial != null
                        ? trialLabel(yearlyTrial).toUpperCase()
                        : savings == null
                        ? null
                        : AppStrings.paywallSave(savings),
                  ),
                ),
            ],
          ),
        if (oneCv != null) ...[
          SizedBox(height: compact ? AppSpacing.s10 : AppSpacing.s14),
          _OneTimeCard(
            price: oneCv.priceLabel,
            selected: selected == BillingPlan.oneCv,
            onTap: pick(BillingPlan.oneCv),
            compact: compact,
          ),
        ],
      ],
    );
  }
}

class _OneTimeCard extends StatelessWidget {
  const _OneTimeCard({
    required this.price,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String price;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = AppTextStyles.body.copyWith(
      color: AppColors.accentInk,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label:
          '${AppStrings.paywallOneTimeTitle}, '
          '${AppStrings.paywallOneTimeSubtitle}, $price',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: compact ? AppSpacing.s10 : AppSpacing.s14,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.35),
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: selected ? AppColors.accentInk : AppColors.accentSoft,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.paywallOneTimeTitle, style: ink),
                      Text(
                        AppStrings.paywallOneTimeSubtitle,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.accentInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  price,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.accentInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
