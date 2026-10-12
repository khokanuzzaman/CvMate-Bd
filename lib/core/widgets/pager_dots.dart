import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Page / progress indicator dots. The dot at [index] uses [activeColor] and,
/// when [activeWidth] is set, stretches into a pill (onboarding); on the splash
/// it stays a circle. Purely presentational — wire it to a `PageView` later.
class PagerDots extends StatelessWidget {
  const PagerDots({
    super.key,
    required this.count,
    required this.index,
    required this.activeColor,
    required this.inactiveColor,
    this.dotSize = 8,
    this.activeWidth,
  }) : assert(count > 0, 'PagerDots needs at least one dot'),
       assert(index >= 0 && index < count, 'index must be within count');

  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double? activeWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.s6),
              child: Container(
                width: i == index ? (activeWidth ?? dotSize) : dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: i == index ? activeColor : inactiveColor,
                  borderRadius: AppRadii.pillRadius,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
