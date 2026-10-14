import 'dart:typed_data';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/shared/services/image/image_processing.dart';
import 'package:flutter/material.dart';

/// Fits the picked photo into a 35x45 passport frame (drag to move, pinch to
/// zoom) and pops with the cropped JPEG, or null when cancelled.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.image});

  final PreparedImage image;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const double _ratio = 45 / 35;

  final TransformationController _controller = TransformationController();
  Size _frame = Size.zero;
  double _fit = 1;
  bool _working = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sizes the frame, scales the photo to just cover it and centres it.
  void _layout(Size frame) {
    if (frame == _frame) {
      return;
    }
    _frame = frame;
    final image = widget.image;
    _fit = (frame.width / image.width) > (frame.height / image.height)
        ? frame.width / image.width
        : frame.height / image.height;
    final dx = (image.width * _fit - frame.width) / 2;
    final dy = (image.height * _fit - frame.height) / 2;
    _controller.value = Matrix4.identity()..setTranslationRaw(-dx, -dy, 0);
  }

  CropFraction _visibleFraction() => CropFraction.fromViewport(
    matrix: _controller.value,
    frame: _frame,
    imageWidth: widget.image.width,
    imageHeight: widget.image.height,
    fit: _fit,
  );

  Future<void> _use() async {
    setState(() {
      _working = true;
      _failed = false;
    });
    try {
      final bytes = await ImageProcessing.cropPhotoAsync(
        widget.image.bytes,
        _visibleFraction(),
      );
      if (mounted) {
        Navigator.of(context).pop<Uint8List>(bytes);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _working = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s4,
              ),
              child: AppTopBar(
                title: AppStrings.photoCropTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.s8,
              ),
              child: Text(AppStrings.photoCropHint, style: AppTextStyles.body),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var width = constraints.maxWidth - 2 * AppSpacing.screen;
                  if (width * _ratio > constraints.maxHeight) {
                    width = constraints.maxHeight / _ratio;
                  }
                  width = width.clamp(120.0, 340.0);
                  _layout(Size(width, width * _ratio));
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                      child: SizedBox(
                        width: _frame.width,
                        height: _frame.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            InteractiveViewer(
                              transformationController: _controller,
                              constrained: false,
                              minScale: 1,
                              maxScale: 4,
                              boundaryMargin: EdgeInsets.zero,
                              child: Image.memory(
                                image.bytes,
                                width: image.width * _fit,
                                height: image.height * _fit,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            ),
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.input,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Text(
                  AppStrings.photoFailed,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s8,
                AppSpacing.screen,
                AppSpacing.s16,
              ),
              child: PrimaryButton(
                label: AppStrings.photoCropUse,
                onPressed: _working ? null : _use,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
