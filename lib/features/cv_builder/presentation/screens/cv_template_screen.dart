import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/template_wireframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Template picker opened from the preview. The choice is applied with the
/// existing `selectTemplate` when the user confirms.
class CvTemplateScreen extends ConsumerStatefulWidget {
  const CvTemplateScreen({super.key});

  @override
  ConsumerState<CvTemplateScreen> createState() => _CvTemplateScreenState();
}

class _CvTemplateScreenState extends ConsumerState<CvTemplateScreen> {
  late CvTemplate _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(cvBuilderControllerProvider).draft.template;
  }

  Future<void> _confirm() async {
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    notifier.selectTemplate(_selected);
    await notifier.flushAutosave();
    if (!mounted) {
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: AppTopBar(
                title: AppStrings.templateTitle,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppSpacing.s14;
                    final width = (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final template in CvTemplate.values)
                          SizedBox(
                            width: width,
                            child: _TemplateCard(
                              template: template,
                              selected: template == _selected,
                              onTap: () => setState(() => _selected = template),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
                label: AppStrings.templateUse(_selected.label),
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final CvTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: template.label,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.soft : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        TemplateWireframe(template: template),
                        if (selected)
                          const Positioned(
                            top: AppSpacing.s8,
                            right: AppSpacing.s8,
                            child: _CheckBadge(),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.itemTitle.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s6),
                        const _AtsBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 16,
        color: AppColors.onPrimary,
      ),
    );
  }
}

class _AtsBadge extends StatelessWidget {
  const _AtsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        AppStrings.templateAtsBadge,
        style: AppTextStyles.hint.copyWith(
          color: AppColors.successText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
