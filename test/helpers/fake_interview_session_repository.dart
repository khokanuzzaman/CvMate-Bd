import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/repositories/interview_prep_session_repository.dart';

/// In-memory [InterviewPrepSessionRepository] so screen tests need no Hive.
class FakeInterviewSessionRepository implements InterviewPrepSessionRepository {
  FakeInterviewSessionRepository([
    Iterable<InterviewPrepSession> initial = const [],
  ]) {
    for (final session in initial) {
      sessions[session.id] = session;
    }
  }

  final Map<String, InterviewPrepSession> sessions = {};

  @override
  Future<void> clearAllSessions() async => sessions.clear();

  @override
  Future<List<InterviewPrepSession>> getAllSessions() async {
    return sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<InterviewPrepSession?> getSessionById(String id) async => sessions[id];

  @override
  Future<InterviewPrepSession> saveSession(InterviewPrepSession session) async {
    final saved = session.copyWith(updatedAt: DateTime.now());
    sessions[saved.id] = saved;
    return saved;
  }
}
