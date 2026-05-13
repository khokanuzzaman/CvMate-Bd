import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter/material.dart';

class CvTemplateSelector extends StatelessWidget {
  const CvTemplateSelector({
    super.key,
    required this.selectedTemplate,
    required this.onSelected,
  });

  final CvTemplate selectedTemplate;
  final ValueChanged<CvTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final itemWidth = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final template in CvTemplate.values)
              SizedBox(
                width: itemWidth,
                child: CustomCard(
                  onTap: () => onSelected(template),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: selectedTemplate == template
                              ? colorScheme.primary.withValues(alpha: 0.14)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.label,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Icon(
                              selectedTemplate == template
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selectedTemplate == template
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        template.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
