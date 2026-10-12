import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages section: name + proficiency rows, with an add / edit sheet.
class LanguagesStep extends ConsumerWidget {
  const LanguagesStep({super.key});

  /// Proficiency values stored on [LanguageInfo].
  static const List<String> levels = [
    'Basic',
    'Conversational',
    'Professional',
    'Fluent',
    'Native',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(cvBuilderControllerProvider).draft.languages;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: SectionLabel(AppStrings.builderLanguagesLabel),
        ),
        if (languages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Column(
              children: [
                for (var i = 0; i < languages.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: AppSpacing.s16,
                      endIndent: AppSpacing.s16,
                    ),
                  _LanguageRow(
                    language: languages[i],
                    onTap: () => _openSheet(
                      context,
                      initial: languages[i],
                      onSave: notifier.updateLanguage,
                      onDelete: () => notifier.removeLanguage(languages[i].id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _openSheet(context, onSave: notifier.addLanguage),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.minTouchTarget),
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              AppStrings.builderAddLanguage,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSheet(
    BuildContext context, {
    LanguageInfo? initial,
    required ValueChanged<LanguageInfo> onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _LanguageSheet(initial: initial, onSave: onSave, onDelete: onDelete),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.onTap});

  final LanguageInfo language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              Expanded(
                child: Text(language.name, style: AppTextStyles.itemTitle),
              ),
              if (language.proficiency.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    language.proficiency,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({this.initial, required this.onSave, this.onDelete});

  final LanguageInfo? initial;
  final ValueChanged<LanguageInfo> onSave;
  final VoidCallback? onDelete;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _proficiency;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    final saved = widget.initial?.proficiency ?? '';
    _proficiency = LanguagesStep.levels.contains(saved)
        ? saved
        : LanguagesStep.levels.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSave(
      (widget.initial ?? LanguageInfo.empty()).copyWith(
        name: _name.text.trim(),
        proficiency: _proficiency,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s20,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? AppStrings.builderEditLanguage
                    : AppStrings.builderAddLanguage,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                controller: _name,
                label: AppStrings.builderLanguageName,
                hintText: AppStrings.builderLanguageNameHint,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: AppStrings.builderLanguageName,
                ),
              ),
              const SizedBox(height: AppSpacing.s14),
              DropdownButtonFormField<String>(
                initialValue: _proficiency,
                decoration: const InputDecoration(
                  labelText: AppStrings.builderProficiency,
                ),
                items: [
                  for (final level in LanguagesStep.levels)
                    DropdownMenuItem<String>(value: level, child: Text(level)),
                ],
                onChanged: (value) {
                  setState(() {
                    _proficiency = value ?? LanguagesStep.levels.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.s20),
              PrimaryButton(
                label: isEditing
                    ? AppStrings.builderUpdateLanguage
                    : AppStrings.builderSaveLanguage,
                onPressed: _save,
              ),
              if (isEditing && widget.onDelete != null)
                TextButton(
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.minTouchTarget),
                    foregroundColor: AppColors.danger,
                  ),
                  child: Text(
                    AppStrings.builderDeleteLanguage,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
