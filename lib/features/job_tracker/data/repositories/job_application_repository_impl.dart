import 'package:careermatebd/features/job_tracker/data/datasources/job_application_local_data_source.dart';
import 'package:careermatebd/features/job_tracker/data/dtos/job_application_dto.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/repositories/job_application_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobApplicationRepositoryProvider = Provider<JobApplicationRepository>((
  ref,
) {
  final localDataSource = ref.watch(jobApplicationLocalDataSourceProvider);
  return JobApplicationRepositoryImpl(localDataSource);
});

class JobApplicationRepositoryImpl implements JobApplicationRepository {
  const JobApplicationRepositoryImpl(this._localDataSource);

  final JobApplicationLocalDataSource _localDataSource;

  @override
  Future<void> deleteApplication(String id) {
    return _localDataSource.deleteApplication(id);
  }

  @override
  Future<void> clearAllApplications() {
    return _localDataSource.clearAllApplications();
  }

  @override
  Future<JobApplication?> getApplicationById(String id) async {
    final dto = await _localDataSource.getApplicationById(id);
    return dto?.application;
  }

  @override
  Future<List<JobApplication>> getAllApplications() async {
    final dtos = await _localDataSource.getAllApplications();
    final applications = dtos.map((dto) => dto.application).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return applications;
  }

  @override
  Future<JobApplication> saveApplication(JobApplication application) async {
    final normalized = application.copyWith(updatedAt: DateTime.now());
    await _localDataSource.saveApplication(JobApplicationDto(normalized));
    return normalized;
  }
}
