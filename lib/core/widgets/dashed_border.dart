import 'dart:ui' show PathMetric;

import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Draws a dashed outline around [child] — a rounded rectangle by default or a
/// circle when [circle] is true. Used for "add another" actions, suggested
/// chips and the photo placeholder. The outline is purely decorative and does
/// not take part in hit-testing.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.lineStrong,
    this.radius = 16,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
    this.circle = false,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
        circle: circle,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.circle,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final path = Path();
    if (circle) {
      path.addOval(rect);
    } else {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) {
    return old.color != color ||
        old.radius != radius ||
        old.strokeWidth != strokeWidth ||
        old.dashLength != dashLength ||
        old.gapLength != gapLength ||
        old.circle != circle;
  }
}
