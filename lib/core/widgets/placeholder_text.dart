import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:flutter/material.dart';

/// Text that renders `[bracketed]` placeholders (e.g. `[add %]`,
/// `[Your name]`) emphasised, so the user can see what still needs their input.
///
/// With [highlight] the placeholder gets an amber pill background (`accentSoft`
/// / `accentInk`); without it the placeholder is just bold.
class PlaceholderText extends StatelessWidget {
  const PlaceholderText(
    this.text, {
    super.key,
    required this.style,
    this.highlight = false,
  });

  final String text;
  final TextStyle style;
  final bool highlight;

  static final RegExp _token = RegExp(r'\[[^\[\]\n]+\]');

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(style: style, children: _spans()));
  }

  List<InlineSpan> _spans() {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _token.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      spans.add(
        highlight
            ? WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: AppRadii.inputRadius,
                  ),
                  child: Text(
                    token,
                    style: style.copyWith(
                      color: AppColors.accentInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : TextSpan(
                text: token,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }
}
