import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';

abstract class InterviewPrepSessionRepository {
  Future<List<InterviewPrepSession>> getAllSessions();

  Future<InterviewPrepSession?> getSessionById(String id);

  Future<InterviewPrepSession> saveSession(InterviewPrepSession session);

  Future<void> clearAllSessions();
}
