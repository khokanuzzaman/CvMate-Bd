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
  });

  final int matchPercentage;
  final List<String> extractedKeywords;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> suggestedSkillsToAdd;
  final List<String> suggestedSectionsToImprove;
  final List<AtsCheckIssue> issues;
}
