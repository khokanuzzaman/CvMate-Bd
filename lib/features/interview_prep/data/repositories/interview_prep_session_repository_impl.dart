import 'package:careermatebd/features/interview_prep/data/datasources/interview_prep_session_local_data_source.dart';
import 'package:careermatebd/features/interview_prep/data/dtos/interview_prep_session_dto.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/repositories/interview_prep_session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final interviewPrepSessionRepositoryProvider =
    Provider<InterviewPrepSessionRepository>((ref) {
      final localDataSource = ref.watch(
        interviewPrepSessionLocalDataSourceProvider,
      );
      return InterviewPrepSessionRepositoryImpl(localDataSource);
    });

class InterviewPrepSessionRepositoryImpl
    implements InterviewPrepSessionRepository {
  const InterviewPrepSessionRepositoryImpl(this._localDataSource);

  final InterviewPrepSessionLocalDataSource _localDataSource;

  @override
  Future<void> clearAllSessions() {
    return _localDataSource.clearAllSessions();
  }

  @override
  Future<List<InterviewPrepSession>> getAllSessions() async {
    final dtos = await _localDataSource.getAllSessions();
    final sessions = dtos.map((dto) => dto.session).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<InterviewPrepSession?> getSessionById(String id) async {
    final dto = await _localDataSource.getSessionById(id);
    return dto?.session;
  }

  @override
  Future<InterviewPrepSession> saveSession(InterviewPrepSession session) async {
    final normalized = session.copyWith(updatedAt: DateTime.now());
    await _localDataSource.saveSession(InterviewPrepSessionDto(normalized));
    return normalized;
  }
}
