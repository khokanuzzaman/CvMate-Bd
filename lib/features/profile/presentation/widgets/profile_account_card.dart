import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:flutter/material.dart';

/// Avatar, name, email and the plan badge. [isPro] is null while the plan is
/// still loading, in which case no badge is shown rather than a wrong one.
class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    super.key,
    required this.user,
    required this.isPro,
  });

  final AuthUser? user;
  final bool? isPro;

  @override
  Widget build(BuildContext context) {
    final email = user?.email.trim() ?? '';
    final displayName = user?.displayName?.trim() ?? '';
    final isGuest = user == null || (displayName.isEmpty && email.isEmpty);

    final name = isGuest
        ? AppStrings.profileGuest
        : (displayName.isNotEmpty ? displayName : email);
    final detail = isGuest
        ? AppStrings.profileGuestSubtitle
        : (displayName.isNotEmpty ? email : null);
    final initial = isGuest ? 'G' : name.substring(0, 1).toUpperCase();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: AppTextStyles.numeric.copyWith(
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.itemTitle.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isPro != null) ...[
            const SizedBox(width: AppSpacing.s8),
            _PlanBadge(isPro: isPro!),
          ],
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: isPro ? AppColors.accentSoft : AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
        border: isPro ? null : Border.all(color: AppColors.lineStrong),
      ),
      child: Text(
        isPro ? AppStrings.planPro : AppStrings.planFree,
        style: AppTextStyles.bodySm.copyWith(
          color: isPro ? AppColors.accentInk : AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
