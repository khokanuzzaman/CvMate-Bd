import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_engine_constants.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AtsRuleEngine {
  const AtsRuleEngine();

  /// Maximum number of salient keywords extracted from a single job post.
  static const int _maxJobKeywords = 8;

  /// Longest multi-word phrase kept as a single keyword.
  static const int _maxPhraseWords = 4;

  /// Extra weight given to phrases that appear inside a comma/bullet list, since
  /// job posts usually enumerate their real skill requirements that way.
  static const int _enumerationWeight = 3;

  static const Map<AtsSuggestionSeverity, int> _severityPenalty = {
    AtsSuggestionSeverity.high: 12,
    AtsSuggestionSeverity.medium: 7,
    AtsSuggestionSeverity.low: 3,
  };

  AtsCheckReport analyzeCv(CvProfile profile) {
    final issues = <AtsCheckIssue>[];

    if (profile.personalInfo.phone.trim().isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.contact,
          severity: AtsSuggestionSeverity.high,
          problem: 'Phone number is missing.',
          suggestion:
              'Add a valid Bangladesh phone number so recruiters can contact you quickly.',
          exampleImprovement: 'Example: 017XXXXXXXX or +8801XXXXXXXXX',
        ),
      );
    }

    if (profile.personalInfo.email.trim().isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.contact,
          severity: AtsSuggestionSeverity.high,
          problem: 'Email address is missing.',
          suggestion:
              'Add a professional email address for recruiter communication.',
          exampleImprovement: 'Example: firstname.lastname@email.com',
        ),
      );
    }

    final summary = profile.professionalSummary.trim();
    if (summary.isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.summary,
          severity: AtsSuggestionSeverity.high,
          problem: 'Professional summary is missing.',
          suggestion:
              'Add a short ATS-friendly summary that matches your target role and experience level.',
          exampleImprovement:
              'Example: Flutter developer with project-based experience in responsive mobile apps, API integration, and clear documentation.',
        ),
      );
    } else if (_wordCount(summary) < 18) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.summary,
          severity: AtsSuggestionSeverity.medium,
          problem: 'Professional summary looks too short.',
          suggestion:
              'Expand the summary to 2-3 strong lines with your role focus, strengths, and practical proof.',
          exampleImprovement:
              'Mention your target role, tools you use, and the kind of value you can contribute.',
        ),
      );
    }

    if (profile.careerObjective.trim().isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.summary,
          severity: AtsSuggestionSeverity.low,
          problem: 'Career objective is missing.',
          suggestion:
              'Add a short and honest objective, especially if you are a fresher or changing fields.',
          exampleImprovement:
              'Example: Seeking a junior software role where I can apply Flutter skills and continue growing through real product work.',
        ),
      );
    }

    if (profile.education.isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.education,
          severity: AtsSuggestionSeverity.high,
          problem: 'Education section is missing.',
          suggestion:
              'Add your degree, institution, field of study, and graduation year.',
        ),
      );
    }

    if (profile.skills.isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.skills,
          severity: AtsSuggestionSeverity.high,
          problem: 'Skills section is missing.',
          suggestion:
              'List the tools, technologies, and soft skills that are relevant to your target role.',
          exampleImprovement:
              'Example: Flutter, Dart, Firebase, API Integration, Git, Communication',
        ),
      );
    }

    if (profile.experiences.isEmpty && profile.projects.isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.experience,
          severity: AtsSuggestionSeverity.high,
          problem: 'Experience and project sections are both missing.',
          suggestion:
              'Add at least one experience entry or one strong project so the CV shows practical proof of work.',
        ),
      );
    }

    if (profile.projects.isNotEmpty &&
        profile.projects.every(
          (project) => _wordCount(project.description) < 8,
        )) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.projects,
          severity: AtsSuggestionSeverity.medium,
          problem: 'Project descriptions look too short.',
          suggestion:
              'Explain the problem, your role, tools used, and what the project achieved.',
          exampleImprovement:
              'Example: Built a Flutter-based appointment app with Firebase authentication, booking flow, and responsive UI for mobile users.',
        ),
      );
    }

    if (profile.experiences.isNotEmpty && !_hasActionVerbs(profile)) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.experience,
          severity: AtsSuggestionSeverity.medium,
          problem: 'Experience bullets are missing strong action verbs.',
          suggestion:
              'Start bullets with verbs like Developed, Led, Built, Improved, or Coordinated.',
          exampleImprovement:
              'Example: Developed a reporting workflow that reduced manual follow-up time for the team.',
        ),
      );
    }

    if (profile.experiences.isNotEmpty && !_hasMeasurableEvidence(profile)) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.experience,
          severity: AtsSuggestionSeverity.low,
          problem: 'Experience bullets are missing measurable achievements.',
          suggestion:
              'Add numbers, percentages, timelines, or team size when you can do so honestly.',
          exampleImprovement:
              'Example: Supported 200+ customers per month with structured follow-up and issue resolution.',
        ),
      );
    }

    final emptySectionCount = _countThinSections(profile);
    if (emptySectionCount >= 5) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.formatting,
          severity: AtsSuggestionSeverity.low,
          problem: 'Too many sections are still empty or underdeveloped.',
          suggestion:
              'Strengthen the most important sections first: summary, education, skills, and either experience or projects.',
        ),
      );
    }

    final totalWords = _estimateCvWordCount(profile);
    if (totalWords < 120) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.formatting,
          severity: AtsSuggestionSeverity.medium,
          problem: 'CV content looks too short.',
          suggestion:
              'Add more role-relevant detail so recruiters can understand your strengths and practical work quickly.',
        ),
      );
    } else if (totalWords > 800) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.formatting,
          severity: AtsSuggestionSeverity.medium,
          problem: 'CV may be too long for a quick recruiter scan.',
          suggestion:
              'Trim repeated information and keep the strongest role-relevant points easy to scan.',
        ),
      );
    }

    if (profile.personalInfo.linkedInUrl.trim().isEmpty &&
        profile.personalInfo.portfolioUrl.trim().isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.contact,
          severity: AtsSuggestionSeverity.low,
          problem: 'No LinkedIn, GitHub, or portfolio link is listed.',
          suggestion:
              'Add a professional profile or project link if you have one. This is optional but useful for digital and technical roles.',
        ),
      );
    }

    final score = _buildScore(issues);
    return AtsCheckReport(
      score: score,
      issues: issues..sort(_compareIssues),
      categoryScores: _buildCategoryScores(issues),
      wordCount: totalWords,
    );
  }

  AtsJobMatchReport analyzeJobPost({
    required CvProfile profile,
    required String jobPostText,
  }) {
    final extractedKeywords = _extractJobKeywords(jobPostText);
    if (extractedKeywords.isEmpty) {
      return const AtsJobMatchReport(
        matchPercentage: 0,
        extractedKeywords: [],
        matchedKeywords: [],
        missingKeywords: [],
        suggestedSkillsToAdd: [],
        suggestedSectionsToImprove: [],
        issues: [],
      );
    }

    final skillsSectionSet = {
      for (final skill in profile.skills)
        if (skill.name.trim().isNotEmpty) skill.name.trim().toLowerCase(),
    };
    final externalEvidenceText = _externalEvidenceText(profile).toLowerCase();
    final fullEvidenceText = _fullEvidenceText(profile).toLowerCase();

    final matchedKeywords = <String>[];
    final missingKeywords = <String>[];
    final suggestedSkillsToAdd = <String>[];

    for (final keyword in extractedKeywords) {
      final lowerKeyword = keyword.toLowerCase();
      if (_textContainsKeyword(fullEvidenceText, lowerKeyword)) {
        matchedKeywords.add(keyword);
        if (!skillsSectionSet.contains(lowerKeyword) &&
            _textContainsKeyword(externalEvidenceText, lowerKeyword)) {
          suggestedSkillsToAdd.add(keyword);
        }
      } else {
        missingKeywords.add(keyword);
      }
    }

    final matchPercentage =
        ((matchedKeywords.length / extractedKeywords.length) * 100)
            .round()
            .clamp(0, 100);
    final suggestedSectionsToImprove = _buildSuggestedSectionsToImprove(
      profile: profile,
      missingKeywords: missingKeywords,
      suggestedSkillsToAdd: suggestedSkillsToAdd,
    );

    final issues = <AtsCheckIssue>[
      if (matchPercentage < 45)
        const AtsCheckIssue(
          category: AtsCheckCategory.jobMatch,
          severity: AtsSuggestionSeverity.high,
          problem: 'This CV has a low role match against the pasted job post.',
          suggestion:
              'Focus on role-relevant skills, stronger summary wording, and practical evidence that already exists in your background.',
        ),
      if (missingKeywords.isNotEmpty)
        AtsCheckIssue(
          category: AtsCheckCategory.jobMatch,
          severity: missingKeywords.length >= 4
              ? AtsSuggestionSeverity.medium
              : AtsSuggestionSeverity.low,
          problem:
              'Several job-post keywords are missing from the current CV wording.',
          suggestion:
              'Review whether these keywords can be reflected honestly in your summary, skills, projects, or experience: ${missingKeywords.take(6).join(', ')}.',
          exampleImprovement:
              'Only add skills, tools, or achievements that are already true in your real background.',
        ),
      if (suggestedSkillsToAdd.isNotEmpty)
        AtsCheckIssue(
          category: AtsCheckCategory.jobMatch,
          severity: AtsSuggestionSeverity.low,
          problem:
              'Some relevant skills seem to exist in your CV content but are not listed in the skills section.',
          suggestion:
              'You can consider adding these already-supported skills to the skills section: ${suggestedSkillsToAdd.join(', ')}.',
        ),
    ]..sort(_compareIssues);

    return AtsJobMatchReport(
      matchPercentage: matchPercentage,
      extractedKeywords: extractedKeywords,
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      suggestedSkillsToAdd: suggestedSkillsToAdd,
      suggestedSectionsToImprove: suggestedSectionsToImprove,
      issues: issues,
    );
  }

  int _buildScore(List<AtsCheckIssue> issues) {
    var score = 100;
    for (final issue in issues) {
      score -= _severityPenalty[issue.severity] ?? 0;
    }
    return score.clamp(0, 100);
  }

  Map<AtsCheckCategory, int> _buildCategoryScores(List<AtsCheckIssue> issues) {
    final scores = {
      for (final category in AtsCheckCategory.values) category: 100,
    };

    for (final issue in issues) {
      scores[issue.category] =
          (scores[issue.category]! - (_severityPenalty[issue.severity] ?? 0))
              .clamp(0, 100);
    }

    return scores;
  }

  int _compareIssues(AtsCheckIssue a, AtsCheckIssue b) {
    final severityOrder = {
      AtsSuggestionSeverity.high: 0,
      AtsSuggestionSeverity.medium: 1,
      AtsSuggestionSeverity.low: 2,
    };
    final severityDelta = severityOrder[a.severity]!.compareTo(
      severityOrder[b.severity]!,
    );
    if (severityDelta != 0) {
      return severityDelta;
    }

    return a.category.index.compareTo(b.category.index);
  }

  int _wordCount(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  int _estimateCvWordCount(CvProfile profile) {
    final values = <String>[
      profile.personalInfo.fullName,
      profile.personalInfo.desiredRole,
      profile.personalInfo.address,
      profile.professionalSummary,
      profile.careerObjective,
      for (final education in profile.education) ...[
        education.institution,
        education.degree,
        education.fieldOfStudy,
        education.result,
      ],
      for (final experience in profile.experiences) ...[
        experience.companyName,
        experience.jobTitle,
        experience.location,
        ...experience.highlights,
      ],
      for (final skill in profile.skills) skill.name,
      for (final project in profile.projects) ...[
        project.title,
        project.role,
        project.description,
        ...project.technologies,
      ],
      for (final training in profile.trainings) ...[
        training.title,
        training.organization,
        training.details,
      ],
      for (final language in profile.languages) ...[
        language.name,
        language.proficiency,
      ],
    ];

    return _wordCount(values.join(' '));
  }

  int _countThinSections(CvProfile profile) {
    final sections = <bool>[
      profile.professionalSummary.trim().isEmpty,
      profile.careerObjective.trim().isEmpty,
      profile.education.isEmpty,
      profile.experiences.isEmpty,
      profile.skills.isEmpty,
      profile.projects.isEmpty,
      profile.trainings.isEmpty,
      profile.languages.isEmpty,
    ];
    return sections.where((isThin) => isThin).length;
  }

  bool _hasActionVerbs(CvProfile profile) {
    for (final experience in profile.experiences) {
      for (final highlight in experience.highlights) {
        final cleaned = highlight.trim().toLowerCase().replaceAll(
          RegExp(r'^[^a-z]+'),
          '',
        );
        if (cleaned.isEmpty) {
          continue;
        }

        final firstWord = cleaned.split(RegExp(r'\s+')).first;
        if (atsActionVerbs.contains(firstWord)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _hasMeasurableEvidence(CvProfile profile) {
    final numericPattern = RegExp(
      r'(\d+|%|\bpercent\b|\busers\b|\bcustomers\b|\bclients\b|\bmonths\b|\bdays\b)',
      caseSensitive: false,
    );

    for (final experience in profile.experiences) {
      for (final highlight in experience.highlights) {
        if (numericPattern.hasMatch(highlight)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Extracts salient role/skill keywords from a pasted job post.
  ///
  /// This is deterministic and rule-based (no LLM, no fixed profession list), so
  /// it works for any role. It splits the text into candidate phrases on
  /// punctuation and stopwords, favours phrases that appear inside comma/bullet
  /// lists (where job posts enumerate real requirements), normalizes casing,
  /// dedupes, and returns the top keywords by relevance.
  List<String> extractJobKeywords(String jobPostText) {
    if (jobPostText.trim().isEmpty) {
      return const [];
    }

    final scoreByKey = <String, int>{};
    final orderByKey = <String, int>{};
    final displayByKey = <String, String>{};
    var appearanceIndex = 0;

    void register(String phraseKey, String display, int weight, int order) {
      scoreByKey.update(
        phraseKey,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
      orderByKey.putIfAbsent(phraseKey, () => order);
      displayByKey.putIfAbsent(phraseKey, () => display);
    }

    // Break the post into lines on newlines and bullet markers.
    final lines = jobPostText.split(RegExp(r'[\n\r•·▪◦*]+'));
    for (final line in lines) {
      final commaParts = line.split(',');
      final isEnumeration = commaParts.length >= 2;
      final segments = isEnumeration
          ? commaParts
          : line.split(RegExp(r'[.;!?]+'));

      for (final segment in segments) {
        // Break each segment on separators that end a distinct term.
        final subSegments = segment.split(RegExp(r'[:()\[\]|]+'));
        for (final sub in subSegments) {
          for (final phrase in _phrasesFromSegment(sub)) {
            final key = _keywordKey(phrase.lower);
            register(
              key,
              _displayKeyword(phrase.original),
              isEnumeration ? _enumerationWeight : 1,
              appearanceIndex++,
            );
          }
        }
      }
    }

    if (scoreByKey.isEmpty) {
      return const [];
    }

    final keys = scoreByKey.keys.toList()
      ..sort((a, b) {
        final scoreDelta = scoreByKey[b]!.compareTo(scoreByKey[a]!);
        if (scoreDelta != 0) {
          return scoreDelta;
        }
        return orderByKey[a]!.compareTo(orderByKey[b]!);
      });

    return [for (final key in keys.take(_maxJobKeywords)) displayByKey[key]!];
  }

  List<String> _extractJobKeywords(String jobPostText) =>
      extractJobKeywords(jobPostText);

  /// Splits a raw text segment into content-word phrases (runs of non-stopword
  /// tokens), capped at [_maxPhraseWords]. Preserves the original casing so the
  /// display form can keep acronyms intact.
  List<_KeywordPhrase> _phrasesFromSegment(String segment) {
    final tokens = segment
        .split(RegExp(r'[^A-Za-z0-9/.+#]+'))
        // Keep punctuation only when it is internal (node.js, ui/ux); strip
        // sentence dots and stray slashes glued to the token edges.
        .map((token) => token.replaceAll(RegExp(r'^[./]+|[./]+$'), ''))
        .where((token) => token.isNotEmpty)
        .toList();

    final phrases = <_KeywordPhrase>[];
    final run = <String>[];

    void flush() {
      if (run.isEmpty) {
        return;
      }
      if (run.length <= _maxPhraseWords) {
        phrases.add(
          _KeywordPhrase(
            original: run.join(' '),
            lower: run.map((token) => token.toLowerCase()).join(' '),
          ),
        );
      }
      run.clear();
    }

    for (final token in tokens) {
      final lower = token.toLowerCase();
      final isContentWord =
          lower.length >= 2 &&
          !atsStopWords.contains(lower) &&
          !_isNumeric(lower);
      if (isContentWord) {
        run.add(token);
      } else {
        flush();
      }
    }
    flush();

    return phrases;
  }

  bool _isNumeric(String value) => RegExp(r'^[0-9]+$').hasMatch(value);

  /// Normalized dedupe key: collapses known aliases so, e.g., "node js",
  /// "nodejs" and "node.js" map to the same keyword.
  String _keywordKey(String lowerPhrase) {
    final override = atsKeywordDisplayOverrides[lowerPhrase];
    return (override ?? lowerPhrase).toLowerCase();
  }

  List<String> _buildSuggestedSectionsToImprove({
    required CvProfile profile,
    required List<String> missingKeywords,
    required List<String> suggestedSkillsToAdd,
  }) {
    final sections = <String>[];

    if (missingKeywords.isNotEmpty) {
      sections.add('Professional Summary');
    }

    if (missingKeywords.length >= 2 || suggestedSkillsToAdd.isNotEmpty) {
      sections.add('Skills');
    }

    if (profile.experiences.isNotEmpty && missingKeywords.isNotEmpty) {
      sections.add('Experience');
    }

    if (profile.projects.isNotEmpty && missingKeywords.isNotEmpty) {
      sections.add('Projects');
    }

    if (profile.trainings.isNotEmpty &&
        missingKeywords.any(_looksLikeTrainableKeyword)) {
      sections.add('Training / Certifications');
    }

    return sections.take(4).toList();
  }

  String _displayKeyword(String value) {
    final lowerValue = value.toLowerCase();
    final override = atsKeywordDisplayOverrides[lowerValue];
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
  /// (e.g. IV, REST, SQL, HR, ICU, CPR) so they read correctly for any field.
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

  bool _looksLikeTrainableKeyword(String keyword) {
    return atsTrainableKeywords.contains(keyword.toLowerCase());
  }

  String _externalEvidenceText(CvProfile profile) {
    return [
      profile.professionalSummary,
      profile.careerObjective,
      for (final experience in profile.experiences) ...experience.highlights,
      for (final experience in profile.experiences) experience.jobTitle,
      for (final project in profile.projects) ...project.technologies,
      for (final project in profile.projects) project.description,
      for (final project in profile.projects) project.title,
    ].join(' ');
  }

  String _fullEvidenceText(CvProfile profile) {
    return [
      _externalEvidenceText(profile),
      for (final skill in profile.skills) skill.name,
      profile.personalInfo.desiredRole,
    ].join(' ');
  }

  bool _textContainsKeyword(String source, String keyword) {
    final normalizedKeyword = keyword.toLowerCase();
    if (normalizedKeyword.contains(' ')) {
      return source.contains(normalizedKeyword);
    }

    final pattern = RegExp(
      '\\b${RegExp.escape(normalizedKeyword)}\\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(source);
  }
}

/// A candidate keyword phrase carrying both its original casing (for display)
/// and its lowercase form (for scoring, deduping, and matching).
class _KeywordPhrase {
  const _KeywordPhrase({required this.original, required this.lower});

  final String original;
  final String lower;
}
