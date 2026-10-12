import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_answer_style.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_question.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_question_category.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_type.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

InterviewPrepSession _session() => InterviewPrepSession(
  id: 's1',
  cvId: 'cv-frontend',
  targetJobTitle: 'UI Engineer',
  companyName: 'Beta Soft',
  jobPost: 'Build UI.',
  interviewType: InterviewType.technicalInterview,
  language: AiOutputLanguage.english,
  answerStyle: InterviewAnswerStyle.professional,
  generatedQuestions: const [
    InterviewPrepQuestion(
      id: 'q1',
      category: InterviewQuestionCategory.technical,
      question: 'What is a render object?',
      whyItMatters: 'Core knowledge.',
      answerTip: 'Be concrete.',
      answerText: 'It paints and lays out.',
      isFavorite: false,
    ),
  ],
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 2),
);

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  FakeCvRepository? repository,
  FakeInterviewSessionRepository? sessions,
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: repository ?? FakeCvRepository([designCv()]),
    interviewSessions: sessions,
    surface: const Size(390, 3400),
  );
  unawaited(app.router.push(RouteNames.interviewPrepPath));
  await tester.pumpAndSettle();
  return app;
}

InterviewPrepState _state(CoreFlowApp app) =>
    app.container.read(interviewPrepControllerProvider);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _generate(WidgetTester tester) =>
    _tap(tester, find.text(AppStrings.interviewGenerate));

AppChipVariant _variant(WidgetTester tester, String label) =>
    tester.widget<AppChip>(find.widgetWithText(AppChip, label)).variant;

void main() {
  group('setup', () {
    testWidgets('shows the CV, fields, choices and the quick practice', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text(AppStrings.interviewSetupTitle), findsOneWidget);
      expect(find.text('Frontend Developer CV'), findsOneWidget);
      expect(find.text(AppStrings.interviewGenerate), findsOneWidget);
      expect(find.text(InterviewType.hrInterview.label), findsOneWidget);
      expect(find.text(AppStrings.interviewQuickTitle), findsOneWidget);
      expect(find.text('Tell me about yourself.'), findsOneWidget);
      expect(find.text(AppStrings.interviewEmptyTitle), findsOneWidget);
    });

    testWidgets('type, language and style choices reach the controller', (
      tester,
    ) async {
      final app = await _open(tester);
      expect(
        _variant(tester, InterviewType.hrInterview.label),
        AppChipVariant.selected,
      );

      await _tap(tester, find.text(InterviewType.technicalInterview.label));
      await _tap(tester, find.text(AppStrings.commonBangla));
      await _tap(tester, find.text(InterviewAnswerStyle.values.last.label));

      final state = _state(app);
      expect(state.interviewType, InterviewType.technicalInterview);
      expect(state.language, AiOutputLanguage.bangla);
      expect(state.answerStyle, InterviewAnswerStyle.values.last);
      expect(
        _variant(tester, InterviewType.technicalInterview.label),
        AppChipVariant.selected,
      );
      expect(
        _variant(tester, InterviewType.hrInterview.label),
        AppChipVariant.neutral,
      );
    });

    testWidgets('role, company and job post reach the controller', (
      tester,
    ) async {
      final app = await _open(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Frontend Developer');
      await tester.enterText(fields.at(1), 'Acme');
      await tester.enterText(fields.at(2), 'Build accessible UI.');

      final state = _state(app);
      expect(state.targetJobTitle, 'Frontend Developer');
      expect(state.companyName, 'Acme');
      expect(state.jobPostText, 'Build accessible UI.');
    });

    testWidgets('the CV card can choose another CV or none', (tester) async {
      final app = await _open(
        tester,
        repository: FakeCvRepository([
          designCv(),
          designCv(id: 'cv-2', title: 'Product Designer CV'),
        ]),
      );

      await _tap(tester, find.text('Frontend Developer CV'));
      await _tap(tester, find.text('Product Designer CV'));
      expect(_state(app).selectedCvId, 'cv-2');

      await _tap(tester, find.text('Product Designer CV'));
      await _tap(tester, find.text(AppStrings.interviewNoCv));
      expect(_state(app).selectedCvId, isNull);
      expect(find.text(AppStrings.interviewNoCv), findsOneWidget);
    });

    testWidgets('with no CV it offers to create one and can still practise', (
      tester,
    ) async {
      final app = await _open(tester, repository: FakeCvRepository());

      expect(find.text(AppStrings.interviewNoCvTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Nurse');
      await tester.pumpAndSettle();
      await _generate(tester);
      expect(app.ai.interviewCalls, 1);

      await _tap(tester, find.text(AppStrings.interviewCreateCv).first);
      expect(find.text(builderPlaceholder), findsOneWidget);
    });
  });

  group('generating', () {
    testWidgets('shows the questions by category and calls the AI once', (
      tester,
    ) async {
      final app = await _open(tester);

      await _generate(tester);

      expect(app.ai.interviewCalls, 1);
      expect(app.ai.lastInterviewType, InterviewType.hrInterview.label);
      expect(find.text(AppStrings.interviewResultsTitle), findsOneWidget);
      expect(
        find.text(InterviewQuestionCategory.hr.label.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(InterviewQuestionCategory.technical.label.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('How do you keep a React app fast?'), findsOneWidget);
      expect(find.text(AppStrings.interviewEmptyTitle), findsNothing);
    });

    testWidgets('a question opens to a tip and an editable answer', (
      tester,
    ) async {
      final app = await _open(tester);
      await _generate(tester);
      expect(find.text(AppStrings.interviewAnswerLabel), findsNothing);

      await _tap(tester, find.text('Tell me about yourself.').last);
      expect(
        find.text(
          AppStrings.interviewAnswerTip('Start with your current focus.'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'I am a front-end developer.'),
        'My edited answer.',
      );
      await tester.pumpAndSettle();
      expect(
        _state(app).questions
            .firstWhere((q) => q.question == 'Tell me about yourself.')
            .answerText,
        'My edited answer.',
      );
    });

    testWidgets('a question can be favorited and unfavorited', (tester) async {
      final app = await _open(tester);
      await _generate(tester);
      await _tap(tester, find.text('Tell me about yourself.').last);

      await _tap(tester, find.text(AppStrings.interviewFavorite));
      expect(_state(app).questions.first.isFavorite, isTrue);
      expect(find.text(AppStrings.interviewUnfavorite), findsOneWidget);

      await _tap(tester, find.text(AppStrings.interviewUnfavorite));
      expect(_state(app).questions.first.isFavorite, isFalse);
    });

    testWidgets('Save session stores it and Start over clears the set', (
      tester,
    ) async {
      final sessions = FakeInterviewSessionRepository();
      final app = await _open(tester, sessions: sessions);
      await _generate(tester);

      await _tap(tester, find.text(AppStrings.interviewSaveSession));
      expect(sessions.saveCount, 1);
      expect(sessions.sessions.single.generatedQuestions, hasLength(3));

      await _tap(tester, find.text(AppStrings.commonStartOver).first);
      expect(_state(app).questions, isEmpty);
      expect(find.text(AppStrings.interviewEmptyTitle), findsOneWidget);
    });
  });

  group('copying', () {
    List<String> mockClipboard(WidgetTester tester) {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return copied;
    }

    testWidgets('a quick practice question is copied with a snackbar', (
      tester,
    ) async {
      final copied = mockClipboard(tester);
      await _open(tester);

      await _tap(
        tester,
        find.byTooltip(AppStrings.interviewCopyQuestion).first,
      );

      expect(copied.single, 'Tell me about yourself.');
      expect(find.text(AppStrings.interviewQuestionCopied), findsOneWidget);
    });

    testWidgets('Copy all questions copies every question', (tester) async {
      final copied = mockClipboard(tester);
      await _open(tester);
      await _generate(tester);

      await _tap(tester, find.text(AppStrings.interviewCopyAllQuestions));

      expect(copied.single, contains('Tell me about yourself.'));
      expect(copied.single, contains('How do you keep a React app fast?'));
    });
  });

  group('recent sessions', () {
    testWidgets('a saved session is listed and reopens its questions', (
      tester,
    ) async {
      final app = await _open(
        tester,
        sessions: FakeInterviewSessionRepository([_session()]),
      );

      expect(
        find.text(AppStrings.interviewSessionsTitle.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('UI Engineer'), findsOneWidget);

      await _tap(tester, find.text('UI Engineer'));

      expect(_state(app).questions.single.question, 'What is a render object?');
      expect(find.text('What is a render object?'), findsOneWidget);
      expect(_state(app).interviewType, InterviewType.technicalInterview);
    });
  });

  testWidgets('the top-bar restart clears the setup', (tester) async {
    final app = await _open(tester);
    await tester.enterText(find.byType(TextField).first, 'Nurse');
    await tester.pumpAndSettle();

    await _tap(tester, find.byTooltip(AppStrings.commonStartOver));

    // Start over returns to the defaults: the CV's own role, no company.
    expect(_state(app).targetJobTitle, 'Frontend Developer');
    expect(_state(app).companyName, isEmpty);
  });
}
