enum AiOutputLanguage { english, bangla }

extension AiOutputLanguageX on AiOutputLanguage {
  String get code => switch (this) {
    AiOutputLanguage.english => 'english',
    AiOutputLanguage.bangla => 'bangla',
  };
}

enum AiTone { professional, formal, simple, confident }

extension AiToneX on AiTone {
  String get code => switch (this) {
    AiTone.professional => 'professional',
    AiTone.formal => 'formal',
    AiTone.simple => 'simple',
    AiTone.confident => 'confident',
  };
}

enum AtsSuggestionSeverity { high, medium, low }

extension AtsSuggestionSeverityX on AtsSuggestionSeverity {
  String get code => switch (this) {
    AtsSuggestionSeverity.high => 'high',
    AtsSuggestionSeverity.medium => 'medium',
    AtsSuggestionSeverity.low => 'low',
  };
}

class AiTextSuggestion {
  const AiTextSuggestion({
    required this.title,
    required this.originalText,
    required this.suggestedText,
    required this.guidancePoints,
    required this.language,
  });

  final String title;
  final String originalText;
  final String suggestedText;
  final List<String> guidancePoints;
  final AiOutputLanguage language;
}

class SkillSuggestion {
  const SkillSuggestion({required this.name, required this.reason});

  final String name;
  final String reason;
}

class AiDocumentDraft {
  const AiDocumentDraft({
    required this.title,
    required this.subjectLine,
    required this.body,
    required this.highlights,
    required this.language,
    required this.tone,
  });

  final String title;
  final String subjectLine;
  final String body;
  final List<String> highlights;
  final AiOutputLanguage language;
  final AiTone tone;
}

class InterviewQuestionItem {
  const InterviewQuestionItem({
    required this.category,
    required this.question,
    required this.whyItMatters,
    required this.answerTip,
    required this.sampleAnswer,
  });

  final String category;
  final String question;
  final String whyItMatters;
  final String answerTip;
  final String sampleAnswer;
}

class InterviewQuestionSet {
  const InterviewQuestionSet({
    required this.title,
    required this.questions,
    required this.language,
  });

  final String title;
  final List<InterviewQuestionItem> questions;
  final AiOutputLanguage language;
}

class AtsSuggestionItem {
  const AtsSuggestionItem({
    required this.title,
    required this.description,
    required this.severity,
  });

  final String title;
  final String description;
  final AtsSuggestionSeverity severity;
}

class AtsSuggestionReport {
  const AtsSuggestionReport({
    required this.headline,
    required this.strengths,
    required this.suggestions,
  });

  final String headline;
  final List<String> strengths;
  final List<AtsSuggestionItem> suggestions;
}

class JobPostAnalysis {
  const JobPostAnalysis({
    required this.roleTitle,
    required this.companyName,
    required this.summary,
    required this.requiredSkills,
    required this.preferredSkills,
    required this.keywords,
  });

  final String roleTitle;
  final String companyName;
  final String summary;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final List<String> keywords;
}

class CvJobMatchResult {
  const CvJobMatchResult({
    required this.matchScore,
    required this.assessment,
    required this.matchedSkills,
    required this.missingSkills,
    required this.suggestedSummary,
    required this.priorityActions,
  });

  final int matchScore;
  final String assessment;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String suggestedSummary;
  final List<String> priorityActions;
}
