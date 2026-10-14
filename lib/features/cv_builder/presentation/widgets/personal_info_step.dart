import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/style_labels.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/personal_details_card.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/photo_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Personal page: photo, name, headline, phone / location and
/// links, plus the CV title and email the app requires.
class PersonalInfoStep extends ConsumerWidget {
  const PersonalInfoStep({super.key, required this.showValidationErrors});

  final bool showValidationErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(cvBuilderControllerProvider).draft;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final info = draft.personalInfo;
    final autovalidate = showValidationErrors
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;

    void update(PersonalInfo Function(PersonalInfo current) change) {
      final current = ref.read(cvBuilderControllerProvider).draft.personalInfo;
      notifier.updatePersonalInfo(change(current));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _StylePill(style: draft.style),
        ),
        const SizedBox(height: AppSpacing.s8),
        const PhotoBlock(),
        const SizedBox(height: AppSpacing.s22),
        AppTextField(
          initialValue: info.fullName,
          label: AppStrings.builderFullName,
          hintText: AppStrings.builderFullNameHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: (value) => Validators.requiredText(
            value,
            fieldName: AppStrings.builderFullName,
          ),
          onChanged: (value) => update((i) => i.copyWith(fullName: value)),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          initialValue: info.desiredRole,
          label: AppStrings.builderHeadline,
          hintText: AppStrings.builderHeadlineHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: (value) => Validators.requiredText(
            value,
            fieldName: AppStrings.builderHeadline,
          ),
          onChanged: (value) => update((i) => i.copyWith(desiredRole: value)),
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                initialValue: info.phone,
                label: AppStrings.builderPhone,
                hintText: AppStrings.builderPhoneHint,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                fillColor: AppColors.surface,
                autovalidateMode: autovalidate,
                validator: Validators.bangladeshPhone,
                onChanged: (value) => update((i) => i.copyWith(phone: value)),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppTextField(
                initialValue: info.address,
                label: AppStrings.builderLocation,
                hintText: AppStrings.builderLocationHint,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                fillColor: AppColors.surface,
                autovalidateMode: autovalidate,
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: AppStrings.builderLocation,
                ),
                onChanged: (value) => update((i) => i.copyWith(address: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          initialValue: info.linkedInUrl,
          label: AppStrings.builderWebsite,
          hintText: AppStrings.builderWebsiteHint,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: Validators.optionalUrl,
          onChanged: (value) => update((i) => i.copyWith(linkedInUrl: value)),
        ),
        const SizedBox(height: AppSpacing.s16),
        // Fields the app requires or stores that the design does not show.
        AppTextField(
          initialValue: info.email,
          label: AppStrings.builderEmail,
          hintText: AppStrings.builderEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: Validators.email,
          onChanged: (value) => update((i) => i.copyWith(email: value)),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          initialValue: info.portfolioUrl,
          label: AppStrings.builderPortfolio,
          hintText: AppStrings.builderPortfolioHint,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: Validators.optionalUrl,
          onChanged: (value) => update((i) => i.copyWith(portfolioUrl: value)),
        ),
        const SizedBox(height: AppSpacing.s22),
        const PersonalDetailsCard(),
        const SizedBox(height: AppSpacing.s22),
        AppTextField(
          initialValue: draft.title,
          label: AppStrings.builderCvTitle,
          hintText: AppStrings.builderCvTitleHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          fillColor: AppColors.surface,
          autovalidateMode: autovalidate,
          validator: (value) => Validators.requiredText(
            value,
            fieldName: AppStrings.builderCvTitle,
          ),
          onChanged: notifier.updateTitle,
        ),
      ],
    );
  }
}

/// The CV's market style; tapping opens the CV style screen.
class _StylePill extends StatelessWidget {
  const _StylePill({required this.style});

  final CvStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${AppStrings.styleTooltip}: ${styleShortName(style)}',
      child: Material(
        color: AppColors.accentSoft,
        borderRadius: AppRadii.pillRadius,
        child: InkWell(
          onTap: () => context.push(RouteNames.cvStylePath),
          borderRadius: AppRadii.pillRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${styleShortName(style)} style',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.accentInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.accentInk,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
