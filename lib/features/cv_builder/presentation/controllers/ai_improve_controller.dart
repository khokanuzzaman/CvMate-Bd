import 'dart:async';

import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiImproveControllerProvider =
    NotifierProvider<AiImproveController, AiImproveState>(
      AiImproveController.new,
    );

class AiImproveController extends Notifier<AiImproveState> {
  @override
  AiImproveState build() => AiImproveState.initial();

  Future<void> initialize({bool force = false}) async {
    if (state.hasInitialized && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final activeDraftState = ref.read(cvBuilderControllerProvider);
      final activeDraftId = activeDraftState.hasActiveDraft
          ? activeDraftState.draft.id
          : null;

      final selected = _selectInitialCv(cvs, activeDraftId: activeDraftId);
      state = _stateForSelectedCv(
        profile: selected,
        availableCvs: cvs,
        improvementType: state.improvementType,
      ).copyWith(hasInitialized: true, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        errorMessage: 'Could not load saved CVs. Please try again.',
      );
    }
  }

  Future<void> reload() => initialize(force: true);

  void selectCv(String cvId) {
    if (state.selectedCv?.id == cvId) {
      return;
    }

    CvProfile? nextProfile;
    for (final profile in state.availableCvs) {
      if (profile.id == cvId) {
        nextProfile = profile;
        break;
      }
    }

    state = _stateForSelectedCv(
      profile: nextProfile,
      availableCvs: state.availableCvs,
      improvementType: state.improvementType,
    );
  }

  void selectImprovementType(AiImproveType type) {
    if (type == state.improvementType) {
      return;
    }

    state = _stateForSelectedCv(
      profile: state.selectedCv,
      availableCvs: state.availableCvs,
      improvementType: type,
      outputLanguage: state.outputLanguage,
      tone: state.tone,
    );
  }

  void selectOutputLanguage(AiOutputLanguage language) {
    if (language == state.outputLanguage) {
      return;
    }

    state = state.copyWith(outputLanguage: language);
  }

  void selectTone(AiTone tone) {
    if (tone == state.tone) {
      return;
    }

    state = state.copyWith(tone: tone);
  }

  void selectExperience(String experienceId) {
    if (state.selectedExperienceId == experienceId) {
      return;
    }

    final experience = _findExperience(state.selectedCv, experienceId);
    final firstBullet = _bulletText(experience, 0);
    state = state.copyWith(
      selectedExperienceId: experienceId,
      selectedExperienceBulletIndex: 0,
      currentInput: firstBullet,
      generatedOutput: '',
      skillSuggestions: const [],
      selectedSuggestedSkills: const <String>{},
      clearErrorMessage: true,
    );
  }

  void selectExperienceBulletIndex(int index) {
    if (index == state.selectedExperienceBulletIndex) {
      return;
    }

    final bulletText = _bulletText(state.selectedExperience, index);
    state = state.copyWith(
      selectedExperienceBulletIndex: index,
      currentInput: bulletText,
      generatedOutput: '',
      skillSuggestions: const [],
      selectedSuggestedSkills: const <String>{},
      clearErrorMessage: true,
    );
  }

  void selectProject(String projectId) {
    if (state.selectedProjectId == projectId) {
      return;
    }

    final project = _findProject(state.selectedCv, projectId);
    state = state.copyWith(
      selectedProjectId: projectId,
      currentInput: project?.description ?? '',
      generatedOutput: '',
      skillSuggestions: const [],
      selectedSuggestedSkills: const <String>{},
      clearErrorMessage: true,
    );
  }

  void updateCurrentInput(String value) {
    if (value == state.currentInput) {
      return;
    }

    state = state.copyWith(currentInput: value, clearErrorMessage: true);
  }

  void updateGeneratedOutput(String value) {
    if (value == state.generatedOutput) {
      return;
    }

    state = state.copyWith(generatedOutput: value, clearErrorMessage: true);
  }

  void toggleSkillSelection(String skillName) {
    final nextSelection = Set<String>.from(state.selectedSuggestedSkills);
    if (nextSelection.contains(skillName)) {
      nextSelection.remove(skillName);
    } else {
      nextSelection.add(skillName);
    }

    final orderedSelection = [
      for (final suggestion in state.skillSuggestions)
        if (nextSelection.contains(suggestion.name)) suggestion.name,
    ];

    state = state.copyWith(
      selectedSuggestedSkills: nextSelection,
      generatedOutput: orderedSelection.join('\n'),
      clearErrorMessage: true,
    );
  }

  Future<void> generateSuggestion() async {
    final selectedCv = state.selectedCv;
    if (selectedCv == null) {
      state = state.copyWith(
        errorMessage: 'Create or select a CV first before generating.',
      );
      return;
    }

    if (!_canGenerateForCurrentType()) {
      state = state.copyWith(
        errorMessage: state.improvementType.emptyRequirementMessage,
      );
      return;
    }

    state = state.copyWith(isGenerating: true, clearErrorMessage: true);
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.aiActionUsed,
        params: {AnalyticsEvents.paramAction: state.improvementType.name},
      ),
    );
    final aiService = ref.read(aiCareerServiceProvider);

    switch (state.improvementType) {
      case AiImproveType.professionalSummary:
        final result = await aiService.generateProfessionalSummary(
          profile: selectedCv.copyWith(
            professionalSummary: state.currentInput.trim(),
          ),
          language: state.outputLanguage,
          tone: state.tone,
          jobTitle: selectedCv.personalInfo.desiredRole,
        );
        _handleTextSuggestionResult(result);
        break;
      case AiImproveType.careerObjective:
        final result = await aiService.generateCareerObjective(
          profile: selectedCv.copyWith(
            careerObjective: state.currentInput.trim(),
          ),
          language: state.outputLanguage,
          tone: state.tone,
          jobTitle: selectedCv.personalInfo.desiredRole,
        );
        _handleTextSuggestionResult(result);
        break;
      case AiImproveType.experienceBullet:
        final experience = state.selectedExperience;
        final result = await aiService.improveExperienceBullet(
          bullet: state.currentInput.trim(),
          profile: selectedCv,
          language: state.outputLanguage,
          tone: state.tone,
          companyName: experience?.companyName ?? '',
          jobTitle: experience?.jobTitle ?? selectedCv.displayRole,
        );
        _handleTextSuggestionResult(result);
        break;
      case AiImproveType.projectDescription:
        final project = state.selectedProject;
        if (project == null) {
          state = state.copyWith(
            isGenerating: false,
            errorMessage: 'Select a project first before generating.',
          );
          return;
        }
        final result = await aiService.improveProjectDescription(
          project: project.copyWith(description: state.currentInput.trim()),
          profile: selectedCv,
          language: state.outputLanguage,
          tone: state.tone,
        );
        _handleTextSuggestionResult(result);
        break;
      case AiImproveType.skillsSuggestion:
        final result = await aiService.suggestSkills(
          profile: selectedCv,
          language: state.outputLanguage,
          tone: state.tone,
          jobTitle: selectedCv.personalInfo.desiredRole,
          jobPostText: state.currentInput.trim(),
        );
        _handleSkillSuggestionResult(result);
        break;
    }
  }

  Future<String?> copyOutput() async {
    final output = state.generatedOutput.trim();
    if (output.isEmpty) {
      return 'Generate a suggestion first.';
    }

    await Clipboard.setData(ClipboardData(text: output));
    return 'Copied to clipboard.';
  }

  Future<String?> applySuggestion() async {
    return _persistSuggestion(successMessage: 'AI suggestion applied to CV.');
  }

  Future<String?> saveAsDraft() async {
    return _persistSuggestion(successMessage: 'Draft saved.');
  }

  void _handleTextSuggestionResult(Result<AiTextSuggestion> result) {
    result.when(
      success: (data) {
        state = state.copyWith(
          isGenerating: false,
          generatedOutput: data.suggestedText,
          skillSuggestions: const [],
          selectedSuggestedSkills: const <String>{},
          clearErrorMessage: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  void _handleSkillSuggestionResult(Result<List<SkillSuggestion>> result) {
    result.when(
      success: (data) {
        final Set<String> selectedSkills = {for (final item in data) item.name};
        state = state.copyWith(
          isGenerating: false,
          skillSuggestions: data,
          selectedSuggestedSkills: selectedSkills,
          generatedOutput: data.map((item) => item.name).join('\n'),
          clearErrorMessage: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<String?> _persistSuggestion({required String successMessage}) async {
    final selectedCv = state.selectedCv;
    if (selectedCv == null) {
      state = state.copyWith(
        errorMessage: 'Create or select a CV first before saving changes.',
      );
      return state.errorMessage;
    }

    if (state.generatedOutput.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Generate a suggestion first.');
      return state.errorMessage;
    }

    if (!_canGenerateForCurrentType()) {
      state = state.copyWith(
        errorMessage: state.improvementType.emptyRequirementMessage,
      );
      return state.errorMessage;
    }

    final updatedProfile = _applySuggestionToProfile(selectedCv);
    if (updatedProfile == null) {
      return state.errorMessage;
    }

    try {
      final saved = await ref.read(cvRepositoryProvider).saveCv(updatedProfile);
      ref.invalidate(cvLibraryControllerProvider);
      ref.read(cvBuilderControllerProvider.notifier).syncExternalDraft(saved);

      final refreshedList = _replaceProfile(state.availableCvs, saved)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = _stateForSelectedCv(
        profile: saved,
        availableCvs: refreshedList,
        improvementType: state.improvementType,
        outputLanguage: state.outputLanguage,
        tone: state.tone,
        preserveCurrentInput: true,
        currentInputOverride: _currentInputForAppliedProfile(saved),
        generatedOutputOverride: state.generatedOutput,
        skillSuggestionsOverride: state.skillSuggestions,
        selectedSuggestedSkillsOverride: state.selectedSuggestedSkills,
      );

      return successMessage;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Draft save failed. Please try again.',
      );
      return state.errorMessage;
    }
  }

  CvProfile? _applySuggestionToProfile(CvProfile profile) {
    final output = state.generatedOutput.trim();

    switch (state.improvementType) {
      case AiImproveType.professionalSummary:
        return profile.copyWith(professionalSummary: output);
      case AiImproveType.careerObjective:
        return profile.copyWith(careerObjective: output);
      case AiImproveType.experienceBullet:
        final experience = state.selectedExperience;
        if (experience == null) {
          state = state.copyWith(
            errorMessage: 'Select an experience entry before applying.',
          );
          return null;
        }

        final updatedHighlights = List<String>.from(experience.highlights);
        if (updatedHighlights.isEmpty) {
          updatedHighlights.add(output);
        } else {
          final index = state.selectedExperienceBulletIndex.clamp(
            0,
            updatedHighlights.length - 1,
          );
          updatedHighlights[index] = output;
        }

        final updatedExperience = experience.copyWith(
          highlights: updatedHighlights,
        );
        return profile.copyWith(
          experiences: [
            for (final item in profile.experiences)
              if (item.id == updatedExperience.id) updatedExperience else item,
          ],
        );
      case AiImproveType.projectDescription:
        final project = state.selectedProject;
        if (project == null) {
          state = state.copyWith(
            errorMessage: 'Select a project before applying.',
          );
          return null;
        }

        final updatedProject = project.copyWith(description: output);
        return profile.copyWith(
          projects: [
            for (final item in profile.projects)
              if (item.id == updatedProject.id) updatedProject else item,
          ],
        );
      case AiImproveType.skillsSuggestion:
        final skillNames = _parseSkillOutput(output);
        if (skillNames.isEmpty) {
          state = state.copyWith(
            errorMessage: 'Select or write at least one skill before applying.',
          );
          return null;
        }

        final existingSkills = {
          for (final skill in profile.skills) skill.name.trim().toLowerCase(),
        };
        final nextSkills = List<SkillInfo>.from(profile.skills);

        for (final skillName in skillNames) {
          final normalized = skillName.toLowerCase();
          if (existingSkills.contains(normalized)) {
            continue;
          }

          existingSkills.add(normalized);
          nextSkills.add(
            SkillInfo.empty().copyWith(name: skillName, level: 'Suggested'),
          );
        }

        return profile.copyWith(skills: nextSkills);
    }
  }

  bool _canGenerateForCurrentType() {
    final profile = state.selectedCv;
    if (profile == null) {
      return false;
    }

    return switch (state.improvementType) {
      AiImproveType.experienceBullet => profile.experiences.isNotEmpty,
      AiImproveType.projectDescription => profile.projects.isNotEmpty,
      _ => true,
    };
  }

  AiImproveState _stateForSelectedCv({
    required CvProfile? profile,
    required List<CvProfile> availableCvs,
    required AiImproveType improvementType,
    AiOutputLanguage? outputLanguage,
    AiTone? tone,
    bool preserveCurrentInput = false,
    String? currentInputOverride,
    String? generatedOutputOverride,
    List<SkillSuggestion>? skillSuggestionsOverride,
    Set<String>? selectedSuggestedSkillsOverride,
  }) {
    final selectedExperienceId = _defaultExperienceId(profile, improvementType);
    final selectedProjectId = _defaultProjectId(profile, improvementType);
    final nextCurrentInput =
        currentInputOverride ??
        (preserveCurrentInput
            ? state.currentInput
            : _defaultInputForType(
                profile,
                improvementType,
                selectedExperienceId: selectedExperienceId,
                selectedProjectId: selectedProjectId,
                bulletIndex: 0,
              ));

    return state.copyWith(
      availableCvs: availableCvs,
      selectedCv: profile,
      improvementType: improvementType,
      outputLanguage: outputLanguage ?? state.outputLanguage,
      tone: tone ?? state.tone,
      selectedExperienceId: selectedExperienceId,
      selectedExperienceBulletIndex: 0,
      selectedProjectId: selectedProjectId,
      currentInput: nextCurrentInput,
      generatedOutput: generatedOutputOverride ?? '',
      skillSuggestions: skillSuggestionsOverride ?? const [],
      selectedSuggestedSkills:
          selectedSuggestedSkillsOverride ?? const <String>{},
      clearErrorMessage: true,
    );
  }

  CvProfile? _selectInitialCv(List<CvProfile> cvs, {String? activeDraftId}) {
    if (cvs.isEmpty) {
      return null;
    }

    if (activeDraftId != null) {
      for (final profile in cvs) {
        if (profile.id == activeDraftId) {
          return profile;
        }
      }
    }

    return cvs.first;
  }

  String? _defaultExperienceId(CvProfile? profile, AiImproveType type) {
    if (profile == null || !type.needsExperienceSelection) {
      return null;
    }

    return profile.experiences.isEmpty ? null : profile.experiences.first.id;
  }

  String? _defaultProjectId(CvProfile? profile, AiImproveType type) {
    if (profile == null || !type.needsProjectSelection) {
      return null;
    }

    return profile.projects.isEmpty ? null : profile.projects.first.id;
  }

  String _defaultInputForType(
    CvProfile? profile,
    AiImproveType type, {
    String? selectedExperienceId,
    String? selectedProjectId,
    required int bulletIndex,
  }) {
    if (profile == null) {
      return '';
    }

    return switch (type) {
      AiImproveType.professionalSummary => profile.professionalSummary,
      AiImproveType.careerObjective => profile.careerObjective,
      AiImproveType.experienceBullet => _bulletText(
        _findExperience(profile, selectedExperienceId),
        bulletIndex,
      ),
      AiImproveType.projectDescription =>
        _findProject(profile, selectedProjectId)?.description ?? '',
      AiImproveType.skillsSuggestion => profile.personalInfo.desiredRole,
    };
  }

  String _currentInputForAppliedProfile(CvProfile profile) {
    return switch (state.improvementType) {
      AiImproveType.professionalSummary => profile.professionalSummary,
      AiImproveType.careerObjective => profile.careerObjective,
      AiImproveType.experienceBullet => _bulletText(
        _findExperience(profile, state.selectedExperienceId),
        state.selectedExperienceBulletIndex,
      ),
      AiImproveType.projectDescription =>
        _findProject(profile, state.selectedProjectId)?.description ?? '',
      AiImproveType.skillsSuggestion => state.currentInput,
    };
  }

  ExperienceInfo? _findExperience(CvProfile? profile, String? id) {
    if (profile == null || id == null) {
      return null;
    }

    for (final item in profile.experiences) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  ProjectInfo? _findProject(CvProfile? profile, String? id) {
    if (profile == null || id == null) {
      return null;
    }

    for (final item in profile.projects) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  String _bulletText(ExperienceInfo? experience, int index) {
    if (experience == null || experience.highlights.isEmpty) {
      return '';
    }

    final safeIndex = index.clamp(0, experience.highlights.length - 1);
    return experience.highlights[safeIndex];
  }

  List<CvProfile> _replaceProfile(
    List<CvProfile> source,
    CvProfile nextProfile,
  ) {
    return [
      for (final profile in source)
        if (profile.id == nextProfile.id) nextProfile else profile,
    ];
  }

  List<String> _parseSkillOutput(String output) {
    final values = output
        .split(RegExp(r'[\n,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return values.toSet().toList();
  }
}
