/// Converts between the single text boxes the design uses and the separate
/// model fields behind them. Pure Dart; the data models are unchanged.
///
/// Callers only re-parse a box the user actually edited, so untouched data is
/// never rewritten.
abstract final class DateRangeCodec {
  /// Text shown for an open-ended range ("2022 — Now").
  static const String ongoingLabel = 'Now';

  static final RegExp _separator = RegExp(r'\s*[—–]\s*|\s+-\s+');
  static final RegExp _yearHyphenRange = RegExp(
    r'^(\d{4})\s*-\s*(\d{4}|present|now|current)$',
    caseSensitive: false,
  );
  static final RegExp _ongoing = RegExp(
    r'^(now|present|current|ongoing|till date|to date)$',
    caseSensitive: false,
  );

  /// "start — end", or "start — Now" when [ongoing].
  static String format({
    required String start,
    required String end,
    required bool ongoing,
  }) {
    final from = start.trim();
    final to = ongoing ? ongoingLabel : end.trim();

    if (from.isEmpty && to.isEmpty) {
      return '';
    }
    if (to.isEmpty) {
      return from;
    }
    if (from.isEmpty) {
      return '— $to';
    }
    return '$from — $to';
  }

  /// Splits "2018 — 2022", "Jan 2022 - Now", "2018-2022" or "2020" into its
  /// parts. "Now" / "Present" / "Current" mark the range as ongoing.
  static ({String start, String end, bool ongoing}) parse(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return (start: '', end: '', ongoing: false);
    }

    final match = _separator.firstMatch(text);
    if (match != null) {
      return _fromParts(
        text.substring(0, match.start),
        text.substring(match.end),
      );
    }

    final years = _yearHyphenRange.firstMatch(text);
    if (years != null) {
      return _fromParts(years.group(1)!, years.group(2)!);
    }

    return (start: text, end: '', ongoing: false);
  }

  static ({String start, String end, bool ongoing}) _fromParts(
    String start,
    String end,
  ) {
    final from = start.trim();
    final to = end.trim();
    final ongoing = _ongoing.hasMatch(to);
    return (start: from, end: ongoing ? '' : to, ongoing: ongoing);
  }
}

/// One bullet per line: "• Built X" ↔ `['Built X']`.
abstract final class BulletsCodec {
  static const String marker = '• ';

  static final RegExp _leadingMarker = RegExp(r'^\s*(?:[•·▪‣*]|-(?=\s))\s*');

  static String format(List<String> items) {
    return [
      for (final item in items)
        if (item.trim().isNotEmpty) '$marker${item.trim()}',
    ].join('\n');
  }

  static List<String> parse(String text) {
    return [
      for (final line in text.split('\n'))
        if (line.replaceFirst(_leadingMarker, '').trim().isNotEmpty)
          line.replaceFirst(_leadingMarker, '').trim(),
    ];
  }
}

/// Comma separated list: "React, Firebase" ↔ `['React', 'Firebase']`.
abstract final class CommaListCodec {
  static String format(List<String> items) {
    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  static List<String> parse(String text) {
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
