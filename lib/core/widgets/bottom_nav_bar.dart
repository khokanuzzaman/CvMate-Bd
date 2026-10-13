import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class BottomNavItem {
  const BottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// App bottom navigation — white, top `line` border, 5 items; active `primary`,
/// inactive `muted2`; the center item (index 2) is a raised amber circle with a
/// white border. (DESIGN_TOKENS.md → BottomNavBar)
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
  }) : assert(items.length == 5, 'BottomNavBar expects exactly 5 items');

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  static const List<BottomNavItem> defaultItems = [
    BottomNavItem(icon: Icons.home_outlined, label: 'Home'),
    BottomNavItem(icon: Icons.description_outlined, label: 'CVs'),
    BottomNavItem(icon: Icons.gps_fixed, label: 'Tailor'),
    BottomNavItem(icon: Icons.work_outline_rounded, label: 'Tracker'),
    BottomNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          // The bar has a fixed 64px height, so its labels cannot grow with the
          // system text size (at 2x "Tracker" broke into "Tracke / r" and
          // overflowed). Cap them at 1.3x, which still fits.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: i == 2
                          ? _CenterAction(
                              item: items[i],
                              selected: currentIndex == i,
                              onTap: () => onTap(i),
                            )
                          : _NavButton(
                              item: items[i],
                              selected: currentIndex == i,
                              onTap: () => onTap(i),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted2;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 24, color: color),
          const SizedBox(height: AppSpacing.s4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.hint.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// Circle diameter, from DESIGN_TOKENS.md ("raised amber circle (50px)").
  static const double _circleSize = 50;

  /// How far the circle rises above the bar's top edge.
  static const double _lift = 16;

  /// Matches the 24px icon slot of the regular [_NavButton]s so the "Tailor"
  /// label sits on the same baseline as its neighbours.
  static const double _iconSlot = 24;

  @override
  Widget build(BuildContext context) {
    // The circle is a non-layout (Positioned) child that floats above the bar,
    // so the cell only reserves space for the label — exactly like the other
    // items — and the bar keeps its fixed height regardless of circle size.
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: _iconSlot),
              const SizedBox(height: AppSpacing.s4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.hint.copyWith(
                  color: selected ? AppColors.primary : AppColors.muted2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Positioned(
            top: -_lift,
            child: Container(
              width: _circleSize,
              height: _circleSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
                boxShadow: AppShadows.navGlow,
              ),
              child: Icon(item.icon, size: 24, color: AppColors.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}
