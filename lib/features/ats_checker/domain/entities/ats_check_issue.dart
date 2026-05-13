import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AtsCheckIssue {
  const AtsCheckIssue({
    required this.category,
    required this.severity,
    required this.problem,
    required this.suggestion,
    this.exampleImprovement,
  });

  final AtsCheckCategory category;
  final AtsSuggestionSeverity severity;
  final String problem;
  final String suggestion;
  final String? exampleImprovement;
}
