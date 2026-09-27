import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/tailoring/domain/entities/tailoring_result.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';

/// Minimum job-post length before analysis/tailoring is allowed.
const int kMinJobPostLength = 30;

class TailoringState {
  const TailoringState({
    required this.hasInitialized,
    required this.isLoading,
    required this.stage,
    required this.availableCvs,
    required this.cvId,
    required this.jobTitle,
    required this.company,
    required this.jobPostText,
    required this.matchReport,
    required this.result,
    required this.savedCvId,
    required this.failure,
  });

  factory TailoringState.initial() => const TailoringState(
    hasInitialized: false,
    isLoading: false,
    stage: TailoringStage.idle,
    availableCvs: [],
    cvId: null,
    jobTitle: '',
    company: '',
    jobPostText: '',
    matchReport: null,
    result: null,
    savedCvId: null,
    failure: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final TailoringStage stage;
  final List<CvProfile> availableCvs;
  final String? cvId;
  final String jobTitle;
  final String company;
  final String jobPostText;
  final AtsJobMatchReport? matchReport;
  final TailoringResult? result;
  final String? savedCvId;
  final Failure? failure;

  CvProfile? get selectedCv {
    final id = cvId;
    if (id == null) {
      return null;
    }

    for (final cv in availableCvs) {
      if (cv.id == id) {
        return cv;
      }
    }
    return null;
  }

  bool get hasSavedCvs => availableCvs.isNotEmpty;
  bool get hasMatchReport => matchReport != null;
  bool get hasResult => result != null;
  bool get isBusy => stage.isBusy;
  bool get hasJobPost => jobPostText.trim().length >= kMinJobPostLength;
  bool get canAnalyze => selectedCv != null && hasJobPost && !isBusy;
  String? get errorMessage => failure?.message;

  TailoringState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    TailoringStage? stage,
    List<CvProfile>? availableCvs,
    String? cvId,
    bool clearCvId = false,
    String? jobTitle,
    String? company,
    String? jobPostText,
    AtsJobMatchReport? matchReport,
    bool clearMatchReport = false,
    TailoringResult? result,
    bool clearResult = false,
    String? savedCvId,
    bool clearSavedCvId = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return TailoringState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      stage: stage ?? this.stage,
      availableCvs: availableCvs ?? this.availableCvs,
      cvId: clearCvId ? null : cvId ?? this.cvId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      jobPostText: jobPostText ?? this.jobPostText,
      matchReport: clearMatchReport ? null : matchReport ?? this.matchReport,
      result: clearResult ? null : result ?? this.result,
      savedCvId: clearSavedCvId ? null : savedCvId ?? this.savedCvId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
