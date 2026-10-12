import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

const _jobPost =
    'We are hiring a Frontend Developer to build accessible interfaces with '
    'React and TypeScript.';

CoverLetterDraft _draft() => CoverLetterDraft(
  id: 'draft-1',
  userId: null,
  cvId: 'cv-frontend',
  targetCompany: 'Beta Soft',
  jobTitle: 'UI Engineer',
  jobDetails: _jobPost,
  hiringManagerName: '',
  candidateSummary: 'A summary.',
  outputType: CoverLetterOutputType.formalCoverLetter,
  language: AiOutputLanguage.english,
  tone: AiTone.confident,
  subjectLine: '',
  content: 'Dear Beta Soft,\n\nA saved letter body.',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 2),
);

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  FakeCoverLetterRepository? letters,
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: FakeCvRepository([designCv()]),
    letters: letters,
    surface: const Size(390, 1700),
  );
  unawaited(app.router.push(RouteNames.coverLetterPath));
  await tester.pumpAndSettle();
  return app;
}

/// Fills the form and generates, ending on the letter view.
Future<void> _generate(WidgetTester tester) async {
  final fields = find.byType(TextField);
  // company, job title, job details (the first fields in the form).
  await tester.enterText(fields.at(0), 'Acme');
  await tester.enterText(fields.at(1), 'Frontend Developer');
  await tester.enterText(fields.at(2), _jobPost);
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.coverLetterGenerate));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('setup', () {
    testWidgets('opens on the form when there is no letter yet', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text(AppStrings.coverLetterSetupTitle), findsOneWidget);
      expect(find.text(AppStrings.coverLetterGenerate), findsOneWidget);
      expect(find.text(AppStrings.coverLetterToneProfessional), findsOneWidget);
      expect(find.text(AppStrings.coverLetterAlignedTo('x')), findsNothing);
    });

    testWidgets('Generate needs company, title and job details', (
      tester,
    ) async {
      final app = await _open(tester);

      await _tap(tester, find.text(AppStrings.coverLetterGenerate));

      expect(app.ai.coverLetterCalls, 0);
      expect(find.text('Target company name is required.'), findsOneWidget);
      expect(find.text(AppStrings.coverLetterGenerate), findsOneWidget);
    });

    testWidgets('lists recent drafts, opens one, and deletes one', (
      tester,
    ) async {
      final letters = FakeCoverLetterRepository([_draft()]);
      await _open(tester, letters: letters);

      expect(
        find.text(AppStrings.coverLetterRecentDrafts.toUpperCase()),
        findsOneWidget,
      );

      await _tap(tester, find.byTooltip(AppStrings.coverLetterDeleteDraft));
      await _tap(tester, find.text(AppStrings.coverLetterDelete));
      expect(letters.drafts, isEmpty);
      expect(
        find.text(AppStrings.coverLetterRecentDrafts.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('Open draft shows that draft as the letter', (tester) async {
      await _open(tester, letters: FakeCoverLetterRepository([_draft()]));

      await _tap(tester, find.text(AppStrings.coverLetterOpenDraft));

      expect(find.text('Dear Beta Soft,'), findsOneWidget);
      expect(
        find.text(AppStrings.coverLetterAlignedTo('UI Engineer · Beta Soft')),
        findsOneWidget,
      );
    });
  });

  group('letter', () {
    testWidgets('Generate shows the letter as paper with the tone control', (
      tester,
    ) async {
      final app = await _open(tester);
      await _generate(tester);

      expect(app.ai.coverLetterCalls, 1);
      expect(
        find.text(AppStrings.coverLetterAlignedTo('Frontend Developer · Acme')),
        findsOneWidget,
      );
      expect(find.text('Dear Hiring Manager,'), findsOneWidget);
      expect(
        find.textContaining('[Your name]', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(AppStrings.coverLetterEdit), findsOneWidget);
      expect(find.text(AppStrings.coverLetterRegenerate), findsOneWidget);
      expect(find.text(AppStrings.coverLetterExport), findsOneWidget);
      expect(find.byTooltip(AppStrings.coverLetterShare), findsOneWidget);
    });

    testWidgets('the tone control sets the existing tone option', (
      tester,
    ) async {
      final app = await _open(tester);
      await _generate(tester);
      CoverLetterState state() =>
          app.container.read(coverLetterControllerProvider);
      expect(
        state().tone,
        AiTone.formal,
        reason: 'Professional is the default',
      );

      await _tap(tester, find.text(AppStrings.coverLetterToneFriendly));
      expect(state().tone, AiTone.simple);
      await _tap(tester, find.text(AppStrings.coverLetterToneConfident));
      expect(state().tone, AiTone.confident);
      await _tap(tester, find.text(AppStrings.coverLetterToneProfessional));
      expect(state().tone, AiTone.formal);
    });

    testWidgets('Regenerate writes the letter again in the chosen tone', (
      tester,
    ) async {
      final app = await _open(tester);
      await _generate(tester);

      await _tap(tester, find.text(AppStrings.coverLetterToneConfident));
      expect(
        app.ai.coverLetterCalls,
        1,
        reason: 'picking a tone alone is free',
      );
      await _tap(tester, find.text(AppStrings.coverLetterRegenerate));

      expect(app.ai.coverLetterCalls, 2);
      expect(app.ai.lastCoverLetterTone, AiTone.confident);
      expect(find.textContaining('confident tone'), findsOneWidget);
    });

    testWidgets('Edit makes the letter editable and keeps the changes', (
      tester,
    ) async {
      final app = await _open(tester);
      await _generate(tester);

      await _tap(tester, find.text(AppStrings.coverLetterEdit));
      final body = find.byType(TextField).last;
      await tester.enterText(body, 'My own letter.');
      await tester.pumpAndSettle();
      expect(
        app.container.read(coverLetterControllerProvider).generatedContent,
        'My own letter.',
      );

      await _tap(tester, find.text(AppStrings.coverLetterDoneEditing));
      expect(find.text('My own letter.'), findsOneWidget);
    });

    testWidgets('Export saves the letter as a draft', (tester) async {
      final app = await _open(tester);
      await _generate(tester);
      expect(app.letters.saveCount, 0);

      await tester.tap(find.text(AppStrings.coverLetterExport));
      await tester.pumpAndSettle();

      expect(app.letters.saveCount, 1);
      expect(app.letters.drafts.single.targetCompany, 'Acme');
      expect(app.letters.drafts.single.tone, AiTone.formal);
    });

    testWidgets('the aligned-to chip leads back to the form and back again', (
      tester,
    ) async {
      await _open(tester);
      await _generate(tester);

      await _tap(
        tester,
        find.text(AppStrings.coverLetterAlignedTo('Frontend Developer · Acme')),
      );
      expect(find.text(AppStrings.coverLetterSetupTitle), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget, reason: 'details are kept');

      await _tap(
        tester,
        find.widgetWithText(SecondaryButton, AppStrings.coverLetterViewLetter),
      );
      expect(find.text('Dear Hiring Manager,'), findsOneWidget);
    });

    testWidgets('Back leaves the screen', (tester) async {
      await _open(tester);
      await _generate(tester);

      await _tap(tester, find.byIcon(Icons.chevron_left_rounded));

      expect(find.text(homePlaceholder), findsOneWidget);
    });
  });
}
