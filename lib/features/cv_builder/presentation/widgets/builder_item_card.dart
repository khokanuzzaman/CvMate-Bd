import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:flutter/material.dart';

/// Card for one repeatable entry (degree, role, project …): an uppercase title
/// such as "DEGREE 1", a remove button, and the entry's fields.
class BuilderItemCard extends StatelessWidget {
  const BuilderItemCard({
    super.key,
    required this.title,
    required this.onRemove,
    required this.child,
  });

  final String title;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s8,
        AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SectionLabel(title),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: AppStrings.builderRemoveEntry,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.muted2,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: child,
          ),
        ],
      ),
    );
  }
}
