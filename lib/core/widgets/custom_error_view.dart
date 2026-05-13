import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class CustomErrorView extends StatelessWidget {
  const CustomErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colorScheme.error.withValues(alpha: 0.12),
                foregroundColor: colorScheme.error,
                child: const Icon(Icons.error_outline, size: 28),
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
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Try again',
                  onPressed: onRetry,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
