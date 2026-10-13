import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _jobPost =
    'We are hiring a Flutter Developer skilled in Flutter, Dart, Firebase, '
    'REST API, and GitHub to build mobile products with a cross-functional team.';

CvProfile _sampleCv() => CvProfile.empty().copyWith(
  id: 'cv-1',
  title: 'Flutter CV',
  personalInfo: const PersonalInfo(
    fullName: 'Nusrat Jahan',
    desiredRole: 'Flutter Developer',
    email: 'nusrat@example.com',
    phone: '01700000000',
  ),
  professionalSummary: 'Junior Flutter developer with app-building experience.',
  skills: const [
    SkillInfo(id: 'skill-1', name: 'Flutter', level: 'Advanced'),
    SkillInfo(id: 'skill-2', name: 'Dart', level: 'Advanced'),
  ],
  experiences: const [
    ExperienceInfo(
      id: 'exp-1',
      companyName: 'Tech Studio BD',
      jobTitle: 'Flutter Intern',
      highlights: [
        'Built a Flutter app with Firebase authentication.',
        'Worked on REST API integration for mobile screens.',
      ],
    ),
  ],
);

void main() {
  test('analyze() and tailor() happy path with the mock AI service', () async {
    final repository = _FakeCvRepository([_sampleCv()]);
    final container = ProviderContainer(
      overrides: [cvRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(tailoringControllerProvider.notifier);
    await controller.initialize();

    var state = container.read(tailoringControllerProvider);
    expect(state.hasSavedCvs, isTrue);
    expect(state.cvId, 'cv-1');

    controller.updateJobPost(
      jobPostText: _jobPost,
      jobTitle: 'Flutter Developer',
      company: 'Acme Ltd',
    );

    await controller.analyze();
    state = container.read(tailoringControllerProvider);
    expect(state.matchReport, isNotNull);
    expect(state.stage, TailoringStage.ready);
    expect(state.matchReport!.extractedKeywords, isNotEmpty);
    expect(state.matchReport!.matchPercentage, inInclusiveRange(0, 100));

    await controller.tailor();
    state = container.read(tailoringControllerProvider);
    expect(state.stage, TailoringStage.ready);
    final result = state.result;
    expect(result, isNotNull);
    expect(result!.tailoredSummary.trim(), isNotEmpty);
    expect(result.emphasizedSkills, isNotEmpty);
    expect(result.rewrittenBullets, isNotEmpty);
    for (final bullet in result.rewrittenBullets) {
      expect(bullet.experienceId, 'exp-1');
      expect(bullet.suggested.trim(), isNotEmpty);
    }

    // The source CV must not be mutated by tailoring.
    final source = await repository.getCvById('cv-1');
    expect(
      source!.professionalSummary,
      'Junior Flutter developer with app-building experience.',
    );

    // Saving persists a NEW CV and keeps the source untouched.
    final saved = await controller.saveAsTailoredCopy();
    expect(saved, isNotNull);
    expect(saved!.id, isNot('cv-1'));
    final allCvs = await repository.getAllCvs();
    expect(allCvs, hasLength(2));
    final stillSource = await repository.getCvById('cv-1');
    expect(
      stillSource!.professionalSummary,
      'Junior Flutter developer with app-building experience.',
    );
  });

  test('generateCoverLetter() fills the cover letter with the mock AI', () async {
    final repository = _FakeCvRepository([_sampleCv()]);
    final container = ProviderContainer(
      overrides: [cvRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(tailoringControllerProvider.notifier);
    await controller.initialize();
    controller.updateJobPost(
      jobPostText: _jobPost,
      jobTitle: 'Flutter Developer',
      company: 'Acme Ltd',
    );

    await controller.generateCoverLetter();
    final state = container.read(tailoringControllerProvider);
    expect(state.stage, TailoringStage.ready);
    expect(state.result?.coverLetter.trim(), isNotEmpty);
  });

  test('tailor() surfaces a Failure when the AI service fails', () async {
    final repository = _FakeCvRepository([_sampleCv()]);
    final container = ProviderContainer(
      overrides: [
        cvRepositoryProvider.overrideWithValue(repository),
        aiCareerServiceProvider.overrideWithValue(const _FailingAiService()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(tailoringControllerProvider.notifier);
    await controller.initialize();
    controller.updateJobPost(
      jobPostText: _jobPost,
      jobTitle: 'Flutter Developer',
      company: 'Acme Ltd',
    );

    await controller.tailor();
    final state = container.read(tailoringControllerProvider);
    expect(state.stage, TailoringStage.error);
    expect(state.failure, isNotNull);
    expect(state.result, isNull);
  });
}

class _FakeCvRepository implements CvRepository {
  _FakeCvRepository(List<CvProfile> initial)
    : _profiles = {for (final profile in initial) profile.id: profile};

  final Map<String, CvProfile> _profiles;

  @override
  Future<CvProfile> createEmptyCv({String? title}) async {
    final now = DateTime.now();
    final profile = CvProfile.empty().copyWith(
      id: now.microsecondsSinceEpoch.toString(),
      title: title ?? 'New CV',
      createdAt: now,
      updatedAt: now,
    );
    _profiles[profile.id] = profile;
    return profile;
  }

  @override
  Future<void> deleteCv(String id) async {
    _profiles.remove(id);
  }

  @override
  Future<void> clearAllCvs() async {
    _profiles.clear();
  }

  @override
  Future<CvProfile> duplicateCv(String id) async {
    final source = _profiles[id]!;
    final now = DateTime.now();
    final duplicated = source.copyWith(
      id: '${id}_copy',
      title: '${source.displayTitle} Copy',
      createdAt: now,
      updatedAt: now,
    );
    _profiles[duplicated.id] = duplicated;
    return duplicated;
  }

  @override
  Future<List<CvProfile>> getAllCvs() async {
    return _profiles.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<CvProfile?> getCvById(String id) async {
    return _profiles[id];
  }

  @override
  Future<CvProfile> saveCv(CvProfile profile) async {
    final saved = profile.copyWith(updatedAt: DateTime.now());
    _profiles[profile.id] = saved;
    return saved;
  }
}

/// AI service that always fails; used to exercise the tailoring failure path.
/// Only [tailorCvForJob] is exercised; the rest route through [noSuchMethod].
class _FailingAiService implements AiCareerService {
  const _FailingAiService();

  @override
  Future<Result<CvTailoringSuggestion>> tailorCvForJob({
    required CvProfile profile,
    required String jobPostText,
    String jobTitle = '',
    String companyName = '',
    List<String> targetKeywords = const [],
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) async {
    return const FailureResult(
      Failure('AI tailoring failed. Please try again.'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
