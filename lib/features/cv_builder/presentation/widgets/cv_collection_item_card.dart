import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:flutter/material.dart';

class CvCollectionItemCard extends StatelessWidget {
  const CvCollectionItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
          for (final detail in details.where((item) => item.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(detail, style: theme.textTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}
