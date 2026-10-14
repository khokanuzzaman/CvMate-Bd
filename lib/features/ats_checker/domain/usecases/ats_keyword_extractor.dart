import 'package:careermatebd/features/ats_checker/domain/usecases/ats_engine_constants.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_job_vocabulary.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_text.dart';

/// Pulls the real skills and requirements out of a pasted job post, for any
/// profession. Deterministic and offline (no model, no fixed skill list).
///
/// It reads the post as sentences, comma lists and parentheses, weighting what
/// a post emphasises (the job title, comma-listed requirements, repeated
/// terms), and keeps only the skill itself: employer, institution and place
/// names, dates, pay, contact details and filler are dropped, leading verbs
/// ("Provide patient care" -> "Patient Care") and trailing generic words
/// ("ACLS certification" -> "ACLS") are trimmed, and aliases ("ICU" /
/// "intensive care unit") count once.
class AtsKeywordExtractor {
  const AtsKeywordExtractor();

  static const int maxKeywords = 8;

  /// Longest multi-word phrase kept as one keyword.
  static const int _maxPhraseWords = 4;

  // How much a mention counts for.
  static const int _titleWeight = 4;
  static const int _listWeight = 3;
  static const int _proseWeight = 2;

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
  static final RegExp _url = RegExp(r'(?:https?://|www\.)\S+');
  static final RegExp _phone = RegExp(r'\+?\d[\d\s\-().]{7,}\d');
  static final RegExp _money = RegExp(
    r'(?:(?:bdt|tk\.?|taka|usd|aed|sar|qar|inr|rs\.?|[$€£৳₹])\s*\d[\d,.]*'
    r'(?:\s*(?:-|–|to)\s*\d[\d,.]*)?\s*[km]?'
    r'|\d[\d,.]*\s*(?:bdt|tk|taka|usd|aed|sar|qar|inr)\b)',
    caseSensitive: false,
  );
  static const String _month =
      r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?';
  static final List<RegExp> _dates = [
    RegExp(
      r'\b\d{1,2}(?:st|nd|rd|th)?\s+'
      '$_month'
      r',?\s*(?:\d{2,4})?\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b'
      '$_month'
      r'\s+\d{1,2}(?:st|nd|rd|th)?(?:,?\s*\d{4})?\b',
      caseSensitive: false,
    ),
    RegExp(r'\b\d{1,4}[/-]\d{1,2}[/-]\d{1,4}\b'),
  ];
  static final RegExp _places = RegExp(
    '\\b(?:${atsPlacePhrases.map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );
  static final RegExp _dropLabel = RegExp(
    '^\\s*(?:${atsDropLineLabels.map(RegExp.escape).join('|')})\\b[^:]{0,40}:',
    caseSensitive: false,
  );

  static final Set<String> _stopWords = {
    ...atsStopWords,
    ...atsBoilerplateWords,
    ...atsPayWords,
    ...atsDateWords,
    'key',
    'main',
    'core',
    'following',
    'additional',
    'general',
    'various',
    'multiple',
    'related',
    'etc',
    'eg',
    'ie',
  };

  List<String> extract(String jobPostText) {
    if (jobPostText.trim().isEmpty) {
      return const [];
    }

    final scores = <String, int>{};
    final order = <String, int>{};
    final display = <String, String>{};
    var seen = 0;

    void register(List<String> tokens, int weight) {
      final lower = [for (final token in tokens) token.toLowerCase()];
      final override = atsKeywordDisplayOverrides[lower.join(' ')];
      final stems = AtsText.stems(override ?? lower.join(' '));
      if (stems.isEmpty) {
        return;
      }
      final key = AtsText.canonicalKey(stems);
      scores.update(key, (value) => value + weight, ifAbsent: () => weight);
      order.putIfAbsent(key, () => seen++);
      display.putIfAbsent(key, () => _displayKeyword(tokens.join(' ')));
    }

    var firstLine = true;
    for (final rawLine in _clean(jobPostText).split(RegExp(r'[\n\r•·▪◦*]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty || _dropLabel.hasMatch(line)) {
        continue;
      }
      var firstSentence = firstLine;
      firstLine = false;

      for (final sentence in line.split(RegExp(r'[.!?;]+(?=\s|$)'))) {
        _readSentence(sentence, isTitle: firstSentence, register: register);
        firstSentence = false;
      }
    }

    final keys = scores.keys.toList()
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        return byScore != 0 ? byScore : order[a]!.compareTo(order[b]!);
      });
    return [for (final key in keys.take(maxKeywords)) display[key]!];
  }

  /// Contact details, pay, dates and place names out; each leaves a sentence
  /// break behind so the words around it are not glued together.
  String _clean(String text) {
    var value = text
        .replaceAll(RegExp(r'\s+and/or\s+', caseSensitive: false), ' and ')
        .replaceAll(RegExp(r"['’]s\b"), '')
        .replaceAll(RegExp("['’]"), '')
        .replaceAll(_email, ' ; ')
        .replaceAll(_url, ' ; ')
        .replaceAll(_money, ' ; ');
    for (final date in _dates) {
      value = value.replaceAll(date, ' ; ');
    }
    return value.replaceAll(_phone, ' ; ').replaceAll(_places, ' ; ');
  }

  void _readSentence(
    String sentence, {
    required bool isTitle,
    required void Function(List<String> tokens, int weight) register,
  }) {
    // Parenthesised terms ("(ICU)") are terms in their own right.
    var rest = sentence;
    for (final match in RegExp(r'\(([^)]*)\)').allMatches(sentence)) {
      _readList(match.group(1)!, register: register, base: _listWeight);
    }
    rest = rest.replaceAll(RegExp(r'\([^)]*\)'), ' , ');

    // In the title line, what follows a dash or "at" is the employer and the
    // location ("Accountant - BRAC Bank", "Sales Executive at Acme"), not skills.
    if (isTitle) {
      rest = rest.split(RegExp(r'\s(?:at|@)\s', caseSensitive: false)).first;
    }
    var pieces = rest.split(RegExp(r'\s[–—-]\s|\s\|\s'));
    if (isTitle) {
      pieces = pieces.take(1).toList();
    }
    for (final (index, piece) in pieces.indexed) {
      if (_dropLabel.hasMatch(piece)) {
        continue;
      }
      // "Requirements: a, b, c" - the label is not a keyword.
      final parts = piece.split(RegExp(r':\s*'));
      for (final part in parts) {
        _readList(
          part,
          register: register,
          base: isTitle && index == 0 ? _titleWeight : _proseWeight,
        );
      }
    }
  }

  /// A comma list counts more than running prose.
  void _readList(
    String text, {
    required void Function(List<String> tokens, int weight) register,
    required int base,
  }) {
    final items = text.split(',');
    final isList = items.length >= 2;
    for (final item in items) {
      for (final run in _runs(item)) {
        final cleaned = _cleanRun(run, inList: isList);
        if (cleaned != null) {
          register(cleaned, isList && base < _listWeight ? _listWeight : base);
        }
      }
    }
  }

  /// Runs of content words (not stop words, numbers or place names) in [text].
  List<List<String>> _runs(String text) {
    final tokens = text
        .split(RegExp(r'[^A-Za-z0-9/.+#]+'))
        .map((token) => token.replaceAll(RegExp(r'^[./]+|[./]+$'), ''))
        .where((token) => token.isNotEmpty);

    final runs = <List<String>>[];
    var run = <String>[];
    for (final token in tokens) {
      final lower = token.toLowerCase();
      final isContent =
          lower.length >= 2 &&
          !_stopWords.contains(lower) &&
          !atsPlaceWords.contains(lower) &&
          !RegExp(r'^[\d+./%-]+$').hasMatch(lower);
      if (isContent) {
        run.add(token);
      } else if (run.isNotEmpty) {
        runs.add(run);
        run = <String>[];
      }
    }
    if (run.isNotEmpty) {
      runs.add(run);
    }
    return runs;
  }

  /// Trims a run down to the skill, or null when it is not one.
  List<String>? _cleanRun(List<String> run, {required bool inList}) {
    var tokens = [...run];

    // An organisation name ("Square Hospital") is dropped whole; a bare
    // institution word ("hospital experience") is just dropped.
    final hasOrg = tokens.any(
      (t) => atsOrganisationWords.contains(t.toLowerCase()),
    );
    if (hasOrg) {
      final named = tokens.any(
        (t) =>
            !atsOrganisationWords.contains(t.toLowerCase()) &&
            _isCapitalised(t),
      );
      if (named) {
        return null;
      }
      tokens = [
        for (final t in tokens)
          if (!atsOrganisationWords.contains(t.toLowerCase())) t,
      ];
    }

    // Leading filler and duty verbs. "-ing" words only count as verbs in
    // longer phrases ("Monitoring vital signs", not "Marketing Manager").
    while (tokens.length > 1 && _isLeadingNoise(tokens.first, tokens.length)) {
      tokens.removeAt(0);
    }
    while (tokens.length > 1 &&
        atsTrailingGenericWords.contains(tokens.last.toLowerCase())) {
      tokens.removeLast();
    }

    if (tokens.isEmpty || tokens.length > _maxPhraseWords) {
      return null;
    }
    if (tokens.length == 1) {
      final only = tokens.first.toLowerCase();
      if (atsFillerWords.contains(only) ||
          atsTrailingGenericWords.contains(only) ||
          (!inList && AtsText.isLeadingVerb(only))) {
        return null;
      }
    }
    return tokens;
  }

  bool _isLeadingNoise(String token, int runLength) {
    final lower = token.toLowerCase();
    if (atsFillerWords.contains(lower)) {
      return true;
    }
    if (!AtsText.isLeadingVerb(lower)) {
      return false;
    }
    return !lower.endsWith('ing') || runLength >= 3;
  }

  bool _isCapitalised(String token) {
    final first = token.codeUnitAt(0);
    return first >= 0x41 && first <= 0x5A;
  }

  String _displayKeyword(String value) {
    final override = atsKeywordDisplayOverrides[value.toLowerCase()];
    if (override != null) {
      return override;
    }
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map(_displayToken)
        .join(' ');
  }

  /// Title-cases a token, but keeps short all-caps acronyms uppercase
  /// (IV, REST, SQL, HR, ICU, CPR) so they read correctly for any field.
  String _displayToken(String token) {
    final letters = token.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length >= 2 && letters == letters.toUpperCase()) {
      return token.toUpperCase();
    }
    final lower = token.toLowerCase();
    if (lower.isEmpty) {
      return token;
    }
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
