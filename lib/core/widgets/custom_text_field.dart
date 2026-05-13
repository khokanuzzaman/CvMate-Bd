import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.autovalidateMode,
    this.readOnly = false,
    this.obscureText = false,
    this.scrollPadding = const EdgeInsets.only(bottom: 140),
  }) : assert(
         controller == null || initialValue == null,
         'A controller and an initialValue cannot be used together.',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final AutovalidateMode? autovalidateMode;
  final bool readOnly;
  final bool obscureText;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (minLines ?? 1) > 1 || maxLines > 1;

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      autovalidateMode: autovalidateMode,
      readOnly: readOnly,
      obscureText: obscureText,
      scrollPadding: scrollPadding,
      textAlignVertical: isMultiline ? TextAlignVertical.top : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        alignLabelWithHint: isMultiline,
      ),
    );
  }
}
