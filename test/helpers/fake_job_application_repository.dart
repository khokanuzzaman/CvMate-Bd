import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/domain/repositories/job_application_repository.dart';

/// In-memory [JobApplicationRepository] so tracker tests need no Hive.
class FakeJobApplicationRepository implements JobApplicationRepository {
  FakeJobApplicationRepository([Iterable<JobApplication> initial = const []]) {
    for (final application in initial) {
      store[application.id] = application;
    }
  }

  final Map<String, JobApplication> store = {};

  @override
  Future<void> clearAllApplications() async => store.clear();

  @override
  Future<void> deleteApplication(String id) async => store.remove(id);

  @override
  Future<List<JobApplication>> getAllApplications() async {
    return store.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<JobApplication?> getApplicationById(String id) async => store[id];

  @override
  Future<JobApplication> saveApplication(JobApplication application) async {
    store[application.id] = application;
    return application;
  }
}

/// The three applications of the Job Tracker design: an upcoming interview, an
/// application that is 8 days old, and an offer.
List<JobApplication> designApplications({DateTime? now}) {
  final today = now ?? DateTime.now();
  return [
    JobApplication.empty().copyWith(
      id: 'job-interview',
      jobTitle: 'Frontend Developer',
      companyName: 'Acme Ltd.',
      jobSource: JobSource.linkedIn,
      status: JobApplicationStatus.interview,
      appliedDate: today.subtract(const Duration(days: 5)),
      interviewDate: DateTime(
        today.year,
        today.month,
        today.day,
        10,
        30,
      ).add(const Duration(days: 3)),
      updatedAt: today,
    ),
    JobApplication.empty().copyWith(
      id: 'job-applied',
      jobTitle: 'React Developer',
      companyName: 'Beta Soft',
      jobSource: JobSource.bdjobs,
      status: JobApplicationStatus.applied,
      appliedDate: today.subtract(const Duration(days: 8)),
      updatedAt: today.subtract(const Duration(hours: 1)),
    ),
    JobApplication.empty().copyWith(
      id: 'job-offer',
      jobTitle: 'UI Engineer',
      companyName: 'Cloud Co.',
      jobSource: JobSource.email,
      status: JobApplicationStatus.offered,
      appliedDate: today.subtract(const Duration(days: 20)),
      updatedAt: today.subtract(const Duration(hours: 2)),
    ),
  ];
}
