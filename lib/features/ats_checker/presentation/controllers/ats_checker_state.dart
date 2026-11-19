import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';

/// Where the job post used for matching came from.
enum AtsJobPostSource {
  /// No job post, and the user has not cleared one here.
  none,

  /// Taken from Tailor; follows Tailor's post on the next visit.
  tailor,

  /// Typed or pasted on this screen; kept as is.
  typed,

  /// Cleared on this screen; Tailor's post is not taken again.
  cleared,
}

class AtsCheckerState {
  const AtsCheckerState({
    required this.hasInitialized,
    required this.isLoading,
    required this.isCheckingJobMatch,
    required this.isGeneratingAiSuggestion,
    required this.hasCheckedJobMatch,
    required this.availableCvs,
    required this.selectedCvId,
    required this.jobPostText,
    this.jobPostSource = AtsJobPostSource.none,
    required this.report,
    required this.jobMatchReport,
    required this.aiTarget,
    required this.aiSuggestionText,
    required this.errorMessage,
  });

  factory AtsCheckerState.initial() => const AtsCheckerState(
    hasInitialized: false,
    isLoading: false,
    isCheckingJobMatch: false,
    isGeneratingAiSuggestion: false,
    hasCheckedJobMatch: false,
    availableCvs: [],
    selectedCvId: null,
    jobPostText: '',
    report: null,
    jobMatchReport: null,
    aiTarget: AtsAiTarget.professionalSummary,
    aiSuggestionText: '',
    errorMessage: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final bool isCheckingJobMatch;
  final bool isGeneratingAiSuggestion;
  final bool hasCheckedJobMatch;
  final List<CvProfile> availableCvs;
  final String? selectedCvId;
  final String jobPostText;
  final AtsJobPostSource jobPostSource;
  final AtsCheckReport? report;
  final AtsJobMatchReport? jobMatchReport;
  final AtsAiTarget aiTarget;
  final String aiSuggestionText;
  final String? errorMessage;

  CvProfile? get selectedCv {
    final id = selectedCvId;
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
  bool get hasAiSuggestion => aiSuggestionText.trim().isNotEmpty;
  bool get hasJobPost => jobPostText.trim().isNotEmpty;

  AtsCheckerState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    bool? isCheckingJobMatch,
    bool? isGeneratingAiSuggestion,
    bool? hasCheckedJobMatch,
    List<CvProfile>? availableCvs,
    String? selectedCvId,
    bool clearSelectedCvId = false,
    String? jobPostText,
    AtsJobPostSource? jobPostSource,
    AtsCheckReport? report,
    bool clearReport = false,
    AtsJobMatchReport? jobMatchReport,
    bool clearJobMatchReport = false,
    AtsAiTarget? aiTarget,
    String? aiSuggestionText,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AtsCheckerState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      isCheckingJobMatch: isCheckingJobMatch ?? this.isCheckingJobMatch,
      isGeneratingAiSuggestion:
          isGeneratingAiSuggestion ?? this.isGeneratingAiSuggestion,
      hasCheckedJobMatch: hasCheckedJobMatch ?? this.hasCheckedJobMatch,
      availableCvs: availableCvs ?? this.availableCvs,
      selectedCvId: clearSelectedCvId
          ? null
          : selectedCvId ?? this.selectedCvId,
      jobPostText: jobPostText ?? this.jobPostText,
      jobPostSource: jobPostSource ?? this.jobPostSource,
      report: clearReport ? null : report ?? this.report,
      jobMatchReport: clearJobMatchReport
          ? null
          : jobMatchReport ?? this.jobMatchReport,
      aiTarget: aiTarget ?? this.aiTarget,
      aiSuggestionText: aiSuggestionText ?? this.aiSuggestionText,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
