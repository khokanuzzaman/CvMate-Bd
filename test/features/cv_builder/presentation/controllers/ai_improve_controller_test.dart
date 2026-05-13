import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI Improve controller generates and applies summary output', () async {
    final repository = _FakeCvRepository([
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
        professionalSummary: 'Junior flutter developer with project work.',
        skills: const [
          SkillInfo(id: '1', name: 'Flutter', level: 'Advanced'),
          SkillInfo(id: '2', name: 'Dart', level: 'Advanced'),
        ],
        projects: const [
          ProjectInfo(
            id: 'p1',
            title: 'Appointment App',
            description: 'built a booking app',
            technologies: ['Flutter', 'Firebase'],
          ),
        ],
      ),
    ]);

    final container = ProviderContainer(
      overrides: [cvRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(aiImproveControllerProvider.notifier);
    await controller.initialize();

    await controller.generateSuggestion();
    final generatedState = container.read(aiImproveControllerProvider);
    expect(generatedState.generatedOutput, isNotEmpty);

    final message = await controller.applySuggestion();
    expect(message, 'AI suggestion applied to CV.');

    final savedCv = await repository.getCvById('cv-1');
    expect(savedCv, isNotNull);
    expect(savedCv!.professionalSummary, generatedState.generatedOutput);
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
