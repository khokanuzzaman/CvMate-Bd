import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/overflow_menu_button.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/section_content.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/section_titles.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/section_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reorder, hide, rename and add the sections of the CV being edited. Opened
/// from the builder and from the preview; both share the builder controller's
/// draft, so changes show up there straight away and autosave as usual.
class CvSectionsScreen extends ConsumerWidget {
  const CvSectionsScreen({super.key, this.openedFromBuilder = false});

  /// Whether the builder is underneath. "Edit content" then pops back to it
  /// (on the custom section's page) instead of pushing a second builder.
  final bool openedFromBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvBuilderControllerProvider);
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

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
                title: AppStrings.sectionsTitle,
                onBack: () => Navigator.of(context).maybePop(),
                trailingIcon: Icons.restart_alt_rounded,
                trailingTooltip: AppStrings.sectionsResetOrder,
                onTrailingTap: state.hasActiveDraft
                    ? () => _confirmReset(context, notifier)
                    : null,
              ),
            ),
            Expanded(child: _body(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CvBuilderState state,
    CvBuilderController notifier,
  ) {
    if (state.isLoading && !state.hasActiveDraft) {
      return const CustomLoadingView(message: AppStrings.builderPreparing);
    }
    if (!state.hasActiveDraft) {
      return const CustomErrorView(
        title: AppStrings.builderNoDraftTitle,
        message: AppStrings.builderNoDraftBody,
      );
    }

    final draft = state.draft;
    final sections = draft.resolvedSections;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s22,
      ),
      header: const _Intro(),
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: BuilderAddButton(
          label: AppStrings.sectionsAddCustom,
          onPressed: () => _add(context, notifier),
        ),
      ),
      itemCount: sections.length,
      onReorderItem: notifier.reorderSections,
      itemBuilder: (context, index) {
        final section = sections[index];
        final title = section.titleOr(defaultSectionTitle(section.config.kind));
        return Padding(
          key: ValueKey(section.config.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.s10),
          child: _SectionRow(
            index: index,
            title: title,
            section: section,
            isEmpty: !sectionHasContent(draft, section),
            onVisible: (value) =>
                notifier.setSectionVisible(section.config.id, value),
            onRename: () => _rename(context, notifier, section, title),
            onEditContent: () => _editContent(context, notifier, section),
            onDelete: () => _confirmDelete(context, notifier, section, title),
          ),
        );
      },
    );
  }

  Future<void> _rename(
    BuildContext context,
    CvBuilderController notifier,
    CvSection section,
    String title,
  ) async {
    final result = await showRenameSectionSheet(
      context,
      currentTitle: title,
      canReset:
          section.custom == null && section.config.cleanTitleOverride != null,
    );
    if (result != null) {
      notifier.renameSection(section.config.id, result.title);
    }
  }

  Future<void> _add(BuildContext context, CvBuilderController notifier) async {
    final result = await showAddSectionSheet(context);
    if (result == null || !context.mounted) {
      return;
    }
    final section = notifier.addCustomSection(
      title: result.title,
      layout: result.layout,
    );
    _openCustomPage(context, notifier, section.id);
  }

  void _editContent(
    BuildContext context,
    CvBuilderController notifier,
    CvSection section,
  ) => _openCustomPage(context, notifier, section.config.id);

  void _openCustomPage(
    BuildContext context,
    CvBuilderController notifier,
    String id,
  ) {
    notifier.goToCustomSection(id);
    if (openedFromBuilder) {
      Navigator.of(context).maybePop();
    } else {
      context.push(RouteNames.cvBuilderPath);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CvBuilderController notifier,
    CvSection section,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.sectionsDeleteTitle),
        content: Text(AppStrings.sectionsDeleteBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.sectionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.sectionsDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.deleteCustomSection(section.config.id);
    }
  }

  Future<void> _confirmReset(
    BuildContext context,
    CvBuilderController notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.sectionsResetOrderTitle),
        content: const Text(AppStrings.sectionsResetOrderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.sectionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.sectionsResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.resetSectionLayout();
    }
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.sectionsIntro, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.s6),
          Text(AppStrings.sectionsPersonalNote, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.index,
    required this.title,
    required this.section,
    required this.isEmpty,
    required this.onVisible,
    required this.onRename,
    required this.onEditContent,
    required this.onDelete,
  });

  final int index;
  final String title;
  final CvSection section;
  final bool isEmpty;
  final ValueChanged<bool> onVisible;
  final VoidCallback onRename;
  final VoidCallback onEditContent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visible = section.config.visible;
    final isCustom = section.custom != null;
    final tags = <String>[
      if (isCustom) AppStrings.sectionsCustomTag,
      if (!visible) AppStrings.sectionsHiddenTag,
      if (visible && isEmpty) AppStrings.sectionsEmptyTag,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: '${AppStrings.sectionsDragHandle} $title',
              child: const SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget + AppSpacing.s8,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.muted2,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onRename,
              borderRadius: AppRadii.inputRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget + AppSpacing.s8,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: visible ? AppColors.ink : AppColors.muted2,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Wrap(
                          spacing: AppSpacing.s6,
                          runSpacing: AppSpacing.s4,
                          children: [for (final tag in tags) _Tag(tag)],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: visible ? title : AppStrings.sectionsShow(title),
            toggled: visible,
            child: Switch(value: visible, onChanged: onVisible),
          ),
          OverflowMenuButton(
            tooltip: AppStrings.sectionsMoreOptions,
            items: [
              OverflowMenuItem(
                label: AppStrings.sectionsRename,
                icon: Icons.edit_outlined,
                onSelected: onRename,
              ),
              if (isCustom) ...[
                OverflowMenuItem(
                  label: AppStrings.sectionsEditContent,
                  icon: Icons.list_alt_rounded,
                  onSelected: onEditContent,
                ),
                OverflowMenuItem(
                  label: AppStrings.sectionsDelete,
                  icon: Icons.delete_outline_rounded,
                  onSelected: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}
