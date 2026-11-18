import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Asks for the user's full name when the CV has none, so the letter can be
/// signed with it. Returns the trimmed name, or null when cancelled.
Future<String?> showCandidateNameDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _CandidateNameDialog(),
  );
}

class _CandidateNameDialog extends StatefulWidget {
  const _CandidateNameDialog();

  @override
  State<_CandidateNameDialog> createState() => _CandidateNameDialogState();
}

class _CandidateNameDialogState extends State<_CandidateNameDialog> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    final name = _name.trim();
    return AlertDialog(
      title: const Text(AppStrings.coverLetterNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.coverLetterNameBody),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            label: AppStrings.coverLetterNameLabel,
            autofocus: true,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (value) => setState(() => _name = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.coverLetterCancel),
        ),
        FilledButton(
          onPressed: name.isEmpty
              ? null
              : () => Navigator.of(context).pop(name),
          child: const Text(AppStrings.coverLetterNameContinue),
        ),
      ],
    );
  }
}
