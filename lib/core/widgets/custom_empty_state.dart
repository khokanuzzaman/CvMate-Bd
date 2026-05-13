import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class CustomEmptyState extends StatelessWidget {
  const CustomEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: colorScheme.primary,
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            CustomButton(
              label: actionLabel!,
              onPressed: onAction,
              isExpanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
