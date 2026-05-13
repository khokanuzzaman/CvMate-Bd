import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/repositories/interview_prep_session_repository.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Interview Prep controller generates, edits, and saves a session',
    () async {
      final cvRepository = _FakeCvRepository([
        CvProfile.empty().copyWith(
          id: 'cv-1',
          title: 'Flutter CV',
          personalInfo: const PersonalInfo(
            fullName: 'Khokan Uzzaman',
            desiredRole: 'Flutter Developer',
            email: 'khokan@example.com',
            phone: '01700000000',
          ),
          professionalSummary:
              'Junior Flutter developer with practical project experience.',
          skills: const [
            SkillInfo(id: 'skill-1', name: 'Flutter', level: 'Advanced'),
            SkillInfo(id: 'skill-2', name: 'Dart', level: 'Advanced'),
          ],
          projects: const [
            ProjectInfo(
              id: 'project-1',
              title: 'CareerMate Mobile App',
              description: 'Built a CV and interview prep app.',
              technologies: ['Flutter', 'Firebase'],
            ),
          ],
        ),
      ]);
      final sessionRepository = _FakeInterviewPrepSessionRepository();

      final container = ProviderContainer(
        overrides: [
          cvRepositoryProvider.overrideWithValue(cvRepository),
          interviewPrepSessionRepositoryProvider.overrideWithValue(
            sessionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        interviewPrepControllerProvider.notifier,
      );
      await controller.initialize();
      await controller.generateQuestions();

      final generatedState = container.read(interviewPrepControllerProvider);
      expect(generatedState.questions, isNotEmpty);

      final firstQuestion = generatedState.questions.first;
      controller.toggleFavorite(firstQuestion.id);
      controller.updateAnswer(firstQuestion.id, 'Updated practice answer.');

      final saveMessage = await controller.saveSession();
      expect(saveMessage, 'Interview prep session saved.');
      expect(await sessionRepository.getAllSessions(), hasLength(1));

      final savedSession = (await sessionRepository.getAllSessions()).first;
      expect(savedSession.generatedQuestions.first.isFavorite, isTrue);
      expect(
        savedSession.generatedQuestions.first.answerText,
        'Updated practice answer.',
      );
    },
  );
}

class _FakeCvRepository implements CvRepository {
  _FakeCvRepository(List<CvProfile> initial)
    : _profiles = {for (final profile in initial) profile.id: profile};

  final Map<String, CvProfile> _profiles;

  @override
  Future<void> clearAllCvs() async {
    _profiles.clear();
  }

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

class _FakeInterviewPrepSessionRepository
    implements InterviewPrepSessionRepository {
  final Map<String, InterviewPrepSession> _sessions = {};

  @override
  Future<void> clearAllSessions() async {
    _sessions.clear();
  }

  @override
  Future<List<InterviewPrepSession>> getAllSessions() async {
    return _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<InterviewPrepSession?> getSessionById(String id) async {
    return _sessions[id];
  }

  @override
  Future<InterviewPrepSession> saveSession(InterviewPrepSession session) async {
    final saved = session.copyWith(updatedAt: DateTime.now());
    _sessions[saved.id] = saved;
    return saved;
  }
}
