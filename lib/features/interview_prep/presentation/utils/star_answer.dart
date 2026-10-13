/// One run of a suggested answer: [label] is set for a "Situation:" /
/// "Task:" / "Action:" / "Result:" lead-in, null for plain text.
class AnswerSegment {
  const AnswerSegment({this.label, required this.text});

  final String? label;
  final String text;
}

final RegExp _starLabel = RegExp(
  r'\b(Situation|Task|Action|Result):',
  caseSensitive: false,
);

/// Splits [answer] at its STAR labels so they can be shown in bold. An answer
/// without labels comes back as a single plain segment — nothing is invented
/// or reformatted.
List<AnswerSegment> parseStarAnswer(String answer) {
  final text = answer.trim();
  final matches = _starLabel.allMatches(text).toList();
  if (matches.isEmpty) {
    return text.isEmpty ? const [] : [AnswerSegment(text: text)];
  }

  final segments = <AnswerSegment>[];
  final lead = text.substring(0, matches.first.start).trim();
  if (lead.isNotEmpty) {
    segments.add(AnswerSegment(text: lead));
  }
  for (var i = 0; i < matches.length; i++) {
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    segments.add(
      AnswerSegment(
        label: '${matches[i].group(1)!}:',
        text: text.substring(matches[i].end, end).trim(),
      ),
    );
  }
  return segments;
}

/// Whether [answer] actually follows the STAR structure (at least three of the
/// four labels), so the UI only calls it "STAR" when it is.
bool isStarAnswer(String answer) {
  final found = {
    for (final match in _starLabel.allMatches(answer))
      match.group(1)!.toLowerCase(),
  };
  return found.length >= 3;
}
