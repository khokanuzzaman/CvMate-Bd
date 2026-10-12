import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// One compact, tappable line above the CV paper ("2 things to fix") that
/// expands to the full list of review notes. Renders nothing when there are
/// none. Uses the soft amber tokens (`accentSoft` / `accentInk`).
class PreviewWarningsBanner extends StatefulWidget {
  const PreviewWarningsBanner({super.key, required this.warnings});

  final List<String> warnings;

  @override
  State<PreviewWarningsBanner> createState() => _PreviewWarningsBannerState();
}

class _PreviewWarningsBannerState extends State<PreviewWarningsBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final warnings = widget.warnings;
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = AppStrings.previewWarningsSummary(warnings.length);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.input + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: summary,
            hint: _expanded
                ? AppStrings.previewWarningsCollapse
                : AppStrings.previewWarningsExpand,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppRadii.input + 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s14,
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.accentInk,
                        ),
                        const SizedBox(width: AppSpacing.s10),
                        Expanded(
                          child: Text(
                            summary,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.accentInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.accentInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s14,
                      0,
                      AppSpacing.s14,
                      AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final warning in warnings)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '•  ',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.accentInk,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: AppTextStyles.bodySm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
