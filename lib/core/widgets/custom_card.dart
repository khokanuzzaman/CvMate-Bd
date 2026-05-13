import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardChild = Padding(padding: padding, child: child);

    return Card(
      child: onTap == null
          ? cardChild
          : InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: cardChild,
            ),
    );
  }
}
