import 'dart:math' as math;

import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Circular ATS score — track `ringTrack` (width 9), amber `accent` arc (width
/// 9, rounded cap), centered % in Sora 700. (DESIGN_TOKENS.md → ScoreRing)
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.percent,
    this.size = 120,
    this.stroke = 9,
  });

  /// 0–100.
  final int percent;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(fraction: clamped / 100, stroke: stroke),
        child: Center(
          child: Text(
            '$clamped%',
            style: AppTextStyles.numeric.copyWith(fontSize: size * 0.24),
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({required this.fraction, required this.stroke});

  final double fraction;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..color = AppColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (fraction <= 0) {
      return;
    }

    final arc = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.stroke != stroke;
  }
}
