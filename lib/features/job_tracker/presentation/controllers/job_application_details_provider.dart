import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobApplicationDetailsProvider =
    FutureProvider.family<JobApplicationDetailsData?, String>((ref, id) async {
      final application = await ref
          .read(jobApplicationRepositoryProvider)
          .getApplicationById(id);
      if (application == null) {
        return null;
      }

      final cv = application.cvId == null
          ? null
          : await ref.read(cvRepositoryProvider).getCvById(application.cvId!);
      final coverLetter = application.coverLetterId == null
          ? null
          : await ref
                .read(coverLetterRepositoryProvider)
                .getDraftById(application.coverLetterId!);

      return JobApplicationDetailsData(
        application: application,
        cv: cv,
        coverLetter: coverLetter,
      );
    });

class JobApplicationDetailsData {
  const JobApplicationDetailsData({
    required this.application,
    required this.cv,
    required this.coverLetter,
  });

  final JobApplication application;
  final CvProfile? cv;
  final CoverLetterDraft? coverLetter;
}
