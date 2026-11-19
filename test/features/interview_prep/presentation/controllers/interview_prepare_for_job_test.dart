import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_ai_career_service.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/fake_interview_session_repository.dart';

void main() {
  test('prepareForJob fills the setup; questions for the same job are kept, '
      'another job starts over', () async {
    final cv = designCv();
    final container = ProviderContainer(
      overrides: [
        cvRepositoryProvider.overrideWithValue(FakeCvRepository([cv])),
        aiCareerServiceProvider.overrideWithValue(FakeAiCareerService()),
        interviewPrepSessionRepositoryProvider.overrideWithValue(
          FakeInterviewSessionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(interviewPrepControllerProvider.notifier);
    await controller.initialize();

    controller.prepareForJob(
      jobTitle: ' Frontend Developer ',
      companyName: 'Acme Ltd.',
      cvId: cv.id,
    );
    var state = container.read(interviewPrepControllerProvider);
    expect(state.targetJobTitle, 'Frontend Developer');
    expect(state.companyName, 'Acme Ltd.');
    expect(state.selectedCvId, cv.id);

    await controller.generateQuestions();
    controller.prepareForJob(
      jobTitle: 'frontend developer',
      companyName: 'ACME LTD.',
      cvId: cv.id,
    );
    expect(
      container.read(interviewPrepControllerProvider).questions,
      isNotEmpty,
    );

    controller.prepareForJob(
      jobTitle: 'React Developer',
      companyName: 'Beta Soft',
      cvId: 'deleted-cv',
    );
    state = container.read(interviewPrepControllerProvider);
    expect(state.questions, isEmpty);
    expect(state.targetJobTitle, 'React Developer');
    expect(state.companyName, 'Beta Soft');
    expect(state.selectedCvId, cv.id, reason: 'an unknown CV is not chosen');
  });
}
