import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/presentation/controllers/logout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shows the privacy policy and terms (the same texts Settings shows).
Future<void> showPrivacyTermsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(AppStrings.profilePrivacyTerms),
      content: const SingleChildScrollView(
        child: Text(
          '${AppStrings.privacyPolicyBody}\n\n${AppStrings.termsBody}',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(AppStrings.legalClose),
        ),
      ],
    ),
  );
}

/// Confirms, signs out through [LogoutController] and returns to onboarding.
Future<void> confirmAndLogOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(AppStrings.logOutTitle),
      content: const Text(AppStrings.logOutBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.logOutCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(AppStrings.profileLogOut),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  final success = await ref.read(logoutControllerProvider.notifier).signOut();
  if (!context.mounted) {
    return;
  }

  final state = ref.read(logoutControllerProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? (state.successMessage ?? 'Logged out successfully.')
            : (state.errorMessage ?? 'Could not log out right now.'),
      ),
    ),
  );

  if (success) {
    context.go(RouteNames.onboardingPath);
  }
}
