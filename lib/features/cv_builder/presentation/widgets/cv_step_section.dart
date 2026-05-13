import 'package:flutter/material.dart';

class CvStepSection extends StatelessWidget {
  const CvStepSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.helper,
  });

  final String title;
  final String description;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description, style: theme.textTheme.bodyMedium),
        if (helper != null) ...[
          const SizedBox(height: 10),
          Text(helper!, style: theme.textTheme.labelMedium),
        ],
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}
