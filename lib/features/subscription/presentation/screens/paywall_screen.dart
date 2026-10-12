import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/constants/pricing_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plan_card.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The fair export gate, shown after a user's free export is used.
///
/// Billing is not wired yet, so the plans are display-only and the call to
/// action stays disabled: no purchase is possible and the screen says so. No
/// countdowns, no fake urgency, no pre-selected auto-renew. Prices come from
/// [PricingConstants].
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source});

  /// Where the user hit the paywall from (for analytics only).
  final String? source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logEvent(
            AnalyticsEvents.paywallViewed,
            params: {AnalyticsEvents.paramSource: widget.source ?? 'unknown'},
          );
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s12,
                  AppSpacing.screen,
                  0,
                ),
                child: _CloseButton(onTap: _close),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s4,
                  AppSpacing.screen,
                  AppSpacing.s16,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_Header(), _Benefits(), _Plans()],
                ),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.paywallClose,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const ExcludeSemantics(
                child: Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.body.copyWith(
      color: AppColors.muted,
      fontSize: 15,
      height: 1.45,
    );
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.onPrimary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Text(
          AppStrings.paywallTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: AppSpacing.s12),
        Text.rich(
          TextSpan(
            style: body,
            children: [
              const TextSpan(text: AppStrings.paywallBodyPrefix),
              TextSpan(
                text: AppStrings.paywallBodyEmphasis,
                style: body.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: AppStrings.paywallBodySuffix),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s22),
      ],
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  static const List<String> _items = [
    AppStrings.paywallBenefitTailoring,
    AppStrings.paywallBenefitTemplates,
    AppStrings.paywallBenefitCloud,
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.successText,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    _items[i],
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: PaywallPlanCard(
                  name: AppStrings.paywallMonthly,
                  price: PricingConstants.format(PricingConstants.monthlyPrice),
                  unit: AppStrings.paywallPerMonth,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: PaywallPlanCard(
                  name: AppStrings.paywallYearly,
                  price: PricingConstants.format(PricingConstants.yearlyPrice),
                  unit: AppStrings.paywallPerYear,
                  highlighted: true,
                  badge: AppStrings.paywallSave(
                    PricingConstants.yearlySavingsPercent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          const _OneTimeCard(),
        ],
      ),
    );
  }
}

class _OneTimeCard extends StatelessWidget {
  const _OneTimeCard();

  @override
  Widget build(BuildContext context) {
    final ink = AppTextStyles.body.copyWith(
      color: AppColors.accentInk,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      container: true,
      label:
          '${AppStrings.paywallOneTimeTitle}, '
          '${AppStrings.paywallOneTimeSubtitle}, '
          '${PricingConstants.format(PricingConstants.singleCvPrice)}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.35),
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.accentSoft),
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
                PricingConstants.format(PricingConstants.singleCvPrice),
                style: AppTextStyles.title.copyWith(color: AppColors.accentInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final small = AppTextStyles.bodySm.copyWith(color: AppColors.muted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.paywallNotAvailable,
            textAlign: TextAlign.center,
            style: small.copyWith(color: AppColors.accentInk),
          ),
          const SizedBox(height: AppSpacing.s10),
          // Deliberately disabled: no purchase is possible yet, and we will not
          // pretend otherwise.
          const PrimaryButton(label: AppStrings.paywallCta, onPressed: null),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${AppStrings.paywallFooter} · ', style: small),
              Semantics(
                button: true,
                enabled: false,
                label: AppStrings.paywallRestore,
                child: ExcludeSemantics(
                  child: Text(
                    AppStrings.paywallRestore,
                    style: small.copyWith(
                      color: AppColors.muted2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
