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
    // On short screens (iPhone SE) the header and cards tighten up so the
    // prices are visible without scrolling; only the button stays pinned.
    final compact = MediaQuery.sizeOf(context).height < _compactHeight;
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
                  AppSpacing.s4,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(compact: compact),
                    _Benefits(compact: compact),
                    _Plans(compact: compact),
                    const _Notes(),
                  ],
                ),
              ),
            ),
            const _CtaBar(),
          ],
        ),
      ),
    );
  }

  /// Screens shorter than this (logical px) get the compact layout.
  static const double _compactHeight = 700;
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
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.body.copyWith(
      color: AppColors.muted,
      fontSize: compact ? 13.5 : 15,
      height: compact ? 1.35 : 1.45,
    );
    final iconSize = compact ? 44.0 : 60.0;
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(
              compact ? AppRadii.button : AppRadii.card,
            ),
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.onPrimary,
            size: compact ? 22 : 28,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.s10 : AppSpacing.s20),
        Text(
          AppStrings.paywallTitle,
          textAlign: TextAlign.center,
          style: compact ? AppTextStyles.h2 : AppTextStyles.h1,
        ),
        SizedBox(height: compact ? AppSpacing.s8 : AppSpacing.s12),
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
        SizedBox(height: compact ? AppSpacing.s12 : AppSpacing.s22),
      ],
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.compact});

  final bool compact;

  static const List<String> _items = [
    AppStrings.paywallBenefitTailoring,
    AppStrings.paywallBenefitTemplates,
    AppStrings.paywallBenefitCloud,
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: compact ? AppSpacing.s12 : AppSpacing.s16,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              SizedBox(height: compact ? AppSpacing.s8 : AppSpacing.s14),
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
  const _Plans({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? AppSpacing.s18 : AppSpacing.s20),
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
                  compact: compact,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: PaywallPlanCard(
                  name: AppStrings.paywallYearly,
                  price: PricingConstants.format(PricingConstants.yearlyPrice),
                  unit: AppStrings.paywallPerYear,
                  highlighted: true,
                  compact: compact,
                  badge: AppStrings.paywallSave(
                    PricingConstants.yearlySavingsPercent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.s10 : AppSpacing.s14),
          _OneTimeCard(compact: compact),
        ],
      ),
    );
  }
}

class _OneTimeCard extends StatelessWidget {
  const _OneTimeCard({required this.compact});

  final bool compact;

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
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: compact ? AppSpacing.s10 : AppSpacing.s14,
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

/// What the screen is honest about, directly under the prices: nothing can be
/// bought yet, and the footer line. Scrolls with the content.
class _Notes extends StatelessWidget {
  const _Notes();

  @override
  Widget build(BuildContext context) {
    final small = AppTextStyles.bodySm.copyWith(color: AppColors.muted);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s14),
      child: Column(
        children: [
          Text(
            AppStrings.paywallNotAvailable,
            textAlign: TextAlign.center,
            style: small.copyWith(color: AppColors.accentInk),
          ),
          const SizedBox(height: AppSpacing.s10),
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

/// The only pinned element: the call to action.
class _CtaBar extends StatelessWidget {
  const _CtaBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s12,
      ),
      // Deliberately disabled: no purchase is possible yet, and we will not
      // pretend otherwise.
      child: PrimaryButton(label: AppStrings.paywallCta, onPressed: null),
    );
  }
}
