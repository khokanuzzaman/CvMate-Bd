import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

void main() {
  test('the ATS job post follows Tailor until the user types or clears '
      'one here', () async {
    final container = ProviderContainer(
      overrides: [
        cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
      ],
    );
    addTearDown(container.dispose);
    final ats = container.read(atsCheckerControllerProvider.notifier);
    AtsCheckerState state() => container.read(atsCheckerControllerProvider);
    await ats.initialize();

    ats.syncJobPostFromTailor('  Flutter developer, Dhaka  ');
    expect(state().jobPostText, 'Flutter developer, Dhaka');
    expect(state().jobPostSource, AtsJobPostSource.tailor);
    ats.syncJobPostFromTailor('React developer, Dubai');
    expect(state().jobPostText, 'React developer, Dubai');

    ats.updateJobPostText('My own post');
    ats.syncJobPostFromTailor('Something else');
    expect(state().jobPostText, 'My own post');
    expect(state().jobPostSource, AtsJobPostSource.typed);

    ats.clearJobPost();
    ats.syncJobPostFromTailor('React developer, Dubai');
    expect(state().hasJobPost, isFalse);
    expect(state().jobPostSource, AtsJobPostSource.cleared);
    expect(state().jobMatchReport, isNull);
  });
}
