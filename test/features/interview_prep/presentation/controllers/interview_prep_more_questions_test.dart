import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_ai_career_service.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/fake_interview_session_repository.dart';

const _extra = InterviewQuestionItem(
  category: 'company_based',
  question: 'What do you know about Acme?',
  whyItMatters: 'Shows preparation.',
  answerTip: 'Mention one product or value.',
  sampleAnswer: 'Acme builds tools for small teams.',
);

Future<(ProviderContainer, FakeAiCareerService)> _setUp({
  bool withCv = true,
}) async {
  final ai = FakeAiCareerService();
  final container = ProviderContainer(
    overrides: [
      cvRepositoryProvider.overrideWithValue(
        FakeCvRepository(withCv ? [designCv()] : []),
      ),
      aiCareerServiceProvider.overrideWithValue(ai),
      interviewPrepSessionRepositoryProvider.overrideWithValue(
        FakeInterviewSessionRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(interviewPrepControllerProvider.notifier).initialize();
  return (container, ai);
}

void main() {
  test('generateMoreQuestions appends only questions not listed yet', () async {
    final (container, ai) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();
    final first = container.read(interviewPrepControllerProvider).questions;
    expect(first, hasLength(3));

    ai.interviewQuestions = [...ai.interviewQuestions, _extra];
    final added = await controller.generateMoreQuestions();

    final state = container.read(interviewPrepControllerProvider);
    expect(added, 1);
    expect(state.questions, hasLength(4));
    expect(state.questions.last.question, _extra.question);
    expect(state.isGenerating, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('generateMoreQuestions keeps edited answers and favorites', () async {
    final (container, ai) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();
    final id = container
        .read(interviewPrepControllerProvider)
        .questions
        .first
        .id;
    controller
      ..updateAnswer(id, 'My own answer.')
      ..toggleFavorite(id);

    ai.interviewQuestions = [...ai.interviewQuestions, _extra];
    await controller.generateMoreQuestions();

    final kept = container
        .read(interviewPrepControllerProvider)
        .questions
        .firstWhere((question) => question.id == id);
    expect(kept.answerText, 'My own answer.');
    expect(kept.isFavorite, isTrue);
  });

  test('a repeat with nothing new adds nothing', () async {
    final (container, _) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();

    final added = await controller.generateMoreQuestions();

    expect(added, 0);
    expect(
      container.read(interviewPrepControllerProvider).questions,
      hasLength(3),
    );
  });

  test('duplicates are matched ignoring case and spacing', () async {
    final (container, ai) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();

    ai.interviewQuestions = [
      InterviewQuestionItem(
        category: 'hr',
        question: '  WHY do you want   to work at acme? ',
        whyItMatters: '',
        answerTip: '',
        sampleAnswer: '',
      ),
    ];
    final added = await controller.generateMoreQuestions();

    expect(added, 0);
  });

  test('a failed request keeps the set and reports the error', () async {
    final (container, ai) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();

    ai.interviewFailure = const Failure('AI is unavailable.');
    final added = await controller.generateMoreQuestions();

    final state = container.read(interviewPrepControllerProvider);
    expect(added, 0);
    expect(state.questions, hasLength(3));
    expect(state.errorMessage, 'AI is unavailable.');
    expect(state.isGenerating, isFalse);
  });

  test('without a CV or role it asks for one and calls nothing', () async {
    final (container, ai) = await _setUp(withCv: false);
    final controller = container.read(interviewPrepControllerProvider.notifier);

    final added = await controller.generateMoreQuestions();

    expect(added, 0);
    expect(ai.interviewCalls, 0);
    expect(
      container.read(interviewPrepControllerProvider).errorMessage,
      contains('target role'),
    );
  });

  test('generateQuestions still replaces the whole set', () async {
    final (container, ai) = await _setUp();
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.generateQuestions();
    ai.interviewQuestions = [_extra];

    await controller.generateQuestions();

    final questions = container.read(interviewPrepControllerProvider).questions;
    expect(questions.map((q) => q.question), [_extra.question]);
  });
}
