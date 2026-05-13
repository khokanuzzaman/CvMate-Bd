import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';

class AtsCheckReport {
  const AtsCheckReport({
    required this.score,
    required this.issues,
    required this.categoryScores,
    required this.wordCount,
  });

  final int score;
  final List<AtsCheckIssue> issues;
  final Map<AtsCheckCategory, int> categoryScores;
  final int wordCount;

  List<AtsCheckIssue> issuesFor(AtsCheckCategory category) {
    return issues.where((issue) => issue.category == category).toList();
  }
}
