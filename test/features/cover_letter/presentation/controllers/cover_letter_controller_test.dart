import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/repositories/cover_letter_repository.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cover letter controller generates and saves a draft', () async {
    final cvRepository = _FakeCvRepository([
      CvProfile.empty().copyWith(
        id: 'cv-1',
        title: 'Flutter CV',
        personalInfo: const PersonalInfo(
          fullName: 'Khokan Uzzaman',
          desiredRole: 'Flutter Developer',
          email: 'khokan@example.com',
          phone: '01700000000',
          address: 'Dhaka, Bangladesh',
        ),
        professionalSummary:
            'Junior Flutter developer with app-building experience.',
      ),
    ]);
    final draftRepository = _FakeCoverLetterRepository();

    final container = ProviderContainer(
      overrides: [
        cvRepositoryProvider.overrideWithValue(cvRepository),
        coverLetterRepositoryProvider.overrideWithValue(draftRepository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(coverLetterControllerProvider.notifier);
    await controller.initialize();
    controller.selectOutputType(CoverLetterOutputType.jobApplicationEmail);
    controller.updateTargetCompany('CareerHub BD');
    controller.updateJobTitle('Flutter Developer');
    controller.updateJobDetails(
      'Need Flutter, REST API integration, and mobile UI experience.',
    );

    await controller.generateContent();
    final generatedState = container.read(coverLetterControllerProvider);
    expect(generatedState.generatedContent, isNotEmpty);

    final saveMessage = await controller.saveDraft();
    expect(saveMessage, anyOf('Draft saved.', 'Draft updated.'));
    expect(await draftRepository.getAllDrafts(), hasLength(1));
    expect(
      (await draftRepository.getAllDrafts()).first.outputType,
      CoverLetterOutputType.jobApplicationEmail,
    );
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

class _FakeCoverLetterRepository implements CoverLetterRepository {
  final Map<String, CoverLetterDraft> _drafts = {};

  @override
  Future<void> clearAllDrafts() async {
    _drafts.clear();
  }

  @override
  Future<void> deleteDraft(String id) async {
    _drafts.remove(id);
  }

  @override
  Future<List<CoverLetterDraft>> getAllDrafts() async {
    return _drafts.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<CoverLetterDraft?> getDraftById(String id) async {
    return _drafts[id];
  }

  @override
  Future<CoverLetterDraft> saveDraft(CoverLetterDraft draft) async {
    final saved = draft.copyWith(updatedAt: DateTime.now());
    _drafts[draft.id] = saved;
    return saved;
  }
}
