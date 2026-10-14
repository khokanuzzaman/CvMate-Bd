import 'dart:async';
import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
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
        clearCurrentCustomSection: true,
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
        clearCurrentCustomSection: true,
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
        clearCurrentCustomSection: true,
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
      clearCurrentCustomSection: true,
    );
  }

  /// Opens the builder page of a custom section.
  void goToCustomSection(String id) {
    if (state.draft.customSectionById(id) == null) {
      return;
    }
    state = state.copyWith(
      currentCustomSectionId: id,
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

  /// The first problem on a custom section's page, or null.
  String? validateCustomSection(String id) {
    final section = state.draft.customSectionById(id);
    return section == null
        ? null
        : CvBuilderValidators.validateCustomSection(section);
  }

  List<String> previewWarnings() {
    return CvBuilderValidators.buildPreviewWarnings(state.draft);
  }

  Future<void> saveNow() async {
    // The builder flushes on dispose, which can run after the container itself
    // is gone (app teardown / restart); there is nothing left to save then.
    if (!ref.mounted || !state.hasActiveDraft || state.isLoading) {
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

  // --- Section layout --------------------------------------------------------
  // The layout only controls order, visibility and titles; the typed fields stay
  // where they are. Every change works on the cleaned effective list
  // ([CvProfile.sections]) and stores it, so the first edit "materialises" the
  // template default into an explicit layout.

  /// Moves a section like `ReorderableListView.onReorderItem` reports it
  /// ([newIndex] is the position the section ends up at).
  void reorderSections(int oldIndex, int newIndex) {
    final sections = [...state.draft.sections];
    if (oldIndex < 0 || oldIndex >= sections.length) {
      return;
    }
    final target = newIndex.clamp(0, sections.length - 1);
    if (target == oldIndex) {
      return;
    }
    final moved = sections.removeAt(oldIndex);
    sections.insert(target, moved);
    _updateDraft(state.draft.copyWith(sectionLayout: sections));
  }

  void setSectionVisible(String id, bool visible) {
    _updateDraft(
      state.draft.copyWith(
        sectionLayout: [
          for (final config in state.draft.sections)
            if (config.id == id) config.copyWith(visible: visible) else config,
        ],
      ),
    );
  }

  /// Renames a section. An empty [title] puts the default title back. A custom
  /// section's own title is what is renamed (it has no default to fall back to,
  /// so an empty title is ignored).
  void renameSection(String id, String? title) {
    final value = title?.trim() ?? '';
    final custom = state.draft.customSectionById(id);
    if (custom != null) {
      if (value.isEmpty) {
        return;
      }
      updateCustomSection(custom.copyWith(title: value));
      return;
    }
    _updateDraft(
      state.draft.copyWith(
        sectionLayout: [
          for (final config in state.draft.sections)
            if (config.id == id)
              value.isEmpty
                  ? config.copyWith(clearTitleOverride: true)
                  : config.copyWith(titleOverride: value)
            else
              config,
        ],
      ),
    );
  }

  /// Back to the template's order, every section shown, default titles. Custom
  /// sections and all content are kept (custom sections follow the built-ins).
  void resetSectionLayout() {
    _updateDraft(state.draft.copyWith(clearSectionLayout: true));
  }

  /// Adds a custom section at the end and returns it.
  CustomSection addCustomSection({
    required String title,
    required CustomSectionLayout layout,
  }) {
    final section = CustomSection.create(title: title.trim(), layout: layout);
    _updateDraft(
      state.draft.copyWith(
        customSections: [...state.draft.customSections, section],
        sectionLayout: [
          ...state.draft.sections,
          SectionConfig.custom(section.id),
        ],
      ),
    );
    return section;
  }

  /// Deletes a custom section and its items. Built-in sections cannot be
  /// deleted (only hidden).
  void deleteCustomSection(String id) {
    if (state.draft.customSectionById(id) == null) {
      return;
    }
    final wasCurrent = state.currentCustomSectionId == id;
    _updateDraft(
      state.draft.copyWith(
        customSections: [
          for (final section in state.draft.customSections)
            if (section.id != id) section,
        ],
        sectionLayout: [
          for (final config in state.draft.sections)
            if (config.id != id) config,
        ],
      ),
    );
    if (wasCurrent) {
      state = state.copyWith(clearCurrentCustomSection: true);
    }
  }

  void updateCustomSection(CustomSection section) {
    _updateDraft(
      state.draft.copyWith(
        customSections: [
          for (final existing in state.draft.customSections)
            if (existing.id == section.id) section else existing,
        ],
      ),
    );
  }

  void addCustomSectionItem(String sectionId) {
    final section = state.draft.customSectionById(sectionId);
    if (section == null) {
      return;
    }
    updateCustomSection(
      section.copyWith(items: [...section.items, CustomSectionItem.empty()]),
    );
  }

  void updateCustomSectionItem(String sectionId, CustomSectionItem item) {
    final section = state.draft.customSectionById(sectionId);
    if (section == null) {
      return;
    }
    updateCustomSection(
      section.copyWith(
        items: _replaceById(section.items, item.id, item, (it) => it.id),
      ),
    );
  }

  void removeCustomSectionItem(String sectionId, String itemId) {
    final section = state.draft.customSectionById(sectionId);
    if (section == null) {
      return;
    }
    updateCustomSection(
      section.copyWith(
        items: [
          for (final item in section.items)
            if (item.id != itemId) item,
        ],
      ),
    );
  }

  /// Moves an item within a custom section (same index rules as
  /// [reorderSections]).
  void reorderCustomSectionItems(String sectionId, int oldIndex, int newIndex) {
    final section = state.draft.customSectionById(sectionId);
    if (section == null || oldIndex < 0 || oldIndex >= section.items.length) {
      return;
    }
    final items = [...section.items];
    final target = newIndex.clamp(0, items.length - 1);
    if (target == oldIndex) {
      return;
    }
    items.insert(target, items.removeAt(oldIndex));
    updateCustomSection(section.copyWith(items: items));
  }

  void changeCustomSectionLayout(String sectionId, CustomSectionLayout layout) {
    final section = state.draft.customSectionById(sectionId);
    if (section == null) {
      return;
    }
    updateCustomSection(section.copyWith(layout: layout));
  }

  // --- Market style, personal details, declaration ---------------------------

  /// Picks a market style and the paper size together. Only the *shown* fields
  /// change (to the style's defaults); the data behind hidden fields is kept.
  void applyStyle(CvStyle style, {PaperSize? paperSize}) {
    _updateDraft(
      state.draft.copyWith(
        style: style,
        paperSize: paperSize,
        shownFields: style.defaultFields,
      ),
    );
  }

  /// Switches one field on or off without touching the others.
  void setFieldShown(PersonalField field, bool shown) {
    final fields = {...state.draft.shownFields};
    shown ? fields.add(field) : fields.remove(field);
    _updateDraft(state.draft.copyWith(shownFields: fields));
  }

  void updateDetails(PersonalDetails details) {
    _updateDraft(state.draft.copyWith(details: details));
  }

  void updateDeclaration(CvDeclaration declaration) {
    _updateDraft(state.draft.copyWith(declaration: declaration));
  }

  /// Sets (or, with null, removes) the photo. Adding one switches it on.
  void setPhoto(Uint8List? bytes) {
    _updateDraft(
      bytes == null
          ? state.draft.copyWith(clearPhoto: true)
          : state.draft.copyWith(
              photo: bytes,
              shownFields: {...state.draft.shownFields, PersonalField.photo},
            ),
    );
  }

  /// Sets (or, with null, removes) the signature image. Adding one switches it
  /// on.
  void setSignature(Uint8List? bytes) {
    _updateDraft(
      bytes == null
          ? state.draft.copyWith(clearSignature: true)
          : state.draft.copyWith(
              signature: bytes,
              shownFields: {
                ...state.draft.shownFields,
                PersonalField.signature,
              },
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
