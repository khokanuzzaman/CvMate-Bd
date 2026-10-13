import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:flutter/widgets.dart';

/// Whether the system text size is large enough that two-column layouts
/// should give way to stacked ones (above `AppConstants.largeTextScaleFactor`).
bool isLargeText(BuildContext context) {
  const probe = 100.0;
  return MediaQuery.textScalerOf(context).scale(probe) >
      probe * AppConstants.largeTextScaleFactor + 0.001;
}

/// Caps the system text scale at `AppConstants.maxTextScaleFactor` for the
/// whole subtree, so the fixed-height chrome (bars, pills, pinned buttons)
/// still fits at the largest accessibility sizes.
class TextScaleClamp extends StatelessWidget {
  const TextScaleClamp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppConstants.maxTextScaleFactor,
      child: child,
    );
  }
}
