import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/subscription/presentation/controllers/paywall_controller.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_legal.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plans.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The paywall: Pro monthly / yearly and the one-CV unlock, with prices from
/// the store (RevenueCat offering), the free trial when this user is
/// eligible, Restore, Terms / Privacy links and the auto-renew terms of the
/// selected plan. Nothing is pre-selected; no countdowns or fake urgency.
///
/// After a purchase it waits for the AI server to report the new plan (the
/// only source of truth for Pro) and then closes with `true`, so an export
/// that opened it can continue.
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

  void _close({bool purchased = false}) {
    if (context.canPop()) {
      context.pop(purchased);
    } else {
      context.go(RouteNames.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(paywallControllerProvider, (previous, next) {
      if (next.phase == PaywallPhase.done &&
          previous?.phase != PaywallPhase.done) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.notice ?? AppStrings.paywallPurchaseDone),
            ),
          );
        _close(purchased: true);
      }
    });
    final state = ref.watch(paywallControllerProvider);
    final controller = ref.read(paywallControllerProvider.notifier);
    final canSell = state.offering.hasValue && !state.isBusy;
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
                child: _CloseButton(onTap: state.isBusy ? null : _close),
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
                    PaywallPlans(
                      offering: state.offering,
                      selected: state.selected,
                      onSelect: canSell ? controller.select : null,
                      onRetry: controller.load,
                      compact: compact,
                    ),
                    PaywallLegal(
                      selected: state.selectedPackage,
                      notice: state.notice,
                      noticeIsError: state.noticeIsError,
                      onRestore: canSell ? controller.restore : null,
                    ),
                  ],
                ),
              ),
            ),
            _CtaBar(state: state, onBuy: controller.buy),
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

  final VoidCallback? onTap;

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

/// The only pinned element: the call to action for the selected option.
class _CtaBar extends ConsumerWidget {
  const _CtaBar({required this.state, required this.onBuy});

  final PaywallState state;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(purchaserUidProvider) != null;
    final package = state.selectedPackage;
    final (label, onPressed) = switch (state.phase) {
      PaywallPhase.purchasing ||
      PaywallPhase.restoring => (AppStrings.paywallCtaProcessing, null),
      PaywallPhase.activating => (AppStrings.paywallCtaActivating, null),
      _ when !state.offering.hasValue => (AppStrings.paywallChoosePlan, null),
      _ when !signedIn => (
        AppStrings.paywallCtaSignIn,
        () => context.push(RouteNames.loginPath),
      ),
      _ when package == null => (AppStrings.paywallChoosePlan, null),
      _ => (_buyLabel(package), onBuy),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s12,
      ),
      child: PrimaryButton(label: label, onPressed: onPressed),
    );
  }

  static String _buyLabel(BillingPackage package) {
    if (!package.isSubscription) {
      return AppStrings.paywallCtaBuy(package.priceLabel);
    }
    return package.freeTrial != null
        ? AppStrings.paywallCtaTrial
        : AppStrings.paywallCtaSubscribe;
  }
}
