import 'dart:async';

import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_validators.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cvBuilderControllerProvider =
    NotifierProvider<CvBuilderController, CvBuilderState>(
      CvBuilderController.new,
    );

class CvBuilderController extends Notifier<CvBuilderState> {
  static const Duration _autosaveDelay = Duration(milliseconds: 800);

  Timer? _autosaveTimer;

  @override
  CvBuilderState build() {
    ref.onDispose(() => _autosaveTimer?.cancel());
    return CvBuilderState.initial();
  }

  Future<void> ensureDraftReady() async {
    if (state.hasActiveDraft || state.isLoading) {
      return;
    }

    await startNewDraft();
  }

  Future<void> startNewDraft({String? title}) async {
    _cancelAutosave();
    state = state.copyWith(
      isLoading: true,
      showValidationErrors: false,
      clearErrorMessage: true,
    );

    try {
      final profile = await ref
          .read(cvRepositoryProvider)
          .createEmptyCv(title: title);
      ref.invalidate(cvLibraryControllerProvider);
      unawaited(
        ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.cvCreated),
      );
      state = state.copyWith(
        draft: profile,
        currentStepIndex: 0,
        showValidationErrors: false,
        hasInitializedDraft: true,
        isLoading: false,
        isSaving: false,
        hasUnsavedChanges: false,
        lastSavedAt: profile.updatedAt,
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not create a new CV draft. Please try again.',
      );
    }
  }

  Future<void> loadDraft(String id, {int stepIndex = 0}) async {
    _cancelAutosave();

    if (state.hasActiveDraft && state.draft.id == id) {
      state = state.copyWith(
        currentStepIndex: _normalizeStepIndex(stepIndex),
        showValidationErrors: false,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      showValidationErrors: false,
      clearErrorMessage: true,
    );

    try {
      final profile = await ref.read(cvRepositoryProvider).getCvById(id);
      if (profile == null) {
        throw Exception('CV not found');
      }

      state = state.copyWith(
        draft: profile,
        currentStepIndex: _normalizeStepIndex(stepIndex),
        showValidationErrors: false,
        hasInitializedDraft: true,
        isLoading: false,
        isSaving: false,
        hasUnsavedChanges: false,
        lastSavedAt: profile.updatedAt,
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not open this CV. Please try again.',
      );
    }
  }

  void clearActiveDraftIfMatches(String id) {
    if (!state.hasActiveDraft || state.draft.id != id) {
      return;
    }

    _cancelAutosave();
    state = CvBuilderState.initial();
  }

  void goToStep(int stepIndex) {
    state = state.copyWith(
      currentStepIndex: _normalizeStepIndex(stepIndex),
      showValidationErrors: false,
    );
  }

  void previousStep() {
    if (state.isFirstStep) {
      return;
    }

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      showValidationErrors: false,
    );
  }

  String? nextStep() {
    final error = validateStep(state.currentStep);
    if (error != null) {
      state = state.copyWith(showValidationErrors: true);
      return error;
    }

    if (!state.isLastStep) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
        showValidationErrors: false,
      );
    }

    return null;
  }

  String? validateStep(CvBuilderStep step) {
    return CvBuilderValidators.validateStep(step, state.draft);
  }

  List<String> previewWarnings() {
    return CvBuilderValidators.buildPreviewWarnings(state.draft);
  }

  Future<void> saveNow() async {
    if (!state.hasActiveDraft || state.isLoading) {
      return;
    }

    _cancelAutosave();

    if (!state.hasUnsavedChanges && state.lastSavedAt != null) {
      return;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final saved = await ref.read(cvRepositoryProvider).saveCv(state.draft);
      ref.invalidate(cvLibraryControllerProvider);
      state = state.copyWith(
        draft: saved,
        hasInitializedDraft: true,
        isSaving: false,
        hasUnsavedChanges: false,
        lastSavedAt: saved.updatedAt,
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Draft save failed. Please try again.',
      );
    }
  }

  Future<void> flushAutosave() => saveNow();

  void syncExternalDraft(CvProfile profile) {
    if (!state.hasActiveDraft || state.draft.id != profile.id) {
      return;
    }

    _cancelAutosave();
    state = state.copyWith(
      draft: profile,
      hasInitializedDraft: true,
      isLoading: false,
      isSaving: false,
      hasUnsavedChanges: false,
      lastSavedAt: profile.updatedAt,
      clearErrorMessage: true,
    );
  }

  void updateTitle(String title) {
    _updateDraft(state.draft.copyWith(title: title));
  }

  void updatePersonalInfo(PersonalInfo personalInfo) {
    _updateDraft(state.draft.copyWith(personalInfo: personalInfo));
  }

  void updateSummary({String? professionalSummary, String? careerObjective}) {
    _updateDraft(
      state.draft.copyWith(
        professionalSummary: professionalSummary,
        careerObjective: careerObjective,
      ),
    );
  }

  void selectTemplate(CvTemplate template) {
    _updateDraft(state.draft.copyWith(template: template));
  }

  void addEducation(EducationInfo educationInfo) {
    _updateDraft(
      state.draft.copyWith(
        education: [...state.draft.education, educationInfo],
      ),
    );
  }

  void updateEducation(EducationInfo educationInfo) {
    _updateDraft(
      state.draft.copyWith(
        education: _replaceById(
          state.draft.education,
          educationInfo.id,
          educationInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeEducation(String id) {
    _updateDraft(
      state.draft.copyWith(
        education: state.draft.education
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void addExperience(ExperienceInfo experienceInfo) {
    _updateDraft(
      state.draft.copyWith(
        experiences: [...state.draft.experiences, experienceInfo],
      ),
    );
  }

  void updateExperience(ExperienceInfo experienceInfo) {
    _updateDraft(
      state.draft.copyWith(
        experiences: _replaceById(
          state.draft.experiences,
          experienceInfo.id,
          experienceInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeExperience(String id) {
    _updateDraft(
      state.draft.copyWith(
        experiences: state.draft.experiences
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void addSkill(SkillInfo skillInfo) {
    _updateDraft(
      state.draft.copyWith(skills: [...state.draft.skills, skillInfo]),
    );
  }

  void updateSkill(SkillInfo skillInfo) {
    _updateDraft(
      state.draft.copyWith(
        skills: _replaceById(
          state.draft.skills,
          skillInfo.id,
          skillInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeSkill(String id) {
    _updateDraft(
      state.draft.copyWith(
        skills: state.draft.skills.where((item) => item.id != id).toList(),
      ),
    );
  }

  void addProject(ProjectInfo projectInfo) {
    _updateDraft(
      state.draft.copyWith(projects: [...state.draft.projects, projectInfo]),
    );
  }

  void updateProject(ProjectInfo projectInfo) {
    _updateDraft(
      state.draft.copyWith(
        projects: _replaceById(
          state.draft.projects,
          projectInfo.id,
          projectInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeProject(String id) {
    _updateDraft(
      state.draft.copyWith(
        projects: state.draft.projects.where((item) => item.id != id).toList(),
      ),
    );
  }

  void addTraining(TrainingInfo trainingInfo) {
    _updateDraft(
      state.draft.copyWith(trainings: [...state.draft.trainings, trainingInfo]),
    );
  }

  void updateTraining(TrainingInfo trainingInfo) {
    _updateDraft(
      state.draft.copyWith(
        trainings: _replaceById(
          state.draft.trainings,
          trainingInfo.id,
          trainingInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeTraining(String id) {
    _updateDraft(
      state.draft.copyWith(
        trainings: state.draft.trainings
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void addLanguage(LanguageInfo languageInfo) {
    _updateDraft(
      state.draft.copyWith(languages: [...state.draft.languages, languageInfo]),
    );
  }

  void updateLanguage(LanguageInfo languageInfo) {
    _updateDraft(
      state.draft.copyWith(
        languages: _replaceById(
          state.draft.languages,
          languageInfo.id,
          languageInfo,
          (item) => item.id,
        ),
      ),
    );
  }

  void removeLanguage(String id) {
    _updateDraft(
      state.draft.copyWith(
        languages: state.draft.languages
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void _updateDraft(CvProfile draft) {
    final now = DateTime.now();
    state = state.copyWith(
      draft: draft.copyWith(updatedAt: now),
      hasInitializedDraft: true,
      hasUnsavedChanges: true,
      clearErrorMessage: true,
    );
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _cancelAutosave();
    _autosaveTimer = Timer(_autosaveDelay, saveNow);
  }

  void _cancelAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  int _normalizeStepIndex(int index) {
    final lastIndex = CvBuilderStep.values.length - 1;
    if (index < 0) {
      return 0;
    }

    if (index > lastIndex) {
      return lastIndex;
    }

    return index;
  }

  List<T> _replaceById<T>(
    List<T> source,
    String id,
    T nextValue,
    String Function(T item) getId,
  ) {
    return [
      for (final item in source)
        if (getId(item) == id) nextValue else item,
    ];
  }
}
