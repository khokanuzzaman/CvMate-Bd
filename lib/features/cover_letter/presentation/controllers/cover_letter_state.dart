import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

const Object _coverLetterStateUnset = Object();

class CoverLetterState {
  const CoverLetterState({
    required this.hasInitialized,
    required this.isLoading,
    required this.isGenerating,
    required this.availableCvs,
    required this.recentDrafts,
    required this.activeDraftId,
    required this.activeDraftCreatedAt,
    required this.selectedCvId,
    required this.outputType,
    required this.language,
    required this.tone,
    required this.targetCompany,
    required this.jobTitle,
    required this.jobDetails,
    required this.hiringManagerName,
    required this.candidateSummary,
    required this.subjectLine,
    required this.generatedContent,
    required this.errorMessage,
  });

  factory CoverLetterState.initial() => CoverLetterState(
    hasInitialized: false,
    isLoading: false,
    isGenerating: false,
    availableCvs: const [],
    recentDrafts: const [],
    activeDraftId: null,
    activeDraftCreatedAt: null,
    selectedCvId: null,
    outputType: CoverLetterOutputType.formalCoverLetter,
    language: AiOutputLanguage.english,
    tone: AiTone.formal,
    targetCompany: '',
    jobTitle: '',
    jobDetails: '',
    hiringManagerName: '',
    candidateSummary: '',
    subjectLine: '',
    generatedContent: '',
    errorMessage: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final bool isGenerating;
  final List<CvProfile> availableCvs;
  final List<CoverLetterDraft> recentDrafts;
  final String? activeDraftId;
  final DateTime? activeDraftCreatedAt;
  final String? selectedCvId;
  final CoverLetterOutputType outputType;
  final AiOutputLanguage language;
  final AiTone tone;
  final String targetCompany;
  final String jobTitle;
  final String jobDetails;
  final String hiringManagerName;
  final String candidateSummary;
  final String subjectLine;
  final String generatedContent;
  final String? errorMessage;

  CvProfile? get selectedCv {
    final id = selectedCvId;
    if (id == null) {
      return null;
    }

    for (final profile in availableCvs) {
      if (profile.id == id) {
        return profile;
      }
    }

    return null;
  }

  bool get hasSavedCvs => availableCvs.isNotEmpty;
  bool get hasRecentDrafts => recentDrafts.isNotEmpty;
  bool get hasGeneratedContent => generatedContent.trim().isNotEmpty;
  bool get isEditingSavedDraft => activeDraftId != null;

  CoverLetterState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    bool? isGenerating,
    List<CvProfile>? availableCvs,
    List<CoverLetterDraft>? recentDrafts,
    Object? activeDraftId = _coverLetterStateUnset,
    Object? activeDraftCreatedAt = _coverLetterStateUnset,
    Object? selectedCvId = _coverLetterStateUnset,
    CoverLetterOutputType? outputType,
    AiOutputLanguage? language,
    AiTone? tone,
    String? targetCompany,
    String? jobTitle,
    String? jobDetails,
    String? hiringManagerName,
    String? candidateSummary,
    String? subjectLine,
    String? generatedContent,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CoverLetterState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      availableCvs: availableCvs ?? this.availableCvs,
      recentDrafts: recentDrafts ?? this.recentDrafts,
      activeDraftId: identical(activeDraftId, _coverLetterStateUnset)
          ? this.activeDraftId
          : activeDraftId as String?,
      activeDraftCreatedAt:
          identical(activeDraftCreatedAt, _coverLetterStateUnset)
          ? this.activeDraftCreatedAt
          : activeDraftCreatedAt as DateTime?,
      selectedCvId: identical(selectedCvId, _coverLetterStateUnset)
          ? this.selectedCvId
          : selectedCvId as String?,
      outputType: outputType ?? this.outputType,
      language: language ?? this.language,
      tone: tone ?? this.tone,
      targetCompany: targetCompany ?? this.targetCompany,
      jobTitle: jobTitle ?? this.jobTitle,
      jobDetails: jobDetails ?? this.jobDetails,
      hiringManagerName: hiringManagerName ?? this.hiringManagerName,
      candidateSummary: candidateSummary ?? this.candidateSummary,
      subjectLine: subjectLine ?? this.subjectLine,
      generatedContent: generatedContent ?? this.generatedContent,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
