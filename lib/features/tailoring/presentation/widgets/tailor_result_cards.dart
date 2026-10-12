import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/placeholder_text.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/tailoring/domain/entities/tailoring_result.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A result card: an uppercase label (with an optional badge), the content, and
/// an Edit / Done link that swaps the content for editable fields.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.label,
    required this.editing,
    required this.onToggleEdit,
    required this.child,
    this.badge,
  });

  final String label;
  final bool editing;
  final VoidCallback onToggleEdit;
  final Widget child;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // A plain wrapping Text (not SectionLabel's Row) so a long label
              // wraps next to the badge instead of overflowing.
              Expanded(
                child: Text(label.toUpperCase(), style: AppTextStyles.label),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          child,
          Align(
            alignment: Alignment.centerLeft,
            child: _EditLink(editing: editing, onTap: onToggleEdit),
          ),
        ],
      ),
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.editing, required this.onTap});

  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = editing ? AppStrings.tailorDone : AppStrings.tailorEdit;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.inputRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  editing ? Icons.check_rounded : Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "AI tailored" pill.
class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 14,
            color: AppColors.accentInk,
          ),
          const SizedBox(width: AppSpacing.s6),
          Text(
            AppStrings.tailorAiTailored,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.accentInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable tailored professional summary.
class TailoredSummaryCard extends ConsumerStatefulWidget {
  const TailoredSummaryCard({super.key, required this.summary});

  final String summary;

  @override
  ConsumerState<TailoredSummaryCard> createState() =>
      _TailoredSummaryCardState();
}

class _TailoredSummaryCardState extends ConsumerState<TailoredSummaryCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      label: AppStrings.tailorSummaryLabel,
      badge: const _AiBadge(),
      editing: _editing,
      onToggleEdit: () => setState(() => _editing = !_editing),
      child: _editing
          ? AppTextArea(
              initialValue: widget.summary,
              minLines: 4,
              maxLines: 10,
              onChanged: ref
                  .read(tailoringControllerProvider.notifier)
                  .updateTailoredSummary,
            )
          : Text(
              widget.summary,
              style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
            ),
    );
  }
}

/// Emphasized skills: ones new to the CV are filled, existing ones outlined.
class TailoredSkillsCard extends ConsumerStatefulWidget {
  const TailoredSkillsCard({
    super.key,
    required this.skills,
    required this.sourceCv,
  });

  final List<String> skills;
  final CvProfile? sourceCv;

  @override
  ConsumerState<TailoredSkillsCard> createState() => _TailoredSkillsCardState();
}

class _TailoredSkillsCardState extends ConsumerState<TailoredSkillsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      label: AppStrings.tailorSkillsLabel,
      editing: _editing,
      onToggleEdit: () => setState(() => _editing = !_editing),
      child: _editing
          ? AppTextField(
              initialValue: widget.skills.join(', '),
              hintText: AppStrings.tailorSkillsEditHint,
              textCapitalization: TextCapitalization.words,
              onChanged: ref
                  .read(tailoringControllerProvider.notifier)
                  .updateEmphasizedSkillsText,
            )
          : Wrap(
              spacing: AppSpacing.s10,
              runSpacing: AppSpacing.s10,
              children: [
                for (final skill in widget.skills)
                  AppChip(
                    label: skill,
                    variant: isNewSkill(widget.sourceCv, skill)
                        ? AppChipVariant.selected
                        : AppChipVariant.neutral,
                  ),
              ],
            ),
    );
  }
}

/// Before / after for every rewritten experience bullet.
class TailoredBulletsCard extends ConsumerStatefulWidget {
  const TailoredBulletsCard({super.key, required this.bullets});

  final List<TailoredBullet> bullets;

  @override
  ConsumerState<TailoredBulletsCard> createState() =>
      _TailoredBulletsCardState();
}

class _TailoredBulletsCardState extends ConsumerState<TailoredBulletsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tailoringControllerProvider.notifier);

    return _ResultCard(
      label: AppStrings.tailorBulletsLabel,
      editing: _editing,
      onToggleEdit: () => setState(() => _editing = !_editing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.bullets.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s16),
            _BulletMark(
              icon: Icons.close_rounded,
              background: AppColors.danger.withValues(alpha: 0.12),
              color: AppColors.danger,
              semanticLabel: AppStrings.tailorBulletWas,
              child: Text(
                widget.bullets[i].original,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
            _BulletMark(
              icon: Icons.check_rounded,
              background: AppColors.successSoft,
              color: AppColors.success,
              semanticLabel: AppStrings.tailorBulletNow,
              child: _editing
                  ? AppTextArea(
                      key: ValueKey('bullet-$i'),
                      initialValue: widget.bullets[i].suggested,
                      minLines: 2,
                      maxLines: 6,
                      onChanged: (value) =>
                          notifier.updateBulletSuggestion(i, value),
                    )
                  : PlaceholderText(
                      widget.bullets[i].suggested,
                      highlight: true,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink),
                    ),
            ),
          ],
          const SizedBox(height: AppSpacing.s8),
          Text(
            AppStrings.tailorBulletsReview,
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BulletMark extends StatelessWidget {
  const _BulletMark({
    required this.icon,
    required this.background,
    required this.color,
    required this.semanticLabel,
    required this.child,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: semanticLabel,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: child),
      ],
    );
  }
}
