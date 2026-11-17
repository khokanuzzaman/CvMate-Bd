import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/theme/cv_mate_theme.dart';
import 'package:careermatebd/core/widgets/text_scale_clamp.dart';
import 'package:careermatebd/features/cv_builder/data/cv_cloud_sync.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/billing/billing_identity_sync.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CareerMateApp extends ConsumerWidget {
  const CareerMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate CV cloud backup/restore (guest session + Firestore reconcile).
    ref.watch(cvCloudSyncProvider);
    // Log app_open once for the analytics funnel.
    ref.watch(analyticsBootstrapProvider);
    // Keep "AI actions left" current when the app returns to the foreground.
    ref.watch(aiEntitlementResumeRefreshProvider);
    // RevenueCat's app user id follows the Firebase uid.
    ref.watch(billingIdentitySyncProvider);

    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(appPreferencesControllerProvider);
    final themeMode = preferences.asData?.value.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      // Design is light-only for now; both slots use the light theme so system
      // dark still renders the approved design (see CvMateTheme.dark TODO).
      theme: CvMateTheme.light,
      darkTheme: CvMateTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final appChild = TextScaleClamp(
          child: child ?? const SizedBox.shrink(),
        );
        if (!EnvConfig.isMockAiActive) {
          return appChild;
        }

        return Banner(
          message: 'MOCK AI',
          location: BannerLocation.topEnd,
          color: Theme.of(context).colorScheme.error,
          textStyle:
              Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white) ??
              const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
          child: appChild,
        );
      },
    );
  }
}
