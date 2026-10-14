import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Personal information": the optional details some markets expect, each with
/// its own "Show on CV" switch, the passport safety note, and the link to the
/// declaration and signature screen. Nothing here goes to the AI.
class PersonalDetailsCard extends ConsumerStatefulWidget {
  const PersonalDetailsCard({super.key});

  @override
  ConsumerState<PersonalDetailsCard> createState() =>
      _PersonalDetailsCardState();
}

class _PersonalDetailsCardState extends ConsumerState<PersonalDetailsCard> {
  bool _more = false;

  CvBuilderController get _notifier =>
      ref.read(cvBuilderControllerProvider.notifier);

  PersonalDetails get _details =>
      ref.read(cvBuilderControllerProvider).draft.details;

  void _update(PersonalDetails Function(PersonalDetails current) change) =>
      _notifier.updateDetails(change(_details));

  void _updateRow(DetailRow row) => _update(
    (d) => d.copyWith(
      customRows: [for (final r in d.customRows) r.id == row.id ? row : r],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(cvBuilderControllerProvider).draft;
    final details = draft.details;
    bool shown(PersonalField field) => draft.isFieldShown(field);
    void toggle(PersonalField field, bool value) =>
        _notifier.setFieldShown(field, value);

    final rows = <Widget>[
      _SwitchRow(
        label: AppStrings.personalFieldPhoto,
        value: shown(PersonalField.photo),
        onChanged: (v) => toggle(PersonalField.photo, v),
        child: _StaticValue(
          text: draft.photo == null
              ? AppStrings.personalNotAdded
              : AppStrings.photoPassportTitle,
          muted: draft.photo == null,
        ),
      ),
      _fieldRow(
        PersonalField.dateOfBirth,
        AppStrings.personalFieldDob,
        shown,
        toggle,
        _InlineField(
          initial: details.dateOfBirth,
          hint: AppStrings.personalDobHint,
          onChanged: (v) => _update((d) => d.copyWith(dateOfBirth: v)),
        ),
      ),
      _fieldRow(
        PersonalField.nationality,
        AppStrings.personalFieldNationality,
        shown,
        toggle,
        _InlineField(
          initial: details.nationality,
          hint: AppStrings.personalNationalityHint,
          capitalization: TextCapitalization.words,
          onChanged: (v) => _update((d) => d.copyWith(nationality: v)),
        ),
      ),
      _fieldRow(
        PersonalField.passport,
        AppStrings.personalFieldPassport,
        shown,
        toggle,
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _InlineField(
                initial: details.passportNumber,
                hint: AppStrings.personalPassportNumberHint,
                capitalization: TextCapitalization.characters,
                onChanged: (v) => _update((d) => d.copyWith(passportNumber: v)),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              flex: 2,
              child: _InlineField(
                initial: details.passportExpiry,
                hint: AppStrings.personalPassportExpiryHint,
                onChanged: (v) => _update((d) => d.copyWith(passportExpiry: v)),
              ),
            ),
          ],
        ),
      ),
      _fieldRow(
        PersonalField.visaStatus,
        AppStrings.personalFieldVisa,
        shown,
        toggle,
        _InlineField(
          initial: details.visaStatus,
          hint: AppStrings.personalVisaHint,
          onChanged: (v) => _update((d) => d.copyWith(visaStatus: v)),
        ),
      ),
      _fieldRow(
        PersonalField.drivingLicence,
        AppStrings.personalFieldLicence,
        shown,
        toggle,
        _InlineField(
          initial: details.drivingLicence,
          hint: AppStrings.personalLicenceHint,
          onChanged: (v) => _update((d) => d.copyWith(drivingLicence: v)),
        ),
      ),
      _fieldRow(
        PersonalField.maritalStatus,
        AppStrings.personalFieldMarital,
        shown,
        toggle,
        _InlineField(
          initial: details.maritalStatus,
          hint: AppStrings.personalMaritalHint,
          onChanged: (v) => _update((d) => d.copyWith(maritalStatus: v)),
        ),
      ),
      if (_more) ...[
        _fieldRow(
          PersonalField.religion,
          AppStrings.personalFieldReligion,
          shown,
          toggle,
          _InlineField(
            initial: details.religion,
            hint: AppStrings.personalReligionHint,
            onChanged: (v) => _update((d) => d.copyWith(religion: v)),
          ),
        ),
        _fieldRow(
          PersonalField.gender,
          AppStrings.personalFieldGender,
          shown,
          toggle,
          _InlineField(
            initial: details.gender,
            hint: AppStrings.personalGenderHint,
            onChanged: (v) => _update((d) => d.copyWith(gender: v)),
          ),
        ),
        for (final row in details.customRows)
          _CustomRowTile(
            key: ValueKey(row.id),
            row: row,
            onChanged: _updateRow,
            onRemove: () => _update(
              (d) => d.copyWith(
                customRows: [
                  for (final r in d.customRows)
                    if (r.id != row.id) r,
                ],
              ),
            ),
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.personalInfoHeader.toUpperCase(),
                style: AppTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(AppStrings.personalShowOnCv, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                row,
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        TextButton.icon(
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          ),
          onPressed: () => setState(() => _more = !_more),
          icon: Icon(_more ? Icons.remove_rounded : Icons.add_rounded),
          label: Text(
            _more
                ? AppStrings.personalFewerFields
                : AppStrings.personalMoreFields,
            textAlign: TextAlign.start,
          ),
        ),
        if (_more)
          TextButton.icon(
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
            ),
            onPressed: () => _update(
              (d) =>
                  d.copyWith(customRows: [...d.customRows, DetailRow.empty()]),
            ),
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text(AppStrings.personalAddRow),
          ),
        const SizedBox(height: AppSpacing.s6),
        const _PrivacyNote(),
        const SizedBox(height: AppSpacing.s16),
        _DeclarationTile(draft: draft),
      ],
    );
  }

  Widget _fieldRow(
    PersonalField field,
    String label,
    bool Function(PersonalField) shown,
    void Function(PersonalField, bool) toggle,
    Widget child,
  ) {
    return _SwitchRow(
      label: label,
      value: shown(field),
      onChanged: (value) => toggle(field, value),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s10,
        AppSpacing.s8,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                child,
              ],
            ),
          ),
          Semantics(
            label: '${AppStrings.personalShowOnCv}: $label',
            toggled: value,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _StaticValue extends StatelessWidget {
  const _StaticValue({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Text(
        text,
        style: AppTextStyles.itemTitle.copyWith(
          color: muted ? AppColors.placeholder : AppColors.ink,
        ),
      ),
    );
  }
}

/// An unframed text field that sits inside a row ("Not added" until filled).
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.initial,
    required this.hint,
    required this.onChanged,
    this.capitalization = TextCapitalization.none,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      textCapitalization: capitalization,
      style: AppTextStyles.itemTitle,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
        hintText: hint,
        hintStyle: AppTextStyles.itemTitle.copyWith(
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}

class _CustomRowTile extends StatelessWidget {
  const _CustomRowTile({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final DetailRow row;
  final ValueChanged<DetailRow> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineField(
                  initial: row.label,
                  hint: AppStrings.personalRowLabelHint,
                  capitalization: TextCapitalization.sentences,
                  onChanged: (v) => onChanged(row.copyWith(label: v)),
                ),
                _InlineField(
                  initial: row.value,
                  hint: AppStrings.personalRowValueHint,
                  onChanged: (v) => onChanged(row.copyWith(value: v)),
                ),
              ],
            ),
          ),
          Semantics(
            label: '${AppStrings.personalShowOnCv}: ${row.label}',
            toggled: row.visible,
            child: Switch(
              value: row.visible,
              onChanged: (v) => onChanged(row.copyWith(visible: v)),
            ),
          ),
          IconButton(
            tooltip: AppStrings.personalRemoveRow,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: AppColors.muted2),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: AppColors.accentSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentInk),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              AppStrings.personalPrivacyNote,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclarationTile extends StatelessWidget {
  const _DeclarationTile({required this.draft});

  final CvProfile draft;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.cardRadius,
      child: InkWell(
        onTap: () => context.push(RouteNames.cvDeclarationPath),
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.declarationTile,
                      style: AppTextStyles.itemTitle,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      AppStrings.declarationTileHint,
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted2),
            ],
          ),
        ),
      ),
    );
  }
}
