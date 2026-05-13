import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/logout_controller.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = ref.watch(currentAuthUserProvider);
    final logoutState = ref.watch(logoutControllerProvider);
    final forgotPasswordState = ref.watch(forgotPasswordControllerProvider);
    final overview = ref.watch(settingsOverviewControllerProvider);
    final theme = Theme.of(context);
    final avatarLabel = user != null && user.email.trim().isNotEmpty
        ? user.email.trim().substring(0, 1).toUpperCase()
        : 'G';

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: session.isLoading && user == null
                  ? const CustomLoadingView(
                      message: 'Loading account details...',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                child: Text(avatarLabel),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayLabel ??
                                          'Guest / local mode',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ??
                                          'Using CareerMate BD without a signed-in account.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (user == null)
                          const CustomEmptyState(
                            title: 'No account signed in',
                            message:
                                'You can keep using local-first career tools as a guest, or sign in for Firebase Auth account access.',
                            icon: Icons.person_outline_rounded,
                          )
                        else
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account details',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Text('Firebase UID: ${user.uid}'),
                                const SizedBox(height: 8),
                                const Text(
                                  'Local CVs, cover letters, job applications, and interview prep sessions remain on this device until cloud sync is added later.',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        overview.when(
                          loading: () => const CustomCard(
                            child: LinearProgressIndicator(minHeight: 8),
                          ),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                          data: (data) => CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local data on this device',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    Chip(label: Text('CVs: ${data.cvCount}')),
                                    Chip(
                                      label: Text(
                                        'Cover letters: ${data.coverLetterCount}',
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        'Applications: ${data.jobApplicationCount}',
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        'Interview sessions: ${data.interviewPrepSessionCount}',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (logoutState.errorMessage != null) ...[
                          _InlineMessage(
                            message: logoutState.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (forgotPasswordState.errorMessage != null) ...[
                          _InlineMessage(
                            message: forgotPasswordState.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (user == null) ...[
                              CustomButton(
                                label: 'Login',
                                onPressed: () =>
                                    context.push(RouteNames.loginPath),
                                icon: Icons.login_rounded,
                                isExpanded: false,
                              ),
                              CustomButton.secondary(
                                label: 'Create account',
                                onPressed: () =>
                                    context.push(RouteNames.registerPath),
                                icon: Icons.app_registration_rounded,
                                isExpanded: false,
                              ),
                            ] else ...[
                              CustomButton.secondary(
                                label: forgotPasswordState.isLoading
                                    ? 'Sending reset...'
                                    : 'Reset password',
                                onPressed: forgotPasswordState.isLoading
                                    ? null
                                    : () => _handleResetPassword(
                                        context,
                                        ref,
                                        user.email,
                                      ),
                                icon: Icons.lock_reset_rounded,
                                isExpanded: false,
                              ),
                              CustomButton.secondary(
                                label: logoutState.isLoading
                                    ? 'Logging out...'
                                    : 'Logout',
                                onPressed: logoutState.isLoading
                                    ? null
                                    : () => _confirmLogout(context, ref),
                                icon: Icons.logout_rounded,
                                isExpanded: false,
                              ),
                            ],
                            CustomButton.secondary(
                              label: 'Open settings',
                              onPressed: () =>
                                  context.push(RouteNames.settingsPath),
                              icon: Icons.settings_outlined,
                              isExpanded: false,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
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

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Log out now? Your local CVs and drafts will remain on this device.',
          ),
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
