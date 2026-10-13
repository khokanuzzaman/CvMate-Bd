import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_next_action.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/utils/job_next_action_text.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_status_chip.dart';
import 'package:flutter/material.dart';

/// One application: initial tile, role, "Company · via Source", status pill and
/// — when there is something to do — a next-action strip. Tapping the card opens
/// its details; tapping an interview strip opens interview prep instead.
class JobApplicationCard extends StatelessWidget {
  const JobApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
    required this.onPrep,
    this.now,
  });

  final JobApplication application;
  final VoidCallback onTap;
  final VoidCallback onPrep;

  /// Clock for the next-action hint (tests pass a fixed one).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final title = application.jobTitle.trim().isEmpty
        ? AppStrings.trackerUntitledRole
        : application.jobTitle.trim();
    final company = application.companyName.trim().isEmpty
        ? AppStrings.trackerUnknownCompany
        : application.companyName.trim();
    final action = JobNextAction.of(application, now: now);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialTile(
                text: company,
                offered: application.status == JobApplicationStatus.offered,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppStrings.trackerVia(
                        company,
                        application.jobSource.label,
                      ),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              JobStatusChip(status: application.status),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.s12),
            _ActionStrip(
              action: action,
              text: jobNextActionText(action, now: now),
              onPrep: onPrep,
            ),
          ],
        ],
      ),
    );
  }
}

class _InitialTile extends StatelessWidget {
  const _InitialTile({required this.text, required this.offered});

  final String text;
  final bool offered;

  @override
  Widget build(BuildContext context) {
    final initial = text.trim().isEmpty
        ? '?'
        : String.fromCharCode(text.trim().runes.first).toUpperCase();

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: offered ? AppColors.successSoft : AppColors.primarySoft,
        borderRadius: AppRadii.iconTileRadius,
      ),
      child: Text(
        initial,
        style: AppTextStyles.numeric.copyWith(
          fontSize: 18,
          color: offered ? AppColors.successText : AppColors.primary,
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.action,
    required this.text,
    required this.onPrep,
  });

  final JobNextAction action;
  final String text;
  final VoidCallback onPrep;

  @override
  Widget build(BuildContext context) {
    final isInterview = action.kind == JobNextActionKind.interview;
    final foreground = isInterview ? AppColors.accentInk : AppColors.inkSoft;

    final strip = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: isInterview
            ? AppColors.accentSoft.withValues(alpha: 0.4)
            : AppColors.bg,
        borderRadius: AppRadii.inputRadius,
      ),
      child: Row(
        children: [
          Icon(
            isInterview ? Icons.event_outlined : Icons.schedule_rounded,
            size: 18,
            color: isInterview ? AppColors.accentInk : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isInterview) {
      return strip;
    }
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPrep,
        borderRadius: AppRadii.inputRadius,
        child: strip,
      ),
    );
  }
}
