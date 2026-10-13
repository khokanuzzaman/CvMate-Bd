import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/main_tabs.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/logout_controller.dart';
import 'package:careermatebd/features/cv_builder/data/cv_cloud_sync.dart';
import 'package:careermatebd/features/profile/presentation/controllers/profile_providers.dart';
import 'package:careermatebd/features/profile/presentation/widgets/go_pro_banner.dart';
import 'package:careermatebd/features/profile/presentation/widgets/language_sheet.dart';
import 'package:careermatebd/features/profile/presentation/widgets/profile_account_card.dart';
import 'package:careermatebd/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:careermatebd/features/profile/presentation/widgets/settings_group.dart';
import 'package:careermatebd/features/profile/presentation/widgets/theme_selector.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Profile tab: account and plan, Go Pro, preferences, backup status and
/// log out. Everything else from the old Settings screen stays reachable
/// through "More settings".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current =
        ref.read(appPreferencesControllerProvider).asData?.value ??
        const AppPreferences.defaults();
    final picked = await showLanguageSheet(
      context,
      selected: current.languagePreference,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final message = await ref
        .read(appPreferencesControllerProvider.notifier)
        .updateLanguagePreference(picked);
    if (!context.mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final isPro = ref.watch(profileIsProProvider).asData?.value;
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        const AppPreferences.defaults();
    final backup = ref.watch(cloudBackupStatusProvider);
    final version = ref.watch(appVersionLabelProvider).asData?.value;
    final loggingOut = ref.watch(logoutControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.s16,
            AppSpacing.screen,
            AppSpacing.s22,
          ),
          children: [
            Text(AppStrings.profileTitle, style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.s16),
            ProfileAccountCard(user: user, isPro: isPro),
            if (isPro == false) ...[
              const SizedBox(height: AppSpacing.s14),
              GoProBanner(
                onSeePlans: () =>
                    context.push('${RouteNames.paywallPath}?source=profile'),
              ),
            ],
            const SizedBox(height: AppSpacing.s20),
            const SectionLabel(AppStrings.profilePreferences),
            const SizedBox(height: AppSpacing.s8),
            SettingsGroup(
              children: [
                SettingsRow(
                  label: AppStrings.profileAppLanguage,
                  trailing: SettingsRow.value(
                    preferences.languagePreference.label,
                  ),
                  onTap: () => _pickLanguage(context, ref),
                ),
                SettingsRow(
                  label: AppStrings.profileTheme,
                  trailing: ThemeSelector(
                    onLight: () => ref
                        .read(appPreferencesControllerProvider.notifier)
                        .updateThemeMode(ThemeMode.light),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Text(
                AppStrings.themeComingSoon,
                style: AppTextStyles.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const SectionLabel(AppStrings.profileAccount),
            const SizedBox(height: AppSpacing.s8),
            SettingsGroup(
              children: [
                SettingsRow(
                  label: AppStrings.profileCloudBackup,
                  subtitle: backup == CloudBackupStatus.on
                      ? AppStrings.profileCloudOnNote
                      : AppStrings.profileCloudOffNote,
                  trailing: _BackupPill(on: backup == CloudBackupStatus.on),
                ),
                const SettingsRow(
                  label: AppStrings.paywallRestore,
                  enabled: false,
                  trailing: Text(
                    AppStrings.profileComingSoon,
                    style: TextStyle(color: AppColors.muted2, fontSize: 12.5),
                  ),
                ),
                SettingsRow(
                  label: AppStrings.profilePrivacyTerms,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted2,
                  ),
                  onTap: () => showPrivacyTermsDialog(context),
                ),
                SettingsRow(
                  label: AppStrings.profileMoreSettings,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted2,
                  ),
                  onTap: () => context.push(RouteNames.settingsPath),
                ),
                if (user == null) ...[
                  SettingsRow(
                    label: AppStrings.profileLogIn,
                    onTap: () => context.push(RouteNames.loginPath),
                  ),
                  SettingsRow(
                    label: AppStrings.profileCreateAccount,
                    onTap: () => context.push(RouteNames.registerPath),
                  ),
                ] else
                  SettingsRow(
                    label: AppStrings.profileLogOut,
                    destructive: true,
                    enabled: !loggingOut,
                    onTap: () => confirmAndLogOut(context, ref),
                  ),
              ],
            ),
            if (version != null) ...[
              const SizedBox(height: AppSpacing.s20),
              Center(
                child: Text(
                  AppStrings.profileVersion(version),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted2),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: MainTabs.profile,
        onTap: (index) =>
            MainTabs.open(context, index, current: MainTabs.profile),
      ),
    );
  }
}

class _BackupPill extends StatelessWidget {
  const _BackupPill({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: on ? AppColors.successSoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: on ? null : Border.all(color: AppColors.lineStrong),
      ),
      child: Text(
        on ? AppStrings.profileCloudOn : AppStrings.profileCloudOff,
        style: AppTextStyles.bodySm.copyWith(
          color: on ? AppColors.successText : AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
