import 'package:careermatebd/features/ats_checker/domain/usecases/ats_text.dart';

/// Decides whether a job-post keyword is covered by CV text. Tolerant of
/// plurals and tenses ("signs" / "sign"), hyphens ("full-stack" / "full stack"),
/// word order and a few words in between ("Registered Nurse" / "registered
/// staff nurse"), and of aliases ("ICU" / "intensive care unit").
///
/// The CV is given as separate *documents* (one per bullet, skill, summary …)
/// so a phrase is never stitched together across unrelated lines.
class AtsKeywordMatcher {
  AtsKeywordMatcher(Iterable<String> documents) {
    for (final document in documents) {
      final stems = AtsText.stems(document);
      if (stems.isNotEmpty) {
        _documents.add(stems);
        _allStems.addAll(stems);
      }
    }
  }

  final List<List<String>> _documents = [];
  final Set<String> _allStems = {};

  /// How many extra words may sit between the words of a multi-word keyword.
  static const int _slack = 2;

  bool matches(String keyword) {
    final stems = AtsText.stems(keyword);
    if (stems.isEmpty) {
      return false;
    }
    return AtsText.formsOf(stems).any(_matchesForm);
  }

  bool _matchesForm(List<String> form) {
    if (form.isEmpty) {
      return false;
    }
    if (form.length == 1) {
      return _allStems.contains(form.first);
    }
    final wanted = form.toSet();
    if (!_allStems.containsAll(wanted)) {
      return false;
    }
    final window = form.length + _slack;
    for (final document in _documents) {
      for (var start = 0; start < document.length; start++) {
        if (!wanted.contains(document[start])) {
          continue;
        }
        final end = start + window < document.length
            ? start + window
            : document.length;
        if (document.sublist(start, end).toSet().containsAll(wanted)) {
          return true;
        }
      }
    }
    return false;
  }
}
