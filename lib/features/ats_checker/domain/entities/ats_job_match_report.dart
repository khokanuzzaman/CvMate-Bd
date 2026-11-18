import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';

class AtsJobMatchReport {
  const AtsJobMatchReport({
    required this.matchPercentage,
    required this.extractedKeywords,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.suggestedSkillsToAdd,
    required this.suggestedSectionsToImprove,
    required this.issues,
    this.keywordMatchSupported = true,
  });

  final int matchPercentage;
  final List<String> extractedKeywords;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> suggestedSkillsToAdd;
  final List<String> suggestedSectionsToImprove;
  final List<AtsCheckIssue> issues;

  /// False when the job post is mostly in a non-Latin script (e.g. Bangla):
  /// the keyword matcher only understands English words, so
  /// [matchPercentage] means nothing and must not be shown.
  final bool keywordMatchSupported;
}
