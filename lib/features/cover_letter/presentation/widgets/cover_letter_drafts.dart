import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:flutter/material.dart';

/// "Recent drafts": saved cover letters that can be reopened or deleted.
class CoverLetterDrafts extends StatelessWidget {
  const CoverLetterDrafts({
    super.key,
    required this.drafts,
    required this.cvs,
    required this.activeDraftId,
    required this.onOpen,
    required this.onDelete,
  });

  final List<CoverLetterDraft> drafts;
  final List<CvProfile> cvs;
  final String? activeDraftId;
  final ValueChanged<String> onOpen;
  final ValueChanged<CoverLetterDraft> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(AppStrings.coverLetterRecentDrafts),
        const SizedBox(height: AppSpacing.s10),
        for (final draft in drafts) ...[
          _DraftCard(
            draft: draft,
            isActive: draft.id == activeDraftId,
            cvTitle: _cvTitle(draft.cvId),
            onOpen: () => onOpen(draft.id),
            onDelete: () => onDelete(draft),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }

  String? _cvTitle(String? id) {
    for (final cv in cvs) {
      if (cv.id == id) {
        return cv.displayTitle;
      }
    }
    return null;
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.isActive,
    required this.cvTitle,
    required this.onOpen,
    required this.onDelete,
  });

  final CoverLetterDraft draft;
  final bool isActive;
  final String? cvTitle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            draft.displayTitle,
                            style: AppTextStyles.itemTitle,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: AppSpacing.s8),
                          const _OpenBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      AppStrings.coverLetterDraftMeta(
                        draft.outputType.label,
                        DateFormatter.shortDateTime(draft.updatedAt),
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (cvTitle != null)
                      Text(
                        AppStrings.coverLetterDraftCv(cvTitle!),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: AppStrings.coverLetterDeleteDraft,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            draft.previewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.s12),
          SecondaryButton(
            label: AppStrings.coverLetterOpenDraft,
            leadingIcon: Icons.edit_outlined,
            expanded: false,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        AppStrings.coverLetterOpenBadge,
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
