import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AiImproveState {
  const AiImproveState({
    required this.hasInitialized,
    required this.isLoading,
    required this.isGenerating,
    required this.availableCvs,
    required this.selectedCv,
    required this.improvementType,
    required this.outputLanguage,
    required this.tone,
    required this.currentInput,
    required this.generatedOutput,
    required this.selectedExperienceId,
    required this.selectedExperienceBulletIndex,
    required this.selectedProjectId,
    required this.skillSuggestions,
    required this.selectedSuggestedSkills,
    required this.errorMessage,
  });

  factory AiImproveState.initial() => const AiImproveState(
    hasInitialized: false,
    isLoading: false,
    isGenerating: false,
    availableCvs: [],
    selectedCv: null,
    improvementType: AiImproveType.professionalSummary,
    outputLanguage: AiOutputLanguage.english,
    tone: AiTone.professional,
    currentInput: '',
    generatedOutput: '',
    selectedExperienceId: null,
    selectedExperienceBulletIndex: 0,
    selectedProjectId: null,
    skillSuggestions: [],
    selectedSuggestedSkills: <String>{},
    errorMessage: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final bool isGenerating;
  final List<CvProfile> availableCvs;
  final CvProfile? selectedCv;
  final AiImproveType improvementType;
  final AiOutputLanguage outputLanguage;
  final AiTone tone;
  final String currentInput;
  final String generatedOutput;
  final String? selectedExperienceId;
  final int selectedExperienceBulletIndex;
  final String? selectedProjectId;
  final List<SkillSuggestion> skillSuggestions;
  final Set<String> selectedSuggestedSkills;
  final String? errorMessage;

  bool get hasSavedCvs => availableCvs.isNotEmpty;
  bool get hasSelectedCv => selectedCv != null;
  bool get hasGeneratedOutput =>
      generatedOutput.trim().isNotEmpty || skillSuggestions.isNotEmpty;

  ExperienceInfo? get selectedExperience {
    final profile = selectedCv;
    if (profile == null || selectedExperienceId == null) {
      return null;
    }

    for (final item in profile.experiences) {
      if (item.id == selectedExperienceId) {
        return item;
      }
    }

    return null;
  }

  ProjectInfo? get selectedProject {
    final profile = selectedCv;
    if (profile == null || selectedProjectId == null) {
      return null;
    }

    for (final item in profile.projects) {
      if (item.id == selectedProjectId) {
        return item;
      }
    }

    return null;
  }

  AiImproveState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    bool? isGenerating,
    List<CvProfile>? availableCvs,
    CvProfile? selectedCv,
    bool clearSelectedCv = false,
    AiImproveType? improvementType,
    AiOutputLanguage? outputLanguage,
    AiTone? tone,
    String? currentInput,
    String? generatedOutput,
    String? selectedExperienceId,
    bool clearSelectedExperienceId = false,
    int? selectedExperienceBulletIndex,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
    List<SkillSuggestion>? skillSuggestions,
    Set<String>? selectedSuggestedSkills,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AiImproveState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      availableCvs: availableCvs ?? this.availableCvs,
      selectedCv: clearSelectedCv ? null : selectedCv ?? this.selectedCv,
      improvementType: improvementType ?? this.improvementType,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      tone: tone ?? this.tone,
      currentInput: currentInput ?? this.currentInput,
      generatedOutput: generatedOutput ?? this.generatedOutput,
      selectedExperienceId: clearSelectedExperienceId
          ? null
          : selectedExperienceId ?? this.selectedExperienceId,
      selectedExperienceBulletIndex:
          selectedExperienceBulletIndex ?? this.selectedExperienceBulletIndex,
      selectedProjectId: clearSelectedProjectId
          ? null
          : selectedProjectId ?? this.selectedProjectId,
      skillSuggestions: skillSuggestions ?? this.skillSuggestions,
      selectedSuggestedSkills:
          selectedSuggestedSkills ?? this.selectedSuggestedSkills,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
