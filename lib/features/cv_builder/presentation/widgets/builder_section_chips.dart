import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/builder_pages.dart';
import 'package:flutter/material.dart';

/// Horizontally scrollable section chips; the current page is a filled
/// `primary` pill and is scrolled into view when it changes. Each chip has a
/// 48dp-high tap area around its 36dp pill.
class BuilderSectionChips extends StatefulWidget {
  const BuilderSectionChips({
    super.key,
    required this.profile,
    required this.pages,
    required this.current,
    required this.onSelected,
  });

  final CvProfile profile;
  final List<BuilderPageRef> pages;
  final BuilderPageRef current;
  final ValueChanged<BuilderPageRef> onSelected;

  @override
  State<BuilderSectionChips> createState() => _BuilderSectionChipsState();
}

class _BuilderSectionChipsState extends State<BuilderSectionChips> {
  final Map<BuilderPageRef, GlobalKey> _keys = {};

  GlobalKey _keyFor(BuilderPageRef page) =>
      _keys.putIfAbsent(page, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _scheduleReveal(animate: false);
  }

  @override
  void didUpdateWidget(BuilderSectionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _scheduleReveal(animate: true);
    }
  }

  void _scheduleReveal({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[widget.current]?.currentContext;
      if (context == null || !context.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: [
          for (final page in widget.pages)
            Padding(
              key: _keyFor(page),
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: _Chip(
                label: CvBuilderPages.chipLabel(widget.profile, page),
                selected: page == widget.current,
                onTap: () => widget.onSelected(page),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: AppRadii.pillRadius,
                border: selected ? null : Border.all(color: AppColors.line),
              ),
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.muted2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
