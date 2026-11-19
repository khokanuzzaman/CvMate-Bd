import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/config/dev_labels.dart';
import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/features/account_deletion/presentation/controllers/account_deletion_controller.dart';
import 'package:careermatebd/features/account_deletion/presentation/widgets/delete_account_dialogs.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/logout_controller.dart';
import 'package:careermatebd/features/cv_builder/data/cv_cloud_sync.dart';
import 'package:careermatebd/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/features/settings/presentation/widgets/clear_data_dialog.dart';
import 'package:careermatebd/shared/services/review/review_prompter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final overview = ref.watch(settingsOverviewControllerProvider);
    final logoutState = ref.watch(logoutControllerProvider);
    final forgotPasswordState = ref.watch(forgotPasswordControllerProvider);
    final deletionState = ref.watch(accountDeletionControllerProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.settings),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Account'),
                  _AccountSection(
                    userEmail: user?.email,
                    isLoggedOut: user == null,
                    isResettingPassword: forgotPasswordState.isLoading,
                    isLoggingOut: logoutState.isLoading,
                    onLogin: () => context.push(RouteNames.loginPath),
                    onRegister: () => context.push(RouteNames.registerPath),
                    onResetPassword: user == null
                        ? null
                        : () => _handleResetPassword(context, ref, user.email),
                    onLogout: user == null
                        ? null
                        : () => _confirmLogout(context, ref),
                  ),
                  if (logoutState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _InlineMessage(
                      message: logoutState.errorMessage!,
                      isError: true,
                    ),
                  ],
                  if (forgotPasswordState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _InlineMessage(
                      message: forgotPasswordState.errorMessage!,
                      isError: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: deletionState.isDeleting
                          ? null
                          : () => _deleteAccount(context, ref),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text(
                        deletionState.isDeleting
                            ? AppStrings.deleteAccountDeleting
                            : AppStrings.deleteAccount,
                      ),
                    ),
                  ),
                  if (deletionState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _InlineMessage(
                      message: deletionState.errorMessage!,
                      isError: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'AI Settings'),
                  _AiSettingsSection(),
                  const SizedBox(height: 24),
                  _SectionTitle(title: AppStrings.privacySection),
                  _PrivacySection(),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Data Management'),
                  overview.when(
                    loading: () => const CustomCard(
                      child: LinearProgressIndicator(minHeight: 8),
                    ),
                    error: (error, stackTrace) => CustomErrorView(
                      title: 'Could not load local data summary',
                      message: 'Something went wrong. Please try again.',
                      onRetry: () => ref
                          .read(settingsOverviewControllerProvider.notifier)
                          .reload(),
                    ),
                    data: (data) => _DataManagementSection(
                      overview: data,
                      onClearData: data.isClearingLocalData
                          ? null
                          : () => _confirmClearData(context, ref),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'About App'),
                  _AboutSection(
                    versionLabel:
                        overview.asData?.value.versionLabel ??
                        'Unknown version',
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Legal / Safety'),
                  _LegalSection(
                    onOpenPrivacy: () => openPrivacyPolicy(context, ref),
                    onOpenTerms: () => openTermsOfUse(context, ref),
                    onOpenAiDisclaimer: () => _showInfoDialog(
                      context,
                      title: 'AI Disclaimer',
                      body:
                          'AI suggestions may contain mistakes.\n\nReview everything before sending.\n\nDo not add false skills, false experience, or fake achievements.',
                    ),
                    onOpenAtsDisclaimer: () => _showInfoDialog(
                      context,
                      title: 'ATS Disclaimer',
                      body:
                          'ATS-friendly suggestions may improve readability and keyword coverage, but they do not guarantee job selection, shortlist, or interview success.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Support / Feedback'),
                  _SupportSection(
                    onSupport: () => _showInfoDialog(
                      context,
                      title: AppStrings.supportTitle,
                      body: AppStrings.supportBody,
                    ),
                    onFeedback: () => context.push(RouteNames.feedbackPath),
                    onRate: () => _rateApp(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Confirm → delete (asking for the password if the server wants a recent
  /// sign-in) → back to onboarding. The steps live in
  /// [AccountDeletionController]; this only drives the dialogs.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final hasAccount = ref.read(currentAuthUserProvider) != null;
    if (!await confirmAccountDeletion(context, hasAccount: hasAccount) ||
        !context.mounted) {
      return;
    }
    final controller = ref.read(accountDeletionControllerProvider.notifier);
    var outcome = await controller.delete();
    if (outcome == AccountDeletionOutcome.needsPassword && context.mounted) {
      final password = await askPasswordForDeletion(context);
      if (password == null || !context.mounted) {
        return;
      }
      outcome = await controller.delete(password: password);
    }
    if (outcome != AccountDeletionOutcome.deleted || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hasAccount
                ? AppStrings.deleteAccountDone
                : AppStrings.deleteLocalDataDone,
          ),
        ),
      );
    context.go(RouteNames.onboardingPath);
  }

  /// Opens CvMate's App Store page (the user's own tap, so no rating rules).
  Future<void> _rateApp(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(reviewPrompterProvider).openStoreListing();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.rateCvMateFailed)),
        );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(AppStrings.settingsLogOutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    final success = await ref.read(logoutControllerProvider.notifier).signOut();
    if (!context.mounted) {
      return;
    }

    final state = ref.read(logoutControllerProvider);
    final message = success
        ? (state.successMessage ?? 'Logged out successfully.')
        : (state.errorMessage ?? 'Could not log out right now.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (success) {
      context.go(RouteNames.onboardingPath);
    }
  }

  Future<void> _handleResetPassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(email: email);
    if (!context.mounted) {
      return;
    }

    final state = ref.read(forgotPasswordControllerProvider);
    final message = success
        ? (state.successMessage ?? 'Password reset email sent.')
        : (state.errorMessage ?? 'Could not send a reset email right now.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final choice = await showClearDataDialog(
      context,
      hasCloudBackup:
          ref.read(cloudBackupStatusProvider) == CloudBackupStatus.on,
    );
    if (choice == null || !context.mounted) {
      return;
    }

    final message = await ref
        .read(settingsOverviewControllerProvider.notifier)
        .clearAllLocalCareerData(includeCloudBackup: choice.includeCloudBackup);
    if (!context.mounted || message == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.userEmail,
    required this.isLoggedOut,
    required this.isResettingPassword,
    required this.isLoggingOut,
    required this.onLogin,
    required this.onRegister,
    required this.onResetPassword,
    required this.onLogout,
  });

  final String? userEmail;
  final bool isLoggedOut;
  final bool isResettingPassword;
  final bool isLoggingOut;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback? onResetPassword;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(isLoggedOut ? 'Guest / local mode' : 'Signed in'),
            subtitle: Text(
              isLoggedOut ? AppStrings.settingsGuestModeBody : userEmail ?? '',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isLoggedOut) ...[
                CustomButton.secondary(
                  label: 'Login',
                  onPressed: onLogin,
                  icon: Icons.login_rounded,
                  isExpanded: false,
                ),
                CustomButton.secondary(
                  label: 'Register',
                  onPressed: onRegister,
                  icon: Icons.app_registration_rounded,
                  isExpanded: false,
                ),
              ] else ...[
                CustomButton.secondary(
                  label: isResettingPassword
                      ? 'Sending reset...'
                      : 'Reset password',
                  onPressed: isResettingPassword ? null : onResetPassword,
                  icon: Icons.lock_reset_rounded,
                  isExpanded: false,
                ),
                CustomButton.secondary(
                  label: isLoggingOut ? 'Logging out...' : 'Logout',
                  onPressed: isLoggingOut ? null : onLogout,
                  icon: Icons.logout_rounded,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AiSettingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConsent =
        ref.watch(appPreferencesControllerProvider).asData?.value.aiConsent ??
        false;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: const Text(AppStrings.aiFeaturesSetting),
            subtitle: Text(
              aiConsent
                  ? AppStrings.aiFeaturesOnNote
                  : AppStrings.aiFeaturesOffNote,
            ),
            value: aiConsent,
            onChanged: (enabled) async {
              final message = await ref
                  .read(appPreferencesControllerProvider.notifier)
                  .updateAiConsent(enabled: enabled);
              if (!context.mounted || message == null) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
          ),
          if (EnvConfig.isMockAiActive)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.science_outlined),
              title: Text(DevLabels.mockAiTitle),
              subtitle: Text(DevLabels.mockAiSubtitle),
            ),
        ],
      ),
    );
  }
}

class _DataManagementSection extends StatelessWidget {
  const _DataManagementSection({
    required this.overview,
    required this.onClearData,
  });

  final SettingsOverviewState overview;
  final VoidCallback? onClearData;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryChip(label: 'Saved CVs', value: overview.cvCount),
              _SummaryChip(
                label: 'Cover letters',
                value: overview.coverLetterCount,
              ),
              _SummaryChip(
                label: 'Job applications',
                value: overview.jobApplicationCount,
              ),
              _SummaryChip(
                label: 'Interview sessions',
                value: overview.interviewPrepSessionCount,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Clear all local data removes saved CVs, cover letter drafts, job applications, and interview prep sessions from this device.',
          ),
          const SizedBox(height: 16),
          CustomButton.secondary(
            label: overview.isClearingLocalData
                ? 'Clearing data...'
                : 'Clear all local data',
            onPressed: onClearData,
            icon: Icons.delete_sweep_outlined,
            isExpanded: false,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return CustomCard(child: _AboutContent(versionLabel: versionLabel));
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.brandName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(AppStrings.aboutTagline),
        const SizedBox(height: 8),
        Text(AppStrings.aboutVersion(versionLabel)),
        const SizedBox(height: 12),
        const Text(AppStrings.aboutBody),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.onOpenPrivacy,
    required this.onOpenTerms,
    required this.onOpenAiDisclaimer,
    required this.onOpenAtsDisclaimer,
  });

  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenAiDisclaimer;
  final VoidCallback onOpenAtsDisclaimer;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenPrivacy,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenTerms,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('AI disclaimer'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenAiDisclaimer,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('ATS disclaimer'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenAtsDisclaimer,
          ),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
    required this.onSupport,
    required this.onFeedback,
    required this.onRate,
  });

  final VoidCallback onSupport;
  final VoidCallback onFeedback;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Support / contact'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onSupport,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text(AppStrings.feedbackEntry),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onFeedback,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star_outline_rounded),
            title: const Text(AppStrings.rateCvMate),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: onRate,
          ),
        ],
      ),
    );
  }
}

/// Settings > Privacy > Share usage analytics. Takes effect at once: the
/// telemetry bootstrap listens to the preference.
class _PrivacySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share =
        ref
            .watch(appPreferencesControllerProvider)
            .asData
            ?.value
            .shareUsageAnalytics ??
        true;

    return CustomCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.insights_outlined),
        title: const Text(AppStrings.shareUsageAnalytics),
        subtitle: const Text(AppStrings.shareUsageAnalyticsNote),
        value: share,
        onChanged: (enabled) async {
          final message = await ref
              .read(appPreferencesControllerProvider.notifier)
              .updateShareUsageAnalytics(enabled: enabled);
          if (!context.mounted || message == null) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError ? colorScheme.error : const Color(0xFF0D6B44);
    final background = isError
        ? colorScheme.error.withValues(alpha: 0.08)
        : const Color(0xFFDFF7EA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: foreground),
      ),
    );
  }
}
