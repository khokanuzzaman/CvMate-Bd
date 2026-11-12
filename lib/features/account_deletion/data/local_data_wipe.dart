import 'dart:developer' as developer;

import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Removes CvMate's data from this device (Hive): CVs, cover letters, job
/// applications, interview sessions, the cached plan and the preferences
/// (including the AI consent, so the next account is asked again).
///
/// The one-free-export counter is kept on purpose: it is not personal data,
/// and resetting it would turn "delete account" into a free-export reset.
/// Each part is best-effort so one failure does not leave the rest.
Future<void> wipeLocalCvMateData(Ref ref) async {
  final steps = <String, Future<void> Function()>{
    'cvs': () => ref.read(cvRepositoryProvider).clearAllCvs(),
    'cover letters': () =>
        ref.read(coverLetterRepositoryProvider).clearAllDrafts(),
    'job applications': () =>
        ref.read(jobApplicationRepositoryProvider).clearAllApplications(),
    'interview sessions': () =>
        ref.read(interviewPrepSessionRepositoryProvider).clearAllSessions(),
    'plan cache': () => ref.read(aiEntitlementCacheProvider).clear(),
    'preferences': () => ref
        .read(settingsRepositoryProvider)
        .savePreferences(const AppPreferences.defaults()),
  };
  for (final MapEntry(:key, :value) in steps.entries) {
    try {
      await value();
    } catch (error) {
      developer.log(
        'Could not clear $key (${error.runtimeType}).',
        name: 'cvmate.account',
      );
    }
  }
  ref
    ..invalidate(cvLibraryControllerProvider)
    ..invalidate(cvBuilderControllerProvider)
    ..invalidate(jobTrackerControllerProvider)
    ..invalidate(coverLetterControllerProvider)
    ..invalidate(interviewPrepControllerProvider)
    ..invalidate(appPreferencesControllerProvider)
    ..invalidate(settingsOverviewControllerProvider)
    ..invalidate(aiEntitlementProvider);
}
