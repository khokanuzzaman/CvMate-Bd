import 'dart:typed_data';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/signature_pad.dart';
import 'package:careermatebd/shared/services/image/image_processing.dart';
import 'package:careermatebd/shared/services/image/photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _SignatureMode { draw, upload }

/// The declaration text, place and date, and the signature (drawn or
/// uploaded). Edits apply to the CV as they are made; Save just leaves.
class CvDeclarationScreen extends ConsumerStatefulWidget {
  const CvDeclarationScreen({super.key});

  @override
  ConsumerState<CvDeclarationScreen> createState() =>
      _CvDeclarationScreenState();
}

class _CvDeclarationScreenState extends ConsumerState<CvDeclarationScreen> {
  late final TextEditingController _text;
  late final TextEditingController _place;
  late final TextEditingController _date;
  _SignatureMode _mode = _SignatureMode.draw;
  bool _uploadFailed = false;

  CvBuilderController get _notifier =>
      ref.read(cvBuilderControllerProvider.notifier);

  CvDeclaration get _declaration =>
      ref.read(cvBuilderControllerProvider).draft.declaration;

  @override
  void initState() {
    super.initState();
    final declaration = _declaration;
    _text = TextEditingController(text: declaration.effectiveText);
    _place = TextEditingController(text: declaration.place);
    _date = TextEditingController(text: declaration.date);
  }

  @override
  void dispose() {
    _text.dispose();
    _place.dispose();
    _date.dispose();
    super.dispose();
  }

  void _setLanguage(DeclarationLanguage language) {
    final next = _declaration.withLanguage(language);
    _notifier.updateDeclaration(next);
    _text.text = next.effectiveText;
  }

  Future<void> _upload() async {
    setState(() => _uploadFailed = false);
    try {
      final picked = await ref
          .read(photoPickerProvider)
          .pick(PhotoSource.gallery);
      if (picked == null) {
        return;
      }
      final png = await ImageProcessing.prepareSignatureAsync(picked);
      _notifier.setSignature(png);
    } catch (_) {
      if (mounted) {
        setState(() => _uploadFailed = true);
      }
    }
  }

  Future<void> _save() async {
    await _notifier.flushAutosave();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvBuilderControllerProvider);
    final draft = state.draft;
    final enabled = draft.showDeclaration;

    return Scaffold(
      body: SafeArea(
        child: !state.hasActiveDraft
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
                      title: AppStrings.declarationTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.s8,
                        AppSpacing.screen,
                        AppSpacing.s16,
                      ),
                      children: [
                        _ToggleCard(
                          title: AppStrings.declarationAdd,
                          hint: AppStrings.declarationAddHint,
                          value: enabled,
                          onChanged: (value) => _notifier.setFieldShown(
                            PersonalField.declaration,
                            value,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Opacity(
                          opacity: enabled ? 1 : 0.5,
                          child: IgnorePointer(
                            ignoring: !enabled,
                            child: _declarationFields(draft.declaration),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s22),
                        _signatureSection(
                          draft.signature,
                          draft.signatureToShow != null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: state.hasActiveDraft
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
                      label: AppStrings.declarationSave,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _declarationFields(CvDeclaration declaration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(AppStrings.declarationTextLabel),
        const SizedBox(height: AppSpacing.s8),
        AppTextArea(
          controller: _text,
          minLines: 3,
          maxLines: 6,
          fillColor: AppColors.surface,
          onChanged: (value) =>
              _notifier.updateDeclaration(_declaration.withEditedText(value)),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            _LanguageChip(
              label: AppStrings.declarationEnglish,
              selected: declaration.language == DeclarationLanguage.english,
              onTap: () => _setLanguage(DeclarationLanguage.english),
            ),
            _LanguageChip(
              label: AppStrings.declarationBangla,
              selected: declaration.language == DeclarationLanguage.bangla,
              onTap: () => _setLanguage(DeclarationLanguage.bangla),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _place,
                label: AppStrings.declarationPlace,
                hintText: AppStrings.declarationPlaceHint,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                fillColor: AppColors.surface,
                onChanged: (value) => _notifier.updateDeclaration(
                  _declaration.copyWith(place: value),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppTextField(
                controller: _date,
                label: AppStrings.declarationDate,
                hintText: AppStrings.declarationDateOnExport,
                textInputAction: TextInputAction.done,
                fillColor: AppColors.surface,
                onChanged: (value) => _notifier.updateDeclaration(
                  _declaration.copyWith(date: value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signatureSection(Uint8List? signature, bool shown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel(AppStrings.signatureTitle)),
            SizedBox(
              width: 190,
              child: SegmentedToggle<_SignatureMode>(
                value: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
                options: const [
                  SegmentedOption(
                    value: _SignatureMode.draw,
                    label: AppStrings.signatureDraw,
                  ),
                  SegmentedOption(
                    value: _SignatureMode.upload,
                    label: AppStrings.signatureUpload,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s10),
        if (_mode == _SignatureMode.draw)
          SignaturePad(existing: signature, onChanged: _onDrawn)
        else
          _uploadBox(signature),
        const SizedBox(height: AppSpacing.s8),
        Text(AppStrings.signatureNote, style: AppTextStyles.bodySm),
        if (_uploadFailed) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.photoFailed,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ],
        if (signature != null) ...[
          const SizedBox(height: AppSpacing.s12),
          _ToggleCard(
            title: AppStrings.signatureShow,
            value: shown,
            onChanged: (value) =>
                _notifier.setFieldShown(PersonalField.signature, value),
          ),
        ],
      ],
    );
  }

  void _onDrawn(Uint8List? png) => _notifier.setSignature(png);

  Widget _uploadBox(Uint8List? signature) {
    return DashedBorder(
      color: AppColors.placeholder.withValues(alpha: 0.6),
      radius: AppRadii.card,
      child: Container(
        height: 170,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (signature != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s14),
                  child: Image.memory(signature, fit: BoxFit.contain),
                ),
              ),
            TextButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                signature == null
                    ? AppStrings.signaturePick
                    : AppStrings.signatureReplace,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String title;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.itemTitle),
                if (hint != null) Text(hint!, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Semantics(
            label: title,
            toggled: value,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
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
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: AppRadii.pillRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pillRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadii.pillRadius,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.line,
              ),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
