import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_fix_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_score_band.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtsScoreBand', () {
    test('bands the score at 80 and 60', () {
      expect(AtsScoreBand.forScore(100), AtsScoreBand.strong);
      expect(AtsScoreBand.forScore(80), AtsScoreBand.strong);
      expect(AtsScoreBand.forScore(79), AtsScoreBand.good);
      expect(AtsScoreBand.forScore(60), AtsScoreBand.good);
      expect(AtsScoreBand.forScore(59), AtsScoreBand.needsWork);
      expect(AtsScoreBand.forScore(0), AtsScoreBand.needsWork);
    });

    test('the headline counts the fixes', () {
      expect(AtsScoreBand.good.headline(3), 'Good, with 3 fixes');
      expect(AtsScoreBand.good.headline(1), 'Good, with 1 fix');
      expect(AtsScoreBand.strong.headline(0), 'Strong');
    });

    test('the ring is green unless the CV needs work', () {
      expect(AtsScoreBand.strong.ringColor, AppColors.success);
      expect(AtsScoreBand.good.ringColor, AppColors.success);
      expect(AtsScoreBand.needsWork.ringColor, AppColors.accent);
    });

    test('section scores are green from 80, amber from 60, else red', () {
      expect(atsSectionScoreColor(92), AppColors.successText);
      expect(atsSectionScoreColor(64), AppColors.accentInk);
      expect(atsSectionScoreColor(40), AppColors.danger);
    });
  });

  group('atsFixStep', () {
    test('every category opens a builder step', () {
      expect(atsFixStep(AtsCheckCategory.contact), CvBuilderStep.personalInfo);
      expect(
        atsFixStep(AtsCheckCategory.summary),
        CvBuilderStep.summaryObjective,
      );
      expect(atsFixStep(AtsCheckCategory.education), CvBuilderStep.education);
      expect(atsFixStep(AtsCheckCategory.experience), CvBuilderStep.experience);
      expect(atsFixStep(AtsCheckCategory.skills), CvBuilderStep.skills);
      expect(atsFixStep(AtsCheckCategory.projects), CvBuilderStep.projects);
      expect(atsFixStep(AtsCheckCategory.formatting), CvBuilderStep.experience);
      for (final category in AtsCheckCategory.values) {
        expect(atsFixStep(category), isNotNull);
      }
    });
  });
}
