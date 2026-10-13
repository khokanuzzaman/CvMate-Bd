import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/features/interview_prep/presentation/screens/interview_prep_screen.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart'
    show aiCareerServiceProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/clipboard_mock.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_ai_career_service.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/fake_interview_session_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

const _tall = Size(390, 2200);

class _App {
  _App(this.screen, this.ai, this.sessions);

  final RoutedScreen screen;
  final FakeAiCareerService ai;
  final FakeInterviewSessionRepository sessions;

  InterviewPrepState get state =>
      screen.container.read(interviewPrepControllerProvider);
}

Future<_App> _open(
  WidgetTester tester, {
  FakeCvRepository? cvs,
  FakeInterviewSessionRepository? sessions,
}) async {
  final ai = FakeAiCareerService();
  final store = sessions ?? FakeInterviewSessionRepository();
  final screen = await pumpRoutedScreen(
    tester,
    path: RouteNames.interviewPrepPath,
    screen: const InterviewPrepScreen(),
    surface: _tall,
    overrides: [
      cvRepositoryProvider.overrideWithValue(
        cvs ?? FakeCvRepository([designCv()]),
      ),
      aiCareerServiceProvider.overrideWithValue(ai),
      interviewPrepSessionRepositoryProvider.overrideWithValue(store),
    ],
  );
  return _App(screen, ai, store);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The chip rows scroll sideways; bring [label]'s chip into view, then tap it.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(AppChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await _tap(tester, chip);
}

Future<_App> _generated(WidgetTester tester) async {
  final app = await _open(tester);
  await _tap(tester, find.text(AppStrings.interviewGenerate));
  return app;
}

AppChipVariant _variant(WidgetTester tester, String label) =>
    tester.widget<AppChip>(find.widgetWithText(AppChip, label)).variant;

void main() {
  group('setup (no questions yet)', () {
    testWidgets('shows the CV, the fields and the options', (tester) async {
      await _open(tester);

      expect(find.text('Frontend Developer CV'), findsOneWidget);
      expect(find.text(AppStrings.interviewRoleLabel), findsOneWidget);
      expect(find.text('Technical Interview'), findsOneWidget);
      expect(find.text(AppStrings.interviewBangla), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      expect(
        find.text(AppStrings.interviewQuickPractice.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(AppStrings.interviewGenerate), findsOneWidget);
    });

    testWidgets('the CV\'s desired role fills the target role', (tester) async {
      await _open(tester);

      expect(find.text('Frontend Developer'), findsOneWidget);
    });

    testWidgets('the options update the controller', (tester) async {
      final app = await _open(tester);

      await _tap(tester, find.text('Technical Interview'));
      await _tap(tester, find.text(AppStrings.interviewBangla));
      await _tap(tester, find.text('Detailed'));

      final state = app.state;
      expect(state.interviewType, InterviewType.technicalInterview);
      expect(state.language, AiOutputLanguage.bangla);
      expect(state.answerStyle, InterviewAnswerStyle.detailed);
      expect(_variant(tester, 'Detailed'), AppChipVariant.selected);
    });

    testWidgets('"Continue without a CV" clears the selection', (tester) async {
      final app = await _open(tester);

      await _tap(tester, find.text(AppStrings.interviewWithoutCv));

      expect(app.state.selectedCvId, isNull);
      expect(find.text(AppStrings.interviewNoCvSelected), findsOneWidget);
    });

    testWidgets('quick practice copies a question', (tester) async {
      final copied = mockClipboard(tester);
      await _open(tester);

      await _tap(
        tester,
        find.byTooltip(AppStrings.interviewCopyQuestion).first,
      );
      // The snackbar is shown once the clipboard call has returned.
      await tester.pump();
      await tester.pumpAndSettle();

      expect(copied, ['Tell me about yourself.']);
      expect(find.text(AppStrings.interviewQuestionCopied), findsOneWidget);
    });

    testWidgets('with no saved CV it can still practice from a role', (
      tester,
    ) async {
      final app = await _open(tester, cvs: FakeCvRepository());

      expect(find.text(AppStrings.interviewNoCvTitle), findsOneWidget);
      expect(find.text(AppStrings.interviewCreateCv), findsOneWidget);
      // Nothing to generate from yet: the button is disabled.
      PrimaryButton generate() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, AppStrings.interviewGenerate),
      );
      expect(generate().onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Nurse');
      await tester.pumpAndSettle();
      expect(generate().onPressed, isNotNull);
      await _tap(tester, find.text(AppStrings.interviewGenerate));

      expect(app.ai.interviewCalls, 1);
      expect(find.text('All 3'), findsOneWidget);
    });

    testWidgets('a saved session reopens from "Recent sessions"', (
      tester,
    ) async {
      final now = DateTime.now();
      final app = await _open(
        tester,
        sessions: FakeInterviewSessionRepository([
          InterviewPrepSession(
            id: 's1',
            cvId: 'cv-frontend',
            targetJobTitle: 'Designer',
            companyName: 'Beta Soft',
            jobPost: '',
            interviewType: InterviewType.hrInterview,
            language: AiOutputLanguage.english,
            answerStyle: InterviewAnswerStyle.professional,
            generatedQuestions: const [],
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );

      expect(find.text('Designer'), findsOneWidget);
      await _tap(tester, find.text('Designer'));

      expect(app.state.activeSessionId, 's1');
    });
  });

  group('questions', () {
    testWidgets('show the context, the filters and the first card open', (
      tester,
    ) async {
      await _generated(tester);

      expect(find.text('From your CV · Frontend Developer'), findsOneWidget);
      expect(find.text('All 3'), findsOneWidget);
      // Filters follow the order questions appear in.
      final x = [
        for (final label in ['Technical', 'Behavioral', 'HR'])
          tester.getTopLeft(find.widgetWithText(AppChip, label)).dx,
      ];
      expect(x, orderedEquals([...x]..sort()));

      expect(find.text('TECHNICAL · Q1'), findsOneWidget);
      expect(find.text('BEHAVIORAL · Q2'), findsOneWidget);
      expect(find.text('HR · Q3'), findsOneWidget);
      expect(find.text('SUGGESTED ANSWER · STAR'), findsOneWidget);
      expect(find.text(AppStrings.interviewPractice), findsOneWidget);
      expect(find.text(AppStrings.interviewGenerateMore), findsOneWidget);
    });

    testWidgets('the company name joins the context line', (tester) async {
      final app = await _open(tester);
      app.screen.container
          .read(interviewPrepControllerProvider.notifier)
          .updateCompanyName('Acme');
      await tester.pumpAndSettle();
      await _tap(tester, find.text(AppStrings.interviewGenerate));

      expect(
        find.text('From your CV · Frontend Developer at Acme'),
        findsOneWidget,
      );
    });

    testWidgets('the STAR labels are bold, the rest is the answer as is', (
      tester,
    ) async {
      await _generated(tester);

      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().startsWith('Situation:'),
        ),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          spans.add(span);
        }
        return true;
      });
      final bold = [
        for (final span in spans)
          if (span.style?.fontWeight == FontWeight.w700) span.text,
      ];
      expect(bold, ['Situation: ', 'Task: ', 'Action: ', 'Result: ']);
      expect(rich.text.toPlainText(), contains('[add your number].'));
    });

    testWidgets('an answer that is not STAR is not labelled STAR', (
      tester,
    ) async {
      await _generated(tester);

      await _tap(
        tester,
        find.text('Tell me about a time you disagreed with a designer.'),
      );

      expect(find.text('SUGGESTED ANSWER'), findsOneWidget);
      expect(find.text('SUGGESTED ANSWER · STAR'), findsNothing);
      expect(
        find.text('I walked through the trade-offs with the designer.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping another card opens it and closes the first', (
      tester,
    ) async {
      await _generated(tester);

      await _tap(tester, find.text('Why do you want to work at Acme?'));

      expect(find.text(AppStrings.interviewPractice), findsOneWidget);
      expect(
        find.text('The role matches the work I have been preparing for.'),
        findsOneWidget,
      );
      expect(find.text('Situation:'), findsNothing);
    });

    testWidgets('a category filter shows only its questions', (tester) async {
      await _generated(tester);

      await _tapChip(tester, 'HR');

      expect(find.text('Why do you want to work at Acme?'), findsOneWidget);
      expect(find.textContaining('load time'), findsNothing);
      expect(_variant(tester, 'HR'), AppChipVariant.selected);

      await _tapChip(tester, 'All 3');
      expect(find.textContaining('load time'), findsOneWidget);
    });

    testWidgets('keeps each question\'s number while filtering', (
      tester,
    ) async {
      await _generated(tester);

      await _tapChip(tester, 'HR');

      expect(find.text('HR · Q3'), findsOneWidget);
    });
  });

  group('বাংলায় দেখো', () {
    testWidgets('regenerates in Bangla and offers English back', (
      tester,
    ) async {
      final app = await _generated(tester);

      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      expect(app.ai.lastInterviewLanguage, AiOutputLanguage.bangla);
      expect(app.state.language, AiOutputLanguage.bangla);
      expect(find.textContaining('[bn]'), findsWidgets);
      expect(find.text(AppStrings.interviewShowInBangla), findsNothing);
      expect(find.text(AppStrings.interviewShowInEnglish), findsOneWidget);
      expect(find.text(AppStrings.interviewRegeneratedBangla), findsOneWidget);

      await _tap(tester, find.text(AppStrings.interviewShowInEnglish));

      expect(app.ai.lastInterviewLanguage, AiOutputLanguage.english);
      expect(find.textContaining('[bn]'), findsNothing);
      expect(find.text(AppStrings.interviewShowInBangla), findsOneWidget);
    });
  });

  group('বাংলায় দেখো with edited answers', () {
    Future<_App> edited(WidgetTester tester) async {
      final app = await _generated(tester);
      app.screen.container
          .read(interviewPrepControllerProvider.notifier)
          .updateAnswer(app.state.questions.first.id, 'My own answer.');
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('asks before replacing them', (tester) async {
      final app = await edited(tester);

      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      expect(find.text(AppStrings.interviewReplaceEditedBody), findsOneWidget);
      // Nothing has been regenerated yet.
      expect(app.ai.interviewCalls, 1);
      expect(app.state.language, AiOutputLanguage.english);
    });

    testWidgets('"Keep my answers" leaves everything as it was', (
      tester,
    ) async {
      final app = await edited(tester);
      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      await _tap(tester, find.text(AppStrings.interviewReplaceEditedCancel));

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.ai.interviewCalls, 1);
      expect(app.state.language, AiOutputLanguage.english);
      expect(app.state.questions.first.answerText, 'My own answer.');
      expect(find.text(AppStrings.interviewShowInBangla), findsOneWidget);
    });

    testWidgets('Continue regenerates in Bangla', (tester) async {
      final app = await edited(tester);
      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      await _tap(tester, find.text(AppStrings.interviewReplaceEditedContinue));

      expect(app.ai.interviewCalls, 2);
      expect(app.state.language, AiOutputLanguage.bangla);
      expect(app.state.questions.first.answerText, isNot('My own answer.'));
      expect(find.text(AppStrings.interviewShowInEnglish), findsOneWidget);
    });

    testWidgets('does not ask when nothing was edited', (tester) async {
      await _generated(tester);

      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('an answer edited in the Practice sheet counts too', (
      tester,
    ) async {
      final app = await _generated(tester);
      await _tap(tester, find.text(AppStrings.interviewPractice));
      await tester.enterText(find.byType(TextField).last, 'Practised.');
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      expect(find.text(AppStrings.interviewReplaceEditedBody), findsOneWidget);
      expect(app.ai.interviewCalls, 1);
    });

    testWidgets('a reopened saved session always asks', (tester) async {
      final now = DateTime.now();
      final app = await _open(
        tester,
        sessions: FakeInterviewSessionRepository([
          InterviewPrepSession(
            id: 's1',
            cvId: 'cv-frontend',
            targetJobTitle: 'Designer',
            companyName: '',
            jobPost: '',
            interviewType: InterviewType.hrInterview,
            language: AiOutputLanguage.english,
            answerStyle: InterviewAnswerStyle.professional,
            generatedQuestions: [
              InterviewPrepQuestion(
                id: 'q1',
                category: InterviewQuestionCategory.hr,
                question: 'Why us?',
                whyItMatters: '',
                answerTip: '',
                answerText: 'Saved answer.',
                isFavorite: false,
              ),
            ],
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );
      await _tap(tester, find.text('Designer'));

      await _tap(tester, find.text(AppStrings.interviewShowInBangla));

      expect(find.text(AppStrings.interviewReplaceEditedBody), findsOneWidget);
      expect(app.ai.interviewCalls, 0);
    });
  });

  group('Generate more', () {
    testWidgets('adds only the new questions and says how many', (
      tester,
    ) async {
      final app = await _generated(tester);
      app.ai.interviewQuestions = [
        ...app.ai.interviewQuestions,
        const InterviewQuestionItem(
          category: 'company_based',
          question: 'What do you know about Acme?',
          whyItMatters: '',
          answerTip: '',
          sampleAnswer: 'Acme builds tools.',
        ),
      ];

      await _tap(tester, find.text(AppStrings.interviewGenerateMore));

      expect(find.text('All 4'), findsOneWidget);
      expect(find.text('What do you know about Acme?'), findsOneWidget);
      expect(find.text(AppStrings.interviewMoreAdded(1)), findsOneWidget);
    });

    testWidgets('says so when nothing new came back', (tester) async {
      await _generated(tester);

      await _tap(tester, find.text(AppStrings.interviewGenerateMore));

      expect(find.text('All 3'), findsOneWidget);
      expect(find.text(AppStrings.interviewNoNewQuestions), findsOneWidget);
    });
  });

  group('Practice', () {
    testWidgets('opens a sheet whose edits are saved on the question', (
      tester,
    ) async {
      final app = await _generated(tester);

      await _tap(tester, find.text(AppStrings.interviewPractice));
      expect(find.text(AppStrings.interviewPracticeTitle), findsOneWidget);
      expect(find.text('Tip: Name one change and the result.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'My practised answer.',
      );
      await tester.pumpAndSettle();

      expect(app.state.questions.first.answerText, 'My practised answer.');
    });

    testWidgets('can mark the question as a favorite', (tester) async {
      final app = await _generated(tester);
      await _tap(tester, find.text(AppStrings.interviewPractice));

      await _tap(tester, find.text(AppStrings.interviewFavorite));

      expect(app.state.questions.first.isFavorite, isTrue);
      expect(find.text(AppStrings.interviewUnfavorite), findsOneWidget);
    });
  });

  group('⋮ menu', () {
    Future<void> choose(WidgetTester tester, String label) async {
      await _tap(tester, find.byTooltip(AppStrings.interviewMoreOptions));
      await _tap(tester, find.text(label));
    }

    testWidgets('only appears once there are questions', (tester) async {
      await _open(tester);

      expect(find.byTooltip(AppStrings.interviewMoreOptions), findsNothing);
    });

    testWidgets('Save session stores the session', (tester) async {
      final app = await _generated(tester);

      await choose(tester, AppStrings.interviewSaveSession);

      expect(app.sessions.sessions, hasLength(1));
      expect(find.text('Interview prep session saved.'), findsOneWidget);
    });

    testWidgets('Start over returns to the setup', (tester) async {
      await _generated(tester);

      await choose(tester, AppStrings.interviewStartOver);

      expect(find.text(AppStrings.interviewGenerate), findsOneWidget);
      expect(find.text('All 3'), findsNothing);
    });

    testWidgets('Copy all questions copies them and says so', (tester) async {
      final copied = mockClipboard(tester);
      final app = await _generated(tester);

      await choose(tester, AppStrings.interviewCopyAllQuestions);

      expect(copied.single, contains(app.state.questions.first.question));
      expect(find.text('All questions copied.'), findsOneWidget);
    });
  });

  testWidgets('Back leaves the screen', (tester) async {
    await _open(tester);
    expect(find.text(placeholderFor(RouteNames.homePath)), findsNothing);

    await _tap(tester, find.byIcon(Icons.chevron_left_rounded));

    expect(find.text(placeholderFor(RouteNames.homePath)), findsOneWidget);
  });
}
