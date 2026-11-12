import 'package:careermatebd/features/ats_checker/domain/usecases/ats_job_vocabulary.dart';

/// Word-level text helpers for keyword extraction and matching: tokens, a small
/// stemmer (plural/singular, -ing/-ed) and alias groups. Pure Dart.
abstract final class AtsText {
  static final RegExp _token = RegExp(r'[a-z0-9]+(?:\.[a-z0-9]+)*[+#]*');

  /// Lowercase word tokens. Hyphens, slashes and other punctuation separate
  /// words ("full-stack" and "full stack" give the same tokens); dots inside a
  /// word ("node.js") and trailing `+` / `#` ("c++", "c#") stay.
  static List<String> tokens(String text) => [
    for (final match in _token.allMatches(text.toLowerCase())) match.group(0)!,
  ];

  /// A light stem: "signs" -> "sign", "nurses"/"nursing" -> "nurs",
  /// "monitored" -> "monitor", "processes" -> "process". Words with digits,
  /// dots, `+` or `#` and words of three letters or fewer are left alone.
  static String stem(String word) {
    if (word.length <= 3 || RegExp(r'[0-9.+#]').hasMatch(word)) {
      return word;
    }
    var w = word;
    if (w.endsWith('ies') && w.length > 4) {
      w = '${w.substring(0, w.length - 3)}y';
    } else if (w.endsWith('sses')) {
      w = w.substring(0, w.length - 2);
    } else if (w.endsWith('ing') && w.length > 5) {
      w = w.substring(0, w.length - 3);
    } else if (w.endsWith('ed') && w.length > 4) {
      w = w.substring(0, w.length - 2);
    } else if (w.endsWith('es') && w.length > 4) {
      w = w.substring(0, w.length - 2);
    } else if (w.endsWith('s') && !w.endsWith('ss') && w.length > 3) {
      w = w.substring(0, w.length - 1);
    }
    if (w.length > 3 && w.endsWith('e')) {
      w = w.substring(0, w.length - 1);
    }
    return w;
  }

  static List<String> stems(String text) => [
    for (final token in tokens(text)) stem(token),
  ];

  static final Set<String> _leadingVerbStems = {
    for (final verb in atsLeadingVerbs) stem(verb),
  };

  /// Whether [word] is one of the verbs duties start with.
  static bool isLeadingVerb(String word) =>
      _leadingVerbStems.contains(stem(word.toLowerCase()));

  // Alias groups, normalised the same way as everything else.
  static final List<List<List<String>>> _groups = [
    for (final group in atsKeywordAliasGroups)
      [for (final term in group) stems(term)],
  ];

  static final Map<String, int> _groupByPhrase = {
    for (final (index, group) in _groups.indexed)
      for (final form in group) form.join(' '): index,
  };

  /// Every way to say the same thing as [stems] (itself included).
  static List<List<String>> formsOf(List<String> stems) {
    final index = _groupByPhrase[stems.join(' ')];
    return index == null ? [stems] : _groups[index];
  }

  /// A key two keywords share when they are aliases of each other.
  static String canonicalKey(List<String> stems) {
    final index = _groupByPhrase[stems.join(' ')];
    return index == null ? stems.join(' ') : _groups[index].first.join(' ');
  }
}
