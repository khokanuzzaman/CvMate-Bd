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
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String? label;

  /// Optional widget aligned to the end of the label row (e.g. "Forgot?").
  final Widget? labelTrailing;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Runs when an ancestor [Form] validates; renders the themed error state.
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  /// Trailing icon inside the field (e.g. a password show/hide toggle).
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      labelTrailing: labelTrailing,
      field: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: AppTextStyles.bodySm,
        decoration: InputDecoration(hintText: hintText, suffixIcon: suffixIcon),
      ),
    );
  }
}

/// Labeled multi-line input. (DESIGN_TOKENS.md → AppTextArea)
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.minLines = 4,
    this.maxLines = 8,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      field: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        style: AppTextStyles.bodySm,
        decoration: InputDecoration(hintText: hintText),
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
