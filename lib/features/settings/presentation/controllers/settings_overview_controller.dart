import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final packageInfoLoaderProvider = Provider<Future<PackageInfo> Function()>((
  ref,
) {
  return PackageInfo.fromPlatform;
});

class SettingsOverviewState {
  const SettingsOverviewState({
    required this.cvCount,
    required this.coverLetterCount,
    required this.jobApplicationCount,
    required this.interviewPrepSessionCount,
    required this.versionName,
    required this.buildNumber,
    required this.isClearingLocalData,
  });

  const SettingsOverviewState.initial()
    : cvCount = 0,
      coverLetterCount = 0,
      jobApplicationCount = 0,
      interviewPrepSessionCount = 0,
      versionName = 'Unknown',
      buildNumber = '',
      isClearingLocalData = false;

  final int cvCount;
  final int coverLetterCount;
  final int jobApplicationCount;
  final int interviewPrepSessionCount;
  final String versionName;
  final String buildNumber;
  final bool isClearingLocalData;

  String get versionLabel =>
      buildNumber.trim().isEmpty ? versionName : '$versionName ($buildNumber)';

  SettingsOverviewState copyWith({
    int? cvCount,
    int? coverLetterCount,
    int? jobApplicationCount,
    int? interviewPrepSessionCount,
    String? versionName,
    String? buildNumber,
    bool? isClearingLocalData,
  }) {
    return SettingsOverviewState(
      cvCount: cvCount ?? this.cvCount,
      coverLetterCount: coverLetterCount ?? this.coverLetterCount,
      jobApplicationCount: jobApplicationCount ?? this.jobApplicationCount,
      interviewPrepSessionCount:
          interviewPrepSessionCount ?? this.interviewPrepSessionCount,
      versionName: versionName ?? this.versionName,
      buildNumber: buildNumber ?? this.buildNumber,
      isClearingLocalData: isClearingLocalData ?? this.isClearingLocalData,
    );
  }
}

final settingsOverviewControllerProvider =
    AsyncNotifierProvider<SettingsOverviewController, SettingsOverviewState>(
      SettingsOverviewController.new,
    );

class SettingsOverviewController extends AsyncNotifier<SettingsOverviewState> {
  @override
  Future<SettingsOverviewState> build() async {
    return _loadOverview();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadOverview);
  }

  Future<String?> clearAllLocalCareerData() async {
    final current =
        state.asData?.value ?? const SettingsOverviewState.initial();
    state = AsyncData(current.copyWith(isClearingLocalData: true));

    try {
      await ref.read(cvRepositoryProvider).clearAllCvs();
      await ref.read(coverLetterRepositoryProvider).clearAllDrafts();
      await ref.read(jobApplicationRepositoryProvider).clearAllApplications();
      await ref.read(interviewPrepSessionRepositoryProvider).clearAllSessions();

      ref.invalidate(cvLibraryControllerProvider);
      ref.invalidate(cvBuilderControllerProvider);
      ref.invalidate(jobTrackerControllerProvider);
      ref.invalidate(coverLetterControllerProvider);
      ref.invalidate(interviewPrepControllerProvider);

      final refreshed = await _loadOverview();
      state = AsyncData(refreshed);
      return 'Local career data cleared. Theme and language preferences were kept.';
    } catch (_) {
      state = AsyncData(current.copyWith(isClearingLocalData: false));
      return 'Could not clear local data right now.';
    }
  }

  Future<SettingsOverviewState> _loadOverview() async {
    final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
    final drafts = await ref.read(coverLetterRepositoryProvider).getAllDrafts();
    final applications = await ref
        .read(jobApplicationRepositoryProvider)
        .getAllApplications();
    final interviewSessions = await ref
        .read(interviewPrepSessionRepositoryProvider)
        .getAllSessions();
    final packageInfo = await ref.read(packageInfoLoaderProvider)();

    return SettingsOverviewState(
      cvCount: cvs.length,
      coverLetterCount: drafts.length,
      jobApplicationCount: applications.length,
      interviewPrepSessionCount: interviewSessions.length,
      versionName: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      isClearingLocalData: false,
    );
  }
}
