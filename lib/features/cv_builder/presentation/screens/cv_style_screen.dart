import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/core/widgets/text_scale_clamp.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/style_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Where are you applying?": picks the CV's market style and paper size.
/// Reached from the builder top bar, and right after creating a CV
/// ([openBuilderAfter], which then continues to the builder).
class CvStyleScreen extends ConsumerStatefulWidget {
  const CvStyleScreen({super.key, this.openBuilderAfter = false});

  final bool openBuilderAfter;

  @override
  ConsumerState<CvStyleScreen> createState() => _CvStyleScreenState();
}

class _CvStyleScreenState extends ConsumerState<CvStyleScreen> {
  late CvStyle _style;
  late PaperSize _paper;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(cvBuilderControllerProvider).draft;
    _style = draft.style;
    _paper = draft.paperSize;
  }

  void _use() {
    ref
        .read(cvBuilderControllerProvider.notifier)
        .applyStyle(_style, paperSize: _paper);
    if (widget.openBuilderAfter) {
      context.pushReplacement(RouteNames.cvBuilderPath);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDraft = ref.watch(
      cvBuilderControllerProvider.select((state) => state.hasActiveDraft),
    );

    return Scaffold(
      body: SafeArea(
        child: !hasDraft
            ? const CustomErrorView(
                title: AppStrings.builderNoDraftTitle,
                message: AppStrings.builderNoDraftBody,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.s12,
                      AppSpacing.screen,
                      AppSpacing.s4,
                    ),
                    child: AppTopBar(
                      title: AppStrings.styleTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.s8,
                        AppSpacing.screen,
                        AppSpacing.s16,
                      ),
                      children: [
                        Text(AppStrings.styleIntro, style: AppTextStyles.body),
                        const SizedBox(height: AppSpacing.s16),
                        for (final style in CvStyle.values) ...[
                          _StyleCard(
                            style: style,
                            selected: style == _style,
                            onTap: () => setState(() => _style = style),
                          ),
                          const SizedBox(height: AppSpacing.s12),
                        ],
                        const SizedBox(height: AppSpacing.s4),
                        _PaperCard(
                          value: _paper,
                          onChanged: (value) => setState(() => _paper = value),
                        ),
                        const SizedBox(height: AppSpacing.s14),
                        const _TipNote(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: hasDraft
          ? SafeArea(
              // A min-size Column: the slot's loose constraints would stretch
              // the button to the full screen height otherwise.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.s8,
                      AppSpacing.screen,
                      AppSpacing.s16,
                    ),
                    child: PrimaryButton(
                      label: AppStrings.styleUse(styleShortName(_style)),
                      onPressed: _use,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CvStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (tileColor, iconColor, icon) = switch (style) {
      CvStyle.international => (
        selected ? AppColors.primary : AppColors.primarySoft,
        selected ? AppColors.onPrimary : AppColors.primary,
        Icons.public_rounded,
      ),
      CvStyle.gulf => (
        AppColors.accentSoft,
        AppColors.accentInk,
        Icons.home_work_outlined,
      ),
      CvStyle.southAsia => (
        AppColors.primarySoft,
        AppColors.primary,
        Icons.description_outlined,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: styleName(style),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.line,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? AppShadows.soft : null,
            ),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: AppRadii.iconTileRadius,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                styleName(style),
                                style: AppTextStyles.itemTitle,
                              ),
                            ),
                            if (style == CvStyle.international)
                              const _AtsSafePill(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(styleBody(style), style: AppTextStyles.bodySm),
                      ],
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

class _AtsSafePill extends StatelessWidget {
  const _AtsSafePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        AppStrings.styleAtsSafe,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.successText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.value, required this.onChanged});

  final PaperSize value;
  final ValueChanged<PaperSize> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.stylePaperTitle, style: AppTextStyles.itemTitle),
        const SizedBox(height: AppSpacing.s4),
        Text(AppStrings.stylePaperHint, style: AppTextStyles.bodySm),
      ],
    );
    final toggle = SegmentedToggle<PaperSize>(
      value: value,
      onChanged: onChanged,
      options: const [
        SegmentedOption(value: PaperSize.a4, label: AppStrings.paperA4),
        SegmentedOption(value: PaperSize.letter, label: AppStrings.paperLetter),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.line),
      ),
      child: isLargeText(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label,
                const SizedBox(height: AppSpacing.s12),
                toggle,
              ],
            )
          : Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: AppSpacing.s12),
                SizedBox(width: 168, child: toggle),
              ],
            ),
    );
  }
}

class _TipNote extends StatelessWidget {
  const _TipNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.inputRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              AppStrings.styleTip,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
