import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/brand_logo_tile.dart';
import 'package:careermatebd/core/widgets/pager_dots.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:careermatebd/features/onboarding/presentation/controllers/onboarding_seen_controller.dart';
import 'package:careermatebd/features/onboarding/presentation/widgets/onboarding_cv_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-run value prop: tailored-CV illustration, headline, and entry points.
/// Leaving it (Get started / Skip / Log in) records that onboarding was seen so
/// the router skips it on later launches.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  // Only the first page is designed; the dots are ready for a future PageView.
  static const int _pageCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final illustrationHeight = (screenHeight * 0.42).clamp(240.0, 380.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s22,
                  AppSpacing.s12,
                  AppSpacing.s22,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const BrandLogoTile(size: 36),
                        const SizedBox(width: AppSpacing.s12),
                        Text(AppStrings.brandName, style: AppTextStyles.title),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _enterApp(context, ref),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              AppSpacing.minTouchTarget,
                              AppSpacing.minTouchTarget,
                            ),
                            foregroundColor: AppColors.muted2,
                          ),
                          child: Text(
                            AppStrings.onboardingSkip,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.muted2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    OnboardingCvIllustration(height: illustrationHeight),
                    const SizedBox(height: AppSpacing.s22),
                    Text(AppStrings.onboardingHeadline, style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.s14),
                    Text(
                      AppStrings.onboardingBody,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s22),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: PagerDots(
                        count: _pageCount,
                        index: 0,
                        dotSize: 6,
                        activeWidth: 22,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.lineStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    PrimaryButton(
                      label: AppStrings.onboardingGetStarted,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => _enterApp(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    AuthSwitchLink(
                      prompt: AppStrings.authHaveAccount,
                      actionLabel: AppStrings.authLogIn,
                      onTap: () => _logIn(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get started / Skip: explore the app as a guest, like the previous
  /// "Explore first" entry point.
  Future<void> _enterApp(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingSeenControllerProvider.notifier).markSeen();
    if (!context.mounted) {
      return;
    }
    context.go(RouteNames.homePath);
  }

  Future<void> _logIn(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingSeenControllerProvider.notifier).markSeen();
    if (!context.mounted) {
      return;
    }
    context.push(RouteNames.loginPath);
  }
}
