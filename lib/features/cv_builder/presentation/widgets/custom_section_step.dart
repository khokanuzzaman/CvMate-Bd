import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_add_button.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builder page for one user-defined section: its title, layout and items.
/// Follows the same inline-card pattern as the other repeatable sections.
class CustomSectionStep extends ConsumerWidget {
  const CustomSectionStep({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cvBuilderControllerProvider).draft;
    final section = draft.customSectionById(sectionId);
    if (section == null) {
      return const SizedBox.shrink();
    }
    final hidden = draft.sections.any(
      (config) => config.id == sectionId && !config.visible,
    );
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final isRows = section.layout == CustomSectionLayout.titledRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hidden) ...[
          const _HiddenNote(),
          const SizedBox(height: AppSpacing.s14),
        ],
        _TitleField(
          key: ValueKey('title_$sectionId'),
          title: section.title,
          onChanged: (value) => notifier.renameSection(sectionId, value),
        ),
        const SizedBox(height: AppSpacing.s14),
        Text(AppStrings.sectionsLayoutLabel, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.s8),
        SegmentedToggle<CustomSectionLayout>(
          value: section.layout,
          options: const [
            SegmentedOption(
              value: CustomSectionLayout.titledRows,
              label: AppStrings.sectionsLayoutTitledRows,
            ),
            SegmentedOption(
              value: CustomSectionLayout.bullets,
              label: AppStrings.sectionsLayoutBullets,
            ),
          ],
          onChanged: (layout) =>
              notifier.changeCustomSectionLayout(sectionId, layout),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (section.items.isEmpty) ...[
          Text(AppStrings.customSectionEmptyHint, style: AppTextStyles.bodySm),
          const SizedBox(height: AppSpacing.s12),
        ],
        for (var i = 0; i < section.items.length; i++) ...[
          _ItemCard(
            key: ValueKey(section.items[i].id),
            index: i,
            count: section.items.length,
            isRows: isRows,
            item: section.items[i],
            onChanged: (item) =>
                notifier.updateCustomSectionItem(sectionId, item),
            onRemove: () => notifier.removeCustomSectionItem(
              sectionId,
              section.items[i].id,
            ),
            onMove: (delta) =>
                notifier.reorderCustomSectionItems(sectionId, i, i + delta),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        BuilderAddButton(
          label: section.items.isEmpty
              ? AppStrings.customSectionAddFirstRow
              : AppStrings.customSectionAddAnotherRow,
          onPressed: () => notifier.addCustomSectionItem(sectionId),
        ),
      ],
    );
  }
}

class _HiddenNote extends StatelessWidget {
  const _HiddenNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined, color: AppColors.accentInk),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              AppStrings.customSectionHiddenNote,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleField extends StatefulWidget {
  const _TitleField({super.key, required this.title, required this.onChanged});

  final String title;
  final ValueChanged<String> onChanged;

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.title,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: AppStrings.sectionsRenameLabel,
      hintText: AppStrings.sectionsCustomTitleHint,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      // An empty title is ignored by the controller; the last good one stays.
      onChanged: widget.onChanged,
    );
  }
}

class _ItemCard extends StatefulWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.count,
    required this.isRows,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final int count;
  final bool isRows;
  final CustomSectionItem item;
  final ValueChanged<CustomSectionItem> onChanged;
  final VoidCallback onRemove;

  /// -1 = up, 1 = down.
  final ValueChanged<int> onMove;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item.title);
    _description = TextEditingController(text: widget.item.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.index + 1;
    return BuilderItemCard(
      title: widget.isRows
          ? AppStrings.customSectionRowTitle(number)
          : AppStrings.customSectionBulletTitle(number),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _title,
            label: widget.isRows
                ? AppStrings.customSectionRowName
                : AppStrings.customSectionBulletText,
            hintText: widget.isRows
                ? AppStrings.customSectionRowNameHint
                : AppStrings.customSectionBulletHint,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: _description,
            label: widget.isRows
                ? AppStrings.customSectionRowDescription
                : AppStrings.customSectionBulletDetails,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => _emit(),
          ),
          if (widget.count > 1) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: AppStrings.customSectionMoveUp,
                  onPressed: widget.index == 0 ? null : () => widget.onMove(-1),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: AppStrings.customSectionMoveDown,
                  onPressed: widget.index == widget.count - 1
                      ? null
                      : () => widget.onMove(1),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
