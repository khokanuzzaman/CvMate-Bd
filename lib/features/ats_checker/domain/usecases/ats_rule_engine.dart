import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_engine_constants.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_keyword_extractor.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_keyword_matcher.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AtsRuleEngine {
  const AtsRuleEngine();

  static const Map<AtsSuggestionSeverity, int> _severityPenalty = {
    AtsSuggestionSeverity.high: 12,
    AtsSuggestionSeverity.medium: 7,
    AtsSuggestionSeverity.low: 3,
  };

  AtsCheckReport analyzeCv(CvProfile profile) {
    final issues = <AtsCheckIssue>[];
    // A section the user hid is not part of the exported CV, so it is neither
    // read for content nor reported as missing.
    bool shown(CvSectionKind kind) => profile.isSectionVisible(kind);

    if (profile.personalInfo.phone.trim().isEmpty) {
      issues.add(
        const AtsCheckIssue(
          category: AtsCheckCategory.contact,
          severity: AtsSuggestionSeverity.high,
          problem: 'Phone number is missing.',
          suggestion:
              'Add a valid phone number (with country code) so recruiters can contact you quickly.',
          exampleImprovement: 'Example: +8801XXXXXXXXX or +9715XXXXXXXX',
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

    if (shown(CvSectionKind.summary)) {
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
    }

    if (shown(CvSectionKind.objective) &&
        profile.careerObjective.trim().isEmpty) {
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

    if (shown(CvSectionKind.education) && profile.education.isEmpty) {
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

    if (shown(CvSectionKind.skills) && profile.skills.isEmpty) {
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

    final experienceShown = shown(CvSectionKind.experience);
    final projectsShown = shown(CvSectionKind.projects);
    if ((experienceShown || projectsShown) &&
        (!experienceShown || profile.experiences.isEmpty) &&
        (!projectsShown || profile.projects.isEmpty)) {
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

    if (projectsShown &&
        profile.projects.isNotEmpty &&
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

    if (experienceShown &&
        profile.experiences.isNotEmpty &&
        !_hasActionVerbs(profile)) {
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

    if (experienceShown &&
        profile.experiences.isNotEmpty &&
        !_hasMeasurableEvidence(profile)) {
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

    final skillsShown = profile.isSectionVisible(CvSectionKind.skills);
    final skillsMatcher = AtsKeywordMatcher([
      if (skillsShown)
        for (final skill in profile.skills) skill.name,
    ]);
    final externalMatcher = AtsKeywordMatcher(_evidenceDocuments(profile));
    final fullMatcher = AtsKeywordMatcher([
      ..._evidenceDocuments(profile),
      if (skillsShown)
        for (final skill in profile.skills) skill.name,
      profile.personalInfo.desiredRole,
    ]);

    final matchedKeywords = <String>[];
    final missingKeywords = <String>[];
    final suggestedSkillsToAdd = <String>[];

    for (final keyword in extractedKeywords) {
      if (fullMatcher.matches(keyword)) {
        matchedKeywords.add(keyword);
        // Nothing to suggest adding to a skills section that is hidden.
        if (skillsShown &&
            !skillsMatcher.matches(keyword) &&
            externalMatcher.matches(keyword)) {
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
    bool shown(CvSectionKind kind) => profile.isSectionVisible(kind);
    final values = <String>[
      profile.personalInfo.fullName,
      profile.personalInfo.desiredRole,
      profile.personalInfo.address,
      if (shown(CvSectionKind.summary)) profile.professionalSummary,
      if (shown(CvSectionKind.objective)) profile.careerObjective,
      if (shown(CvSectionKind.education))
        for (final education in profile.education) ...[
          education.institution,
          education.degree,
          education.fieldOfStudy,
          education.result,
        ],
      if (shown(CvSectionKind.experience))
        for (final experience in profile.experiences) ...[
          experience.companyName,
          experience.jobTitle,
          experience.location,
          ...experience.highlights,
        ],
      if (shown(CvSectionKind.skills))
        for (final skill in profile.skills) skill.name,
      if (shown(CvSectionKind.projects))
        for (final project in profile.projects) ...[
          project.title,
          project.role,
          project.description,
          ...project.technologies,
        ],
      if (shown(CvSectionKind.training))
        for (final training in profile.trainings) ...[
          training.title,
          training.organization,
          training.details,
        ],
      if (shown(CvSectionKind.languages))
        for (final language in profile.languages) ...[
          language.name,
          language.proficiency,
        ],
      profile.visibleCustomText,
    ];

    return _wordCount(values.join(' '));
  }

  int _countThinSections(CvProfile profile) {
    // Hidden sections are not part of the CV, so they cannot be "thin".
    final sections = <CvSectionKind, bool>{
      CvSectionKind.summary: profile.professionalSummary.trim().isEmpty,
      CvSectionKind.objective: profile.careerObjective.trim().isEmpty,
      CvSectionKind.education: profile.education.isEmpty,
      CvSectionKind.experience: profile.experiences.isEmpty,
      CvSectionKind.skills: profile.skills.isEmpty,
      CvSectionKind.projects: profile.projects.isEmpty,
      CvSectionKind.training: profile.trainings.isEmpty,
      CvSectionKind.languages: profile.languages.isEmpty,
    };
    return sections.entries
        .where((entry) => entry.value && profile.isSectionVisible(entry.key))
        .length;
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

  /// Extracts the real skills and requirements from a pasted job post (see
  /// [AtsKeywordExtractor]): employer, place, date, pay and contact text never
  /// counts, and duties are trimmed to the skill itself.
  List<String> extractJobKeywords(String jobPostText) =>
      const AtsKeywordExtractor().extract(jobPostText);

  List<String> _extractJobKeywords(String jobPostText) =>
      extractJobKeywords(jobPostText);

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

  bool _looksLikeTrainableKeyword(String keyword) {
    return atsTrainableKeywords.contains(keyword.toLowerCase());
  }

  /// Pieces of CV text that can prove a skill (not the skills list itself):
  /// only what is actually on the CV, in its visible built-in sections plus
  /// visible custom ones. Kept as separate pieces so a keyword is never matched
  /// across two unrelated lines.
  List<String> _evidenceDocuments(CvProfile profile) {
    bool shown(CvSectionKind kind) => profile.isSectionVisible(kind);
    return [
      if (shown(CvSectionKind.summary)) profile.professionalSummary,
      if (shown(CvSectionKind.objective)) profile.careerObjective,
      if (shown(CvSectionKind.experience))
        for (final experience in profile.experiences) ...[
          ...experience.highlights,
          experience.jobTitle,
        ],
      if (shown(CvSectionKind.projects))
        for (final project in profile.projects) ...[
          ...project.technologies,
          project.description,
          project.title,
        ],
      if (shown(CvSectionKind.education))
        for (final education in profile.education) ...[
          education.degree,
          education.fieldOfStudy,
        ],
      if (shown(CvSectionKind.training))
        for (final training in profile.trainings) ...[
          training.title,
          training.details,
        ],
      for (final section in profile.visibleSections)
        if (section.custom != null)
          for (final item in section.custom!.filledItems) item.bulletText,
    ];
  }
}
