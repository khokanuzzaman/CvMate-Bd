import 'dart:typed_data';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/photo_crop_screen.dart';
import 'package:careermatebd/shared/services/image/image_processing.dart';
import 'package:careermatebd/shared/services/image/photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Passport-style photo: take or pick one, fit it into a 35x45 frame, keep it
/// with the CV. It is only printed while the Photo switch below is on.
class PhotoBlock extends ConsumerStatefulWidget {
  const PhotoBlock({super.key});

  @override
  ConsumerState<PhotoBlock> createState() => _PhotoBlockState();
}

class _PhotoBlockState extends ConsumerState<PhotoBlock> {
  static const double _width = 76;
  static const double _height = _width * 45 / 35;

  bool _busy = false;

  Future<void> _pick(PhotoSource source) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await ref.read(photoPickerProvider).pick(source);
      if (picked == null || !mounted) {
        return;
      }
      final prepared = await ImageProcessing.prepareForCropAsync(picked);
      if (!mounted) {
        return;
      }
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => PhotoCropScreen(image: prepared)),
      );
      if (cropped != null) {
        ref.read(cvBuilderControllerProvider.notifier).setPhoto(cropped);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(AppStrings.photoFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = ref.watch(
      cvBuilderControllerProvider.select((state) => state.draft.photo),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _frame(photo),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.photoPassportTitle,
                style: AppTextStyles.itemTitle,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(AppStrings.photoPassportHint, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  _Pill(
                    label: AppStrings.photoTake,
                    filled: true,
                    onTap: _busy ? null : () => _pick(PhotoSource.camera),
                  ),
                  _Pill(
                    label: AppStrings.photoGallery,
                    onTap: _busy ? null : () => _pick(PhotoSource.gallery),
                  ),
                  if (photo != null)
                    _Pill(
                      label: AppStrings.photoRemove,
                      onTap: () => ref
                          .read(cvBuilderControllerProvider.notifier)
                          .setPhoto(null),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _frame(Uint8List? photo) {
    return DashedBorder(
      color: AppColors.placeholder.withValues(alpha: 0.6),
      radius: AppRadii.input,
      child: Container(
        width: _width,
        height: _height,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: photo == null
            ? const Icon(
                Icons.person_outline_rounded,
                size: 34,
                color: AppColors.primary,
              )
            : Image.memory(
                photo,
                width: _width,
                height: _height,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Material(
        color: filled ? AppColors.primary : AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pillRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Center(
                widthFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySm.copyWith(
                      color: filled ? AppColors.onPrimary : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
