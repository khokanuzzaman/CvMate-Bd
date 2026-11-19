import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:flutter/material.dart';

/// Shows which job post the ATS check matches against (and where it came
/// from), with Change / Clear, or an "Add job post" action when there is
/// none.
class AtsJobPostCard extends StatelessWidget {
  const AtsJobPostCard({
    super.key,
    required this.jobPost,
    required this.source,
    required this.onEdit,
    required this.onClear,
  });

  final String jobPost;
  final AtsJobPostSource source;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final post = jobPost.trim();
    final origin = switch (source) {
      AtsJobPostSource.tailor => AppStrings.atsJobPostFromTailor,
      AtsJobPostSource.typed => AppStrings.atsJobPostAddedHere,
      _ => null,
    };
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s14,
        AppSpacing.s8,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.atsJobPostLabel, style: AppTextStyles.itemTitle),
              if (post.isNotEmpty && origin != null) ...[
                const SizedBox(width: AppSpacing.s8),
                Text(
                  origin,
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: Text(
              post.isEmpty ? AppStrings.atsJobPostNone : post,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (post.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  child: const Text(AppStrings.atsJobPostClear),
                ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  post.isEmpty
                      ? AppStrings.atsJobPostAdd
                      : AppStrings.atsJobPostChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lets the user paste or edit the job post. Returns the text, or null when
/// dismissed.
Future<String?> showAtsJobPostSheet(BuildContext context, String initial) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => _JobPostSheet(initial: initial),
  );
}

class _JobPostSheet extends StatefulWidget {
  const _JobPostSheet({required this.initial});

  final String initial;

  @override
  State<_JobPostSheet> createState() => _JobPostSheetState();
}

class _JobPostSheetState extends State<_JobPostSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.atsJobPostSheetTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: _text,
            hintText: AppStrings.atsJobPostSheetHint,
            minLines: 6,
            maxLines: 10,
          ),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: AppStrings.atsJobPostSave,
            onPressed: () => Navigator.of(context).pop(_text.text),
          ),
        ],
      ),
    );
  }
}
