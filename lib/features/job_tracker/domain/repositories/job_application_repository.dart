import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';

abstract class JobApplicationRepository {
  Future<List<JobApplication>> getAllApplications();

  Future<JobApplication?> getApplicationById(String id);

  Future<JobApplication> saveApplication(JobApplication application);

  Future<void> deleteApplication(String id);

  Future<void> clearAllApplications();
}
