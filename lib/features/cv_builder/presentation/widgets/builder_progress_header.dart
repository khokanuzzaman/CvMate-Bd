import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/progress_bar.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/builder_pages.dart';
import 'package:flutter/material.dart';

/// "Step N of M · Section", the percentage, and the progress bar. The bar and
/// percentage turn `success` green at 100%.
class BuilderProgressHeader extends StatelessWidget {
  const BuilderProgressHeader({
    super.key,
    required this.profile,
    required this.pages,
    required this.page,
  });

  final CvProfile profile;
  final List<BuilderPageRef> pages;
  final BuilderPageRef page;

  @override
  Widget build(BuildContext context) {
    final progress = CvBuilderPages.progress(pages, page);
    final percent = CvBuilderPages.percent(pages, page);
    final index = CvBuilderPages.indexOf(pages, page) + 1;
    final section = CvBuilderPages.sectionTitle(profile, page);
    final isDone = progress >= 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Semantics(
        label: AppStrings.builderStepLabel(index, pages.length, section),
        value: '$percent%',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.builderStepLabel(index, pages.length, section),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDone ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              ProgressBar(value: progress),
            ],
          ),
        ),
      ),
    );
  }
}
