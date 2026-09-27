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
    this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      field: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: AppTextStyles.bodySm,
        decoration: InputDecoration(hintText: hintText),
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
  const _LabeledField({required this.field, this.label});

  final Widget field;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.s6),
        field,
      ],
    );
  }
}
