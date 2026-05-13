import 'dart:convert';

import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AiResponseParser {
  const AiResponseParser();

  AiTextSuggestion parseTextSuggestion(String rawResponse) {
    final map = _decodeMap(rawResponse);
    return AiTextSuggestion(
      title: _readString(map, 'title'),
      originalText: _readString(map, 'originalText'),
      suggestedText: _readString(map, 'suggestedText'),
      guidancePoints: _readStringList(map, 'guidancePoints'),
      language: _parseLanguage(_readString(map, 'language')),
    );
  }

  List<SkillSuggestion> parseSkillSuggestions(String rawResponse) {
    final list = _decodeList(rawResponse);
    return list.map((item) {
      final map = item is Map<String, dynamic>
          ? item
          : throw const AppException(
              'AI response format was invalid.',
              code: 'ai_parse_error',
            );

      return SkillSuggestion(
        name: _readString(map, 'name'),
        reason: _readString(map, 'reason'),
      );
    }).toList();
  }

  AiDocumentDraft parseDocumentDraft(String rawResponse) {
    final map = _decodeMap(rawResponse);
    return AiDocumentDraft(
      title: _readString(map, 'title'),
      subjectLine: _readString(map, 'subjectLine'),
      body: _readString(map, 'body'),
      highlights: _readStringList(map, 'highlights'),
      language: _parseLanguage(_readString(map, 'language')),
      tone: _parseTone(_readString(map, 'tone')),
    );
  }

  InterviewQuestionSet parseInterviewQuestions(String rawResponse) {
    final map = _decodeMap(rawResponse);
    final questions = (map['questions'] as List<dynamic>? ?? const []).map((
      item,
    ) {
      final questionMap = item is Map<String, dynamic>
          ? item
          : throw const AppException(
              'AI interview response format was invalid.',
              code: 'ai_parse_error',
            );

      return InterviewQuestionItem(
        category: _readCategoryCode(
          questionMap,
          fallbackQuestion: _readString(questionMap, 'question'),
        ),
        question: _readString(questionMap, 'question'),
        whyItMatters: _readString(questionMap, 'whyItMatters'),
        answerTip: _readString(questionMap, 'answerTip'),
        sampleAnswer: _readString(questionMap, 'sampleAnswer'),
      );
    }).toList();

    return InterviewQuestionSet(
      title: _readString(map, 'title'),
      questions: questions,
      language: _parseLanguage(_readString(map, 'language')),
    );
  }

  AtsSuggestionReport parseAtsSuggestions(String rawResponse) {
    final map = _decodeMap(rawResponse);
    final suggestions = (map['suggestions'] as List<dynamic>? ?? const []).map((
      item,
    ) {
      final suggestionMap = item is Map<String, dynamic>
          ? item
          : throw const AppException(
              'AI ATS response format was invalid.',
              code: 'ai_parse_error',
            );

      return AtsSuggestionItem(
        title: _readString(suggestionMap, 'title'),
        description: _readString(suggestionMap, 'description'),
        severity: _parseSeverity(_readString(suggestionMap, 'severity')),
      );
    }).toList();

    return AtsSuggestionReport(
      headline: _readString(map, 'headline'),
      strengths: _readStringList(map, 'strengths'),
      suggestions: suggestions,
    );
  }

  JobPostAnalysis parseJobPostAnalysis(String rawResponse) {
    final map = _decodeMap(rawResponse);
    return JobPostAnalysis(
      roleTitle: _readString(map, 'roleTitle'),
      companyName: _readString(map, 'companyName'),
      summary: _readString(map, 'summary'),
      requiredSkills: _readStringList(map, 'requiredSkills'),
      preferredSkills: _readStringList(map, 'preferredSkills'),
      keywords: _readStringList(map, 'keywords'),
    );
  }

  CvJobMatchResult parseCvJobMatch(String rawResponse) {
    final map = _decodeMap(rawResponse);
    return CvJobMatchResult(
      matchScore: _readInt(map, 'matchScore'),
      assessment: _readString(map, 'assessment'),
      matchedSkills: _readStringList(map, 'matchedSkills'),
      missingSkills: _readStringList(map, 'missingSkills'),
      suggestedSummary: _readString(map, 'suggestedSummary'),
      priorityActions: _readStringList(map, 'priorityActions'),
    );
  }

  Map<String, dynamic> _decodeMap(String rawResponse) {
    try {
      final decoded = jsonDecode(rawResponse);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      throw const AppException(
        'AI response could not be parsed.',
        code: 'ai_parse_error',
      );
    }

    throw const AppException(
      'AI response format was invalid.',
      code: 'ai_parse_error',
    );
  }

  List<dynamic> _decodeList(String rawResponse) {
    try {
      final decoded = jsonDecode(rawResponse);
      if (decoded is List<dynamic>) {
        return decoded;
      }
    } catch (_) {
      throw const AppException(
        'AI response could not be parsed.',
        code: 'ai_parse_error',
      );
    }

    throw const AppException(
      'AI response format was invalid.',
      code: 'ai_parse_error',
    );
  }

  String _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) {
      return value;
    }

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  int _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  List<String> _readStringList(Map<String, dynamic> map, String key) {
    return (map[key] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  AiOutputLanguage _parseLanguage(String value) {
    return switch (value.trim().toLowerCase()) {
      'bangla' => AiOutputLanguage.bangla,
      _ => AiOutputLanguage.english,
    };
  }

  AiTone _parseTone(String value) {
    return switch (value.trim().toLowerCase()) {
      'formal' => AiTone.formal,
      'simple' => AiTone.simple,
      'confident' => AiTone.confident,
      _ => AiTone.professional,
    };
  }

  AtsSuggestionSeverity _parseSeverity(String value) {
    return switch (value.trim().toLowerCase()) {
      'high' => AtsSuggestionSeverity.high,
      'medium' => AtsSuggestionSeverity.medium,
      _ => AtsSuggestionSeverity.low,
    };
  }

  String _readCategoryCode(
    Map<String, dynamic> map, {
    required String fallbackQuestion,
  }) {
    final rawValue = _readString(map, 'category').trim().toLowerCase();
    if (rawValue.isNotEmpty) {
      return rawValue;
    }

    final question = fallbackQuestion.toLowerCase();
    if (question.contains('strength') ||
        question.contains('weakness') ||
        question.contains('tell me about yourself') ||
        question.contains('hire you')) {
      return 'hr';
    }
    if (question.contains('project') || question.contains('cv')) {
      return 'cv_based';
    }
    if (question.contains('company') || question.contains('job')) {
      return 'company_based';
    }
    if (question.contains('conflict') ||
        question.contains('team') ||
        question.contains('challenge') ||
        question.contains('deadline')) {
      return 'behavioral';
    }
    if (question.contains('flutter') ||
        question.contains('dart') ||
        question.contains('technical') ||
        question.contains('skill')) {
      return 'technical';
    }
    return 'general';
  }
}
