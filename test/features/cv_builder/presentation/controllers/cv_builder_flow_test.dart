import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvBuilderFlow page order', () {
    test('follows the design order, with Training kept before Summary', () {
      expect(CvBuilderFlow.pages, [
        CvBuilderPage.personal,
        CvBuilderPage.education,
        CvBuilderPage.experience,
        CvBuilderPage.skills,
        CvBuilderPage.projects,
        CvBuilderPage.training,
        CvBuilderPage.summary,
      ]);
      expect(CvBuilderFlow.total, 7);
    });

    test('next / previous walk the pages and stop at the ends', () {
      expect(CvBuilderFlow.previous(CvBuilderPage.personal), isNull);
      expect(
        CvBuilderFlow.next(CvBuilderPage.personal),
        CvBuilderPage.education,
      );
      expect(
        CvBuilderFlow.previous(CvBuilderPage.summary),
        CvBuilderPage.training,
      );
      expect(CvBuilderFlow.next(CvBuilderPage.summary), isNull);
      expect(CvBuilderFlow.isFirst(CvBuilderPage.personal), isTrue);
      expect(CvBuilderFlow.isLast(CvBuilderPage.summary), isTrue);
      expect(CvBuilderFlow.isLast(CvBuilderPage.training), isFalse);
    });
  });

  group('mapping onto existing builder steps', () {
    test('every existing data step is reachable from some page', () {
      final covered = {for (final page in CvBuilderFlow.pages) ...page.steps};
      for (final step in CvBuilderStep.values) {
        if (step == CvBuilderStep.template || step == CvBuilderStep.preview) {
          continue; // Template + preview now live on the preview screens.
        }
        expect(covered, contains(step), reason: '$step must stay editable');
      }
    });

    test('Skills & languages share one page', () {
      expect(
        CvBuilderPage.skills.steps,
        containsAll([CvBuilderStep.skills, CvBuilderStep.languages]),
      );
      expect(
        CvBuilderFlow.pageFor(CvBuilderStep.languages),
        CvBuilderPage.skills,
      );
    });

    test(
      'pageFor resolves each step; template / preview map to the last page',
      () {
        expect(
          CvBuilderFlow.pageFor(CvBuilderStep.personalInfo),
          CvBuilderPage.personal,
        );
        expect(
          CvBuilderFlow.pageFor(CvBuilderStep.summaryObjective),
          CvBuilderPage.summary,
        );
        expect(
          CvBuilderFlow.pageFor(CvBuilderStep.training),
          CvBuilderPage.training,
        );
        expect(
          CvBuilderFlow.pageFor(CvBuilderStep.template),
          CvBuilderPage.summary,
        );
        expect(
          CvBuilderFlow.pageFor(CvBuilderStep.preview),
          CvBuilderPage.summary,
        );
      },
    );

    test('the entry step of each page maps back to that page', () {
      for (final page in CvBuilderFlow.pages) {
        expect(CvBuilderFlow.pageFor(page.entryStep), page);
      }
    });
  });

  group('progress', () {
    test('percentages round down and reach 100 on the last page', () {
      final percents = [
        for (final page in CvBuilderFlow.pages) CvBuilderFlow.percent(page),
      ];
      expect(percents, [14, 28, 42, 57, 71, 85, 100]);
      expect(CvBuilderFlow.progress(CvBuilderPage.summary), 1.0);
    });
  });

  group('firstError', () {
    test('returns the first failing step on a multi-step page', () {
      final asked = <CvBuilderStep>[];
      final error = CvBuilderFlow.firstError(CvBuilderPage.skills, (step) {
        asked.add(step);
        return step == CvBuilderStep.languages ? 'language problem' : null;
      });

      expect(error, 'language problem');
      expect(asked, [CvBuilderStep.skills, CvBuilderStep.languages]);
    });

    test('stops at the first error and returns null when all pass', () {
      final asked = <CvBuilderStep>[];
      expect(
        CvBuilderFlow.firstError(CvBuilderPage.skills, (step) {
          asked.add(step);
          return 'skills problem';
        }),
        'skills problem',
      );
      expect(asked, [CvBuilderStep.skills], reason: 'does not check further');

      expect(
        CvBuilderFlow.firstError(CvBuilderPage.personal, (_) => null),
        isNull,
      );
    });
  });
}
