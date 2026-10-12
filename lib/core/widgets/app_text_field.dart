import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Labeled single-line input. Field styling (fill, border, radius 12,
/// placeholder) comes from the theme's `inputDecorationTheme`.
/// (DESIGN_TOKENS.md → AppTextField)
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.labelTrailing,
    this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.fillColor,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'A controller and an initialValue cannot be used together.',
       );

  final String? label;

  /// Optional widget aligned to the end of the label row (e.g. "Forgot?").
  final Widget? labelTrailing;
  final String? hintText;
  final TextEditingController? controller;

  /// Initial text for an uncontrolled field (mutually exclusive with
  /// [controller]).
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  /// Runs when an ancestor [Form] validates; renders the themed error state.
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;

  /// Trailing icon inside the field (e.g. a password show/hide toggle).
  final Widget? suffixIcon;

  /// Overrides the theme's field fill (e.g. white for fields that sit directly
  /// on the page ground instead of inside a card).
  final Color? fillColor;

  /// Takes focus (and scrolls into view) when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      labelTrailing: labelTrailing,
      field: TextFormField(
        controller: controller,
        initialValue: initialValue,
        autofocus: autofocus,
        onChanged: onChanged,
        validator: validator,
        autovalidateMode: autovalidateMode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        style: AppTextStyles.bodySm,
        decoration: InputDecoration(
          hintText: hintText,
          suffixIcon: suffixIcon,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

/// Labeled multi-line input. (DESIGN_TOKENS.md → AppTextArea)
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.label,
    this.labelTrailing,
    this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines = 4,
    this.maxLines = 8,
    this.fillColor,
  }) : assert(
         controller == null || initialValue == null,
         'A controller and an initialValue cannot be used together.',
       );

  final String? label;

  /// Optional widget aligned to the end of the label row (e.g. an AI action).
  final Widget? labelTrailing;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final int minLines;
  final int maxLines;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      labelTrailing: labelTrailing,
      field: TextFormField(
        controller: controller,
        initialValue: initialValue,
        onChanged: onChanged,
        validator: validator,
        autovalidateMode: autovalidateMode,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        textCapitalization: textCapitalization,
        textAlignVertical: TextAlignVertical.top,
        style: AppTextStyles.bodySm,
        decoration: InputDecoration(hintText: hintText, fillColor: fillColor),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.field, this.label, this.labelTrailing});

  final Widget field;
  final String? label;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return field;
    }

    final labelText = Text(label!, style: AppTextStyles.fieldLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelTrailing == null)
          labelText
        else
          Row(
            children: [
              Expanded(child: labelText),
              labelTrailing!,
            ],
          ),
        const SizedBox(height: AppSpacing.s6),
        field,
      ],
    );
  }
}
