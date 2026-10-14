import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:flutter/material.dart';

/// What the rename sheet resolved to. [title] null means "reset to default".
class RenameResult {
  const RenameResult(this.title);
  final String? title;
}

/// Rename sheet for a section. Built-in sections can be reset to their default
/// title ([canReset]); a custom section always needs a title.
Future<RenameResult?> showRenameSectionSheet(
  BuildContext context, {
  required String currentTitle,
  required bool canReset,
}) {
  return _showSheet<RenameResult>(
    context,
    (_) => _RenameSheet(currentTitle: currentTitle, canReset: canReset),
  );
}

/// What the add-section sheet resolved to.
class NewSectionResult {
  const NewSectionResult({required this.title, required this.layout});
  final String title;
  final CustomSectionLayout layout;
}

Future<NewSectionResult?> showAddSectionSheet(BuildContext context) {
  return _showSheet<NewSectionResult>(context, (_) => const _AddSheet());
}

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: builder,
  );
}

/// Shared frame: scrolls, and rises above the keyboard.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s14),
          ...children,
        ],
      ),
    );
  }
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.currentTitle, required this.canReset});

  final String currentTitle;
  final bool canReset;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentTitle,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = AppStrings.sectionsTitleRequired);
      return;
    }
    Navigator.of(context).pop(RenameResult(value));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: AppStrings.sectionsRenameTitle,
      children: [
        AppTextField(
          controller: _controller,
          label: AppStrings.sectionsRenameLabel,
          hintText: AppStrings.sectionsRenameHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onChanged: (_) {
            if (_error != null) {
              setState(() => _error = null);
            }
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            _error!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        PrimaryButton(label: AppStrings.sectionsSave, onPressed: _save),
        if (widget.canReset)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const RenameResult(null)),
            child: const Text(AppStrings.sectionsResetToDefault),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.sectionsCancel),
        ),
      ],
    );
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final TextEditingController _controller = TextEditingController();
  CustomSectionLayout _layout = CustomSectionLayout.titledRows;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _create() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = AppStrings.sectionsTitleRequired);
      return;
    }
    Navigator.of(context).pop(NewSectionResult(title: value, layout: _layout));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: AppStrings.sectionsAddCustomTitle,
      children: [
        AppTextField(
          controller: _controller,
          label: AppStrings.sectionsCustomTitleLabel,
          hintText: AppStrings.sectionsCustomTitleHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onChanged: (_) {
            if (_error != null) {
              setState(() => _error = null);
            }
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            _error!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        Text(AppStrings.sectionsLayoutLabel, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.s8),
        _LayoutChoice(
          title: AppStrings.sectionsLayoutTitledRows,
          hint: AppStrings.sectionsLayoutTitledRowsHint,
          selected: _layout == CustomSectionLayout.titledRows,
          onTap: () => setState(() => _layout = CustomSectionLayout.titledRows),
        ),
        const SizedBox(height: AppSpacing.s8),
        _LayoutChoice(
          title: AppStrings.sectionsLayoutBullets,
          hint: AppStrings.sectionsLayoutBulletsHint,
          selected: _layout == CustomSectionLayout.bullets,
          onTap: () => setState(() => _layout = CustomSectionLayout.bullets),
        ),
        const SizedBox(height: AppSpacing.s16),
        PrimaryButton(label: AppStrings.sectionsCreate, onPressed: _create),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.sectionsCancel),
        ),
      ],
    );
  }
}

class _LayoutChoice extends StatelessWidget {
  const _LayoutChoice({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $hint',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.inputRadius,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.muted2,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(hint, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
