import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Personal page: photo placeholder, name, headline, phone / location and
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
        const _PhotoBlock(),
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
        const SizedBox(height: AppSpacing.s16),
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

/// Profile photo placeholder. Photo upload is not implemented (the CV model has
/// no photo field), so the button is shown disabled instead of faking it.
class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock();

  static const double _size = 80;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DashedBorder(
          circle: true,
          color: AppColors.placeholder.withValues(alpha: 0.6),
          child: Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.builderPhotoTitle,
                style: AppTextStyles.itemTitle,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(AppStrings.builderPhotoHint, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.s8),
              // TODO(photo-upload): enable once the CV model can store a photo.
              Tooltip(
                message: AppStrings.builderPhotoComingSoon,
                child: Opacity(
                  opacity: 0.55,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadii.pillRadius,
                    ),
                    child: Text(
                      AppStrings.builderPhotoUpload,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
