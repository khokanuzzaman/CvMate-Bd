/// Static, role-keyword based skill ideas for the "Suggested for this CV" chips.
/// A lightweight local heuristic (no AI call): it matches the CV's target role
/// against a few common families and falls back to general skills.
abstract final class SuggestedSkills {
  static const List<String> _general = [
    'Communication',
    'Teamwork',
    'Problem solving',
    'Time management',
    'MS Office',
  ];

  static const List<_Family> _families = [
    _Family(
      keywords: ['frontend', 'front-end', 'front end', 'web', 'react', 'ui'],
      skills: [
        'React',
        'TypeScript',
        'CSS',
        'HTML',
        'Testing',
        'Accessibility',
        'Git',
      ],
    ),
    _Family(
      keywords: ['flutter', 'mobile', 'android', 'ios', 'app'],
      skills: [
        'Flutter',
        'Dart',
        'Firebase',
        'REST API',
        'State management',
        'Git',
      ],
    ),
    _Family(
      keywords: ['backend', 'back-end', 'back end', 'node', 'java', 'python'],
      skills: ['Node.js', 'SQL', 'REST API', 'Docker', 'Testing', 'Git'],
    ),
    _Family(
      keywords: ['design', 'designer', 'ux', 'graphic'],
      skills: ['Figma', 'Wireframing', 'Prototyping', 'User research'],
    ),
    _Family(
      keywords: ['data', 'analyst', 'analytics', 'bi'],
      skills: ['SQL', 'Excel', 'Power BI', 'Python', 'Data visualization'],
    ),
    _Family(
      keywords: ['account', 'accountant', 'finance', 'audit', 'bookkeeping'],
      skills: ['Excel', 'Accounting', 'QuickBooks', 'Financial reporting'],
    ),
    _Family(
      keywords: ['marketing', 'seo', 'content', 'sales', 'social media'],
      skills: [
        'SEO',
        'Content writing',
        'Social media',
        'Google Analytics',
        'CRM',
      ],
    ),
    _Family(
      keywords: ['hr', 'recruiter', 'admin', 'office', 'customer', 'support'],
      skills: [
        'Communication',
        'MS Office',
        'Customer service',
        'Time management',
      ],
    ),
  ];

  /// Up to [limit] suggestions for [role], skipping anything in [existing]
  /// (case-insensitive).
  static List<String> forRole(
    String role, {
    required Iterable<String> existing,
    int limit = 4,
  }) {
    final lower = role.toLowerCase();
    final tokens = lower
        .split(RegExp(r'[^a-z0-9+#.]+'))
        .where((token) => token.isNotEmpty)
        .toSet();

    final taken = {for (final name in existing) name.trim().toLowerCase()};
    final result = <String>[];

    void addAll(Iterable<String> candidates) {
      for (final candidate in candidates) {
        if (result.length >= limit) {
          return;
        }
        if (taken.add(candidate.toLowerCase())) {
          result.add(candidate);
        }
      }
    }

    for (final family in _families) {
      if (family.matches(lower, tokens)) {
        addAll(family.skills);
      }
    }
    addAll(_general);

    return result;
  }
}

class _Family {
  const _Family({required this.keywords, required this.skills});

  final List<String> keywords;
  final List<String> skills;

  /// Short keywords must match a whole word ("ui" must not match "build");
  /// longer or multi-word keywords match as substrings.
  bool matches(String lowerRole, Set<String> tokens) {
    for (final keyword in keywords) {
      final isShort = keyword.length <= 3 && !keyword.contains(' ');
      if (isShort ? tokens.contains(keyword) : lowerRole.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
