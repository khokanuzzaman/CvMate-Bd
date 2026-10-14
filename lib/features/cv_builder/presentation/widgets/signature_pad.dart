import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A pad to sign on. After every stroke it reports the signature as a PNG
/// cropped to the ink (transparent background), or null once cleared. An
/// [existing] signature is shown until the user draws a new one or clears it.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, required this.onChanged, this.existing});

  final Uint8List? existing;
  final ValueChanged<Uint8List?> onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  static const Color _ink = AppColors.ink;
  static const double _stroke = 3;

  final List<List<Offset>> _strokes = [];

  bool get _hasInk => _strokes.isNotEmpty;

  void _start(Offset point) {
    setState(() => _strokes.add([point]));
  }

  void _extend(Offset point) {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() => _strokes.last.add(point));
  }

  Future<void> _finish() async {
    final bytes = await _export();
    if (mounted) {
      widget.onChanged(bytes);
    }
  }

  void _clear() {
    setState(_strokes.clear);
    widget.onChanged(null);
  }

  /// The strokes as a PNG, cropped to the ink with a small margin.
  Future<Uint8List?> _export() async {
    final points = [for (final stroke in _strokes) ...stroke];
    if (points.isEmpty) {
      return null;
    }
    var left = points.first.dx, right = left;
    var top = points.first.dy, bottom = top;
    for (final p in points) {
      left = p.dx < left ? p.dx : left;
      right = p.dx > right ? p.dx : right;
      top = p.dy < top ? p.dy : top;
      bottom = p.dy > bottom ? p.dy : bottom;
    }
    const margin = 8.0;
    const scale = 2.0;
    final width = (right - left + 2 * margin).clamp(24.0, 4000.0);
    final height = (bottom - top + 2 * margin).clamp(24.0, 4000.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(margin - left, margin - top);
    _paintStrokes(canvas);
    final image = await recorder.endRecording().toImage(
      (width * scale).ceil(),
      (height * scale).ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _paintStrokes(Canvas canvas) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in _strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          _stroke / 2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final showExisting = !_hasInk && existing != null;
    final canClear = _hasInk || existing != null;

    return DashedBorder(
      color: AppColors.placeholder.withValues(alpha: 0.6),
      radius: AppRadii.card,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RawGestureDetector(
                // Win the gesture arena so drawing does not scroll the page.
                gestures: {
                  EagerGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        EagerGestureRecognizer
                      >(EagerGestureRecognizer.new, (_) {}),
                },
                child: Listener(
                  onPointerDown: (event) => _start(event.localPosition),
                  onPointerMove: (event) => _extend(event.localPosition),
                  onPointerUp: (_) => _finish(),
                  child: CustomPaint(
                    painter: _PadPainter(_strokes, _paintStrokes),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            if (showExisting)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s22,
                      AppSpacing.s22,
                      AppSpacing.s22,
                      44,
                    ),
                    child: Image.memory(existing, fit: BoxFit.contain),
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.s22,
              right: AppSpacing.s22,
              bottom: 36,
              child: const SizedBox(
                height: 1.5,
                child: ColoredBox(color: AppColors.lineStrong),
              ),
            ),
            Positioned(
              left: AppSpacing.s22,
              bottom: AppSpacing.s10,
              child: IgnorePointer(
                child: Text(
                  AppStrings.signatureSignAbove,
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            if (canClear)
              Positioned(
                top: AppSpacing.s10,
                right: AppSpacing.s10,
                child: Material(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadii.pillRadius,
                  child: InkWell(
                    onTap: _clear,
                    borderRadius: AppRadii.pillRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s8,
                      ),
                      child: Text(
                        AppStrings.signatureClear,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.strokes, this.paintStrokes);

  final List<List<Offset>> strokes;
  final void Function(Canvas canvas) paintStrokes;

  @override
  void paint(Canvas canvas, Size size) => paintStrokes(canvas);

  @override
  bool shouldRepaint(_PadPainter oldDelegate) => true;
}
