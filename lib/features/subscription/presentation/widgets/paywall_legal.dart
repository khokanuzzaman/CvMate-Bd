import 'package:careermatebd/app/constants/app_links.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plans.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Under the plans: the status line, the terms of the selected option (the
/// auto-renew disclosure Apple requires), Terms / Privacy links and Restore.
/// Scrolls with the content.
class PaywallLegal extends StatelessWidget {
  const PaywallLegal({
    super.key,
    required this.selected,
    required this.notice,
    required this.noticeIsError,
    required this.onRestore,
  });

  final BillingPackage? selected;
  final String? notice;
  final bool noticeIsError;

  /// Null while busy or when purchases are unavailable.
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final small = AppTextStyles.bodySm.copyWith(color: AppColors.muted);
    final terms = _termsFor(selected);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                notice!,
                textAlign: TextAlign.center,
                style: small.copyWith(
                  color: noticeIsError ? AppColors.danger : AppColors.accentInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
          ],
          if (terms != null) ...[
            Text(terms, textAlign: TextAlign.center, style: small),
            const SizedBox(height: AppSpacing.s10),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Link(
                label: AppStrings.paywallTerms,
                onTap: () => _open(context, AppLinks.termsOfUse),
              ),
              Text(' · ', style: small),
              _Link(
                label: AppStrings.paywallPrivacy,
                onTap: () => _open(context, AppLinks.privacyPolicy),
              ),
              Text(' · ', style: small),
              _Link(label: AppStrings.paywallRestore, onTap: onRestore),
            ],
          ),
        ],
      ),
    );
  }

  static String? _termsFor(BillingPackage? package) {
    if (package == null) {
      return null;
    }
    final account = AppStrings.paywallStoreAccount(
      apple: defaultTargetPlatform == TargetPlatform.iOS,
    );
    if (!package.isSubscription) {
      return AppStrings.paywallOneTimeTerms(
        price: package.priceLabel,
        account: account,
      );
    }
    final trial = package.freeTrial;
    return AppStrings.paywallSubscriptionTerms(
      price: package.priceLabel,
      yearly: package.plan == BillingPlan.yearly,
      account: account,
      trial: trial == null ? null : trialLabel(trial),
    );
  }

  /// Opens [url] in the browser; with no published URL yet (privacy policy
  /// before launch) the in-app text is shown instead.
  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      await showPrivacyTermsDialog(context);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      await showPrivacyTermsDialog(context);
    }
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTextStyles.bodySm.copyWith(
                  color: enabled ? AppColors.primary : AppColors.muted2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
