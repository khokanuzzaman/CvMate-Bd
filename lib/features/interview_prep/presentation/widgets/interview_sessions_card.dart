import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:flutter/material.dart';

/// Recent saved sessions (the latest four); tapping one opens it.
class InterviewSessionsCard extends StatelessWidget {
  const InterviewSessionsCard({
    super.key,
    required this.sessions,
    required this.onOpen,
  });

  final List<InterviewPrepSession> sessions;
  final ValueChanged<String> onOpen;

  static const int maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final shown = sessions.take(maxShown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(AppStrings.interviewSessionsTitle),
        const SizedBox(height: AppSpacing.s10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, session) in shown.indexed) ...[
                if (index > 0) const Divider(height: 1, color: AppColors.line),
                _SessionRow(session: session, onTap: () => onOpen(session.id)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final InterviewPrepSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayTitle,
                        style: AppTextStyles.itemTitle,
                      ),
                      Text(
                        AppStrings.interviewSessionMeta(
                          session.displaySubtitle,
                          DateFormatter.shortDateTime(session.updatedAt),
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
