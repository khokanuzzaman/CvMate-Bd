/// Plain, readable text for any AI action's `content`, used where the result
/// is shown outside its own screen (the "Your last result is ready" card).
abstract final class AiResultText {
  /// Fields that repeat the input or only carry ids.
  static const Set<String> _skippedKeys = {
    'language',
    'originalText',
    'original',
    'experienceId',
    'id',
  };

  static const Map<String, String> _actionLabels = {
    'generateProfessionalSummary': 'Professional summary',
    'generateCareerObjective': 'Career objective',
    'improveExperienceBullet': 'Experience bullet',
    'improveProjectDescription': 'Project description',
    'suggestSkills': 'Skill suggestions',
    'generateCoverLetter': 'Cover letter',
    'generateJobApplicationEmail': 'Job application email',
    'generateLinkedInMessage': 'LinkedIn message',
    'generateInterviewQuestions': 'Interview questions',
    'tailorCvForJob': 'Tailored CV',
    'analyzeJobPost': 'Job post analysis',
    'calculateCvJobMatch': 'CV match',
    'generateAtsSuggestions': 'ATS suggestions',
  };

  static String actionLabel(String action) =>
      _actionLabels[action] ?? 'AI result';

  static String fromContent(Object? content) {
    final lines = <String>[];
    _write(content, lines);
    return lines.join('\n').trim();
  }

  static void _write(Object? value, List<String> lines, {String? bullet}) {
    if (value is String) {
      final text = value.trim();
      if (text.isNotEmpty) {
        lines.add(bullet == null ? text : '$bullet $text');
      }
    } else if (value is num || value is bool) {
      lines.add(bullet == null ? '$value' : '$bullet $value');
    } else if (value is List) {
      for (final item in value) {
        if (item is Map) {
          _write(item, lines);
          lines.add('');
        } else {
          _write(item, lines, bullet: '•');
        }
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        if (_skippedKeys.contains(entry.key)) {
          continue;
        }
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          lines
            ..add('')
            ..add(_heading('${entry.key}'));
        }
        _write(entry.value, lines);
      }
    }
  }

  /// `guidancePoints` -> `Guidance points`.
  static String _heading(String key) {
    final words = key
        .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}')
        .trim();
    return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
  }
}
