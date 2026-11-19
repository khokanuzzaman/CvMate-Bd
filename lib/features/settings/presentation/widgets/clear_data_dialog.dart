import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// What the user chose in the "Clear all local data" dialog.
class ClearDataChoice {
  const ClearDataChoice({required this.includeCloudBackup});

  final bool includeCloudBackup;
}

/// Asks before clearing local career data. When [hasCloudBackup] is true the
/// user can also delete the CV cloud backup, and the dialog says plainly what
/// happens either way. Returns null when cancelled.
Future<ClearDataChoice?> showClearDataDialog(
  BuildContext context, {
  required bool hasCloudBackup,
}) {
  return showDialog<ClearDataChoice>(
    context: context,
    builder: (_) => _ClearDataDialog(hasCloudBackup: hasCloudBackup),
  );
}

class _ClearDataDialog extends StatefulWidget {
  const _ClearDataDialog({required this.hasCloudBackup});

  final bool hasCloudBackup;

  @override
  State<_ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends State<_ClearDataDialog> {
  bool _includeCloud = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text(AppStrings.clearDataTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.clearDataBody),
            if (widget.hasCloudBackup) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _includeCloud,
                onChanged: (value) =>
                    setState(() => _includeCloud = value ?? false),
                title: const Text(AppStrings.clearDataAlsoCloud),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              Text(
                _includeCloud
                    ? AppStrings.clearDataCloudDeletedNote
                    : AppStrings.clearDataCloudKeptNote,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.clearDataCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(ClearDataChoice(includeCloudBackup: _includeCloud)),
          child: const Text(AppStrings.clearDataConfirm),
        ),
      ],
    );
  }
}
