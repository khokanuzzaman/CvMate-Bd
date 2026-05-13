import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:flutter/material.dart';

class CvBuilderStepper extends StatelessWidget {
  const CvBuilderStepper({
    super.key,
    required this.currentStep,
    required this.onStepSelected,
  });

  final CvBuilderStep currentStep;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentIndex = currentStep.index;
    final progress = (currentIndex + 1) / CvBuilderStep.values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${currentIndex + 1} of ${CvBuilderStep.values.length}',
              style: theme.textTheme.labelLarge,
            ),
            const Spacer(),
            Text(currentStep.title, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CvBuilderStep.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final step = CvBuilderStep.values[index];
              final isActive = index == currentIndex;
              final isCompleted = index < currentIndex;

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onStepSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : isCompleted
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      Text(
                        step.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isActive
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
