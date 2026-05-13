import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobTrackerSearchQueryProvider =
    NotifierProvider<JobTrackerSearchQueryController, String>(
      JobTrackerSearchQueryController.new,
    );
final jobTrackerStatusFilterProvider =
    NotifierProvider<JobTrackerStatusFilterController, JobApplicationStatus?>(
      JobTrackerStatusFilterController.new,
    );

final jobTrackerControllerProvider =
    AsyncNotifierProvider<JobTrackerController, List<JobApplication>>(
      JobTrackerController.new,
    );

final filteredJobApplicationsProvider = Provider<List<JobApplication>>((ref) {
  final applications = ref
      .watch(jobTrackerControllerProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <JobApplication>[]);
  final query = ref.watch(jobTrackerSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(jobTrackerStatusFilterProvider);

  return [
    for (final application in applications)
      if ((filter == null || application.status == filter) &&
          (query.isEmpty ||
              application.companyName.toLowerCase().contains(query) ||
              application.jobTitle.toLowerCase().contains(query)))
        application,
  ];
});

final jobTrackerSummaryProvider = Provider<JobTrackerSummary>((ref) {
  final applications = ref
      .watch(jobTrackerControllerProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <JobApplication>[]);
  return JobTrackerSummary.fromApplications(applications);
});

class JobTrackerController extends AsyncNotifier<List<JobApplication>> {
  @override
  Future<List<JobApplication>> build() {
    return ref.read(jobApplicationRepositoryProvider).getAllApplications();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jobApplicationRepositoryProvider).getAllApplications(),
    );
  }

  Future<JobApplication?> getApplicationById(String id) {
    return ref.read(jobApplicationRepositoryProvider).getApplicationById(id);
  }

  Future<JobApplication> saveApplication(JobApplication application) async {
    final saved = await ref
        .read(jobApplicationRepositoryProvider)
        .saveApplication(application);
    await _replaceAndPublish(saved);
    return saved;
  }

  Future<JobApplication?> updateStatus(
    String id,
    JobApplicationStatus status,
  ) async {
    final current = await getApplicationById(id);
    if (current == null) {
      return null;
    }

    final saved = await saveApplication(current.copyWith(status: status));
    return saved;
  }

  Future<void> deleteApplication(String id) async {
    await ref.read(jobApplicationRepositoryProvider).deleteApplication(id);
    final currentData = state.asData?.value;
    if (currentData == null) {
      await reload();
      return;
    }

    final next = <JobApplication>[
      for (final application in currentData)
        if (application.id != id) application,
    ];
    state = AsyncData(next);
  }

  Future<JobApplication?> archiveApplication(String id) {
    return updateStatus(id, JobApplicationStatus.archived);
  }

  Future<void> _replaceAndPublish(JobApplication saved) async {
    final currentData = state.asData?.value;
    if (currentData == null) {
      await reload();
      return;
    }

    final next = <JobApplication>[
      for (final application in currentData)
        if (application.id != saved.id) application,
      saved,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncData(next);
  }
}

class JobTrackerSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

class JobTrackerStatusFilterController extends Notifier<JobApplicationStatus?> {
  @override
  JobApplicationStatus? build() => null;

  void setFilter(JobApplicationStatus? value) {
    state = value;
  }

  void clear() {
    state = null;
  }
}

class JobTrackerSummary {
  const JobTrackerSummary({
    required this.total,
    required this.pendingFollowUp,
    required this.interviews,
    required this.offers,
    required this.shortlisted,
  });

  final int total;
  final int pendingFollowUp;
  final int interviews;
  final int offers;
  final int shortlisted;

  factory JobTrackerSummary.fromApplications(
    List<JobApplication> applications,
  ) {
    return JobTrackerSummary(
      total: applications.length,
      pendingFollowUp: applications.where((item) => item.needsFollowUp).length,
      interviews: applications
          .where((item) => item.status == JobApplicationStatus.interview)
          .length,
      offers: applications
          .where((item) => item.status == JobApplicationStatus.offered)
          .length,
      shortlisted: applications
          .where((item) => item.status == JobApplicationStatus.shortlisted)
          .length,
    );
  }
}
