import 'package:flutter/material.dart';

enum CustomButtonVariant { primary, secondary, text }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
    this.variant = CustomButtonVariant.primary,
  });

  const CustomButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
  }) : variant = CustomButtonVariant.secondary;

  const CustomButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
  }) : variant = CustomButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final CustomButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = switch (variant) {
      CustomButtonVariant.primary =>
        icon == null
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
      CustomButtonVariant.secondary =>
        icon == null
            ? OutlinedButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
      CustomButtonVariant.text =>
        icon == null
            ? TextButton(onPressed: onPressed, child: Text(label))
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
    };

    if (!isExpanded) {
      return child;
    }

    return SizedBox(width: double.infinity, child: child);
  }
}
