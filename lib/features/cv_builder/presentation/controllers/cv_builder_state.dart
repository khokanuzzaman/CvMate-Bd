import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';

class CvBuilderState {
  const CvBuilderState({
    required this.draft,
    required this.currentStepIndex,
    required this.showValidationErrors,
    required this.hasInitializedDraft,
    required this.isLoading,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.lastSavedAt,
    required this.errorMessage,
  });

  factory CvBuilderState.initial() => CvBuilderState(
    draft: CvProfile.empty(),
    currentStepIndex: 0,
    showValidationErrors: false,
    hasInitializedDraft: false,
    isLoading: false,
    isSaving: false,
    hasUnsavedChanges: false,
    lastSavedAt: null,
    errorMessage: null,
  );

  final CvProfile draft;
  final int currentStepIndex;
  final bool showValidationErrors;
  final bool hasInitializedDraft;
  final bool isLoading;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final DateTime? lastSavedAt;
  final String? errorMessage;

  CvBuilderStep get currentStep => CvBuilderStep.values[currentStepIndex];
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == CvBuilderStep.values.length - 1;
  bool get hasActiveDraft => hasInitializedDraft;

  CvBuilderState copyWith({
    CvProfile? draft,
    int? currentStepIndex,
    bool? showValidationErrors,
    bool? hasInitializedDraft,
    bool? isLoading,
    bool? isSaving,
    bool? hasUnsavedChanges,
    DateTime? lastSavedAt,
    bool clearLastSavedAt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CvBuilderState(
      draft: draft ?? this.draft,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      hasInitializedDraft: hasInitializedDraft ?? this.hasInitializedDraft,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSavedAt: clearLastSavedAt ? null : lastSavedAt ?? this.lastSavedAt,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
