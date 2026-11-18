import 'package:careermatebd/app/constants/app_links.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Asks before deleting. With an account it says that a subscription must
/// be cancelled in the store and links there; without one (guest) it only
/// removes local data. True when the user confirms.
Future<bool> confirmAccountDeletion(
  BuildContext context, {
  required bool hasAccount,
}) async {
  final apple = defaultTargetPlatform == TargetPlatform.iOS;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        hasAccount
            ? AppStrings.deleteAccountTitle
            : AppStrings.deleteLocalDataTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasAccount
                  ? AppStrings.deleteAccountBody
                  : AppStrings.deleteLocalDataBody,
            ),
            if (hasAccount) ...[
              const SizedBox(height: 12),
              Text(AppStrings.deleteAccountSubscriptionNote(apple: apple)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      apple
                          ? AppLinks.appleSubscriptions
                          : AppLinks.googlePlaySubscriptions,
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    AppStrings.deleteAccountManageSubscriptions,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.deleteAccountCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(AppStrings.deleteAccountConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks for the password when Firebase needs a recent sign-in. Null when the
/// user cancels.
Future<String?> askPasswordForDeletion(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _PasswordDialog(),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isNotEmpty) {
      Navigator.of(context).pop(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.deleteAccountPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.deleteAccountPasswordBody),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: AppStrings.deleteAccountPasswordLabel,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.deleteAccountCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.deleteAccountConfirm),
        ),
      ],
    );
  }
}
