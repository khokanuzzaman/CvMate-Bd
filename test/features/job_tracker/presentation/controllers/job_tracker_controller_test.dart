import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/domain/repositories/job_application_repository.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Job tracker controller saves and updates status', () async {
    final repository = _FakeJobApplicationRepository();
    final container = ProviderContainer(
      overrides: [
        jobApplicationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(jobTrackerControllerProvider.notifier);
    await controller.reload();

    final saved = await controller.saveApplication(
      JobApplication.empty().copyWith(
        id: 'job-1',
        companyName: 'BRAC Bank',
        jobTitle: 'Management Trainee',
        jobSource: JobSource.bdjobs,
        status: JobApplicationStatus.applied,
      ),
    );

    expect(saved.companyName, 'BRAC Bank');
    expect(
      container.read(jobTrackerControllerProvider).asData?.value,
      hasLength(1),
    );

    final updated = await controller.updateStatus(
      'job-1',
      JobApplicationStatus.interview,
    );
    expect(updated, isNotNull);
    expect(updated!.status, JobApplicationStatus.interview);
    expect(
      (await repository.getApplicationById('job-1'))!.status,
      JobApplicationStatus.interview,
    );
  });
}

class _FakeJobApplicationRepository implements JobApplicationRepository {
  final Map<String, JobApplication> _applications = {};

  @override
  Future<void> clearAllApplications() async {
    _applications.clear();
  }

  @override
  Future<void> deleteApplication(String id) async {
    _applications.remove(id);
  }

  @override
  Future<List<JobApplication>> getAllApplications() async {
    return _applications.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<JobApplication?> getApplicationById(String id) async {
    return _applications[id];
  }

  @override
  Future<JobApplication> saveApplication(JobApplication application) async {
    final saved = application.copyWith(updatedAt: DateTime.now());
    _applications[application.id] = saved;
    return saved;
  }
}
