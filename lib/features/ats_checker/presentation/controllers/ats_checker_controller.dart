import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final atsRuleEngineProvider = Provider<AtsRuleEngine>((ref) {
  return const AtsRuleEngine();
});

final atsCheckerControllerProvider =
    NotifierProvider<AtsCheckerController, AtsCheckerState>(
      AtsCheckerController.new,
    );

class AtsCheckerController extends Notifier<AtsCheckerState> {
  @override
  AtsCheckerState build() => AtsCheckerState.initial();

  Future<void> initialize({bool force = false}) async {
    if (state.hasInitialized && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final activeDraftState = ref.read(cvBuilderControllerProvider);
      final activeCvId = activeDraftState.hasActiveDraft
          ? activeDraftState.draft.id
          : null;
      final selectedCvId = _resolveInitialCvId(
        cvs,
        preferredId: state.selectedCvId,
        activeCvId: activeCvId,
      );

      final nextState = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        availableCvs: cvs,
        selectedCvId: selectedCvId,
        clearErrorMessage: true,
      );
      state = _rebuildAnalysis(nextState);
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        errorMessage: 'Could not load saved CVs. Please try again.',
      );
    }
  }

  Future<void> reload() => initialize(force: true);

  void selectCv(String? cvId) {
    if (cvId == state.selectedCvId) {
      return;
    }

    state = _rebuildAnalysis(
      state.copyWith(
        selectedCvId: cvId,
        aiSuggestionText: '',
        clearErrorMessage: true,
      ),
    );
  }

  void updateJobPostText(String value) {
    if (value == state.jobPostText) {
      return;
    }

    state = _rebuildAnalysis(
      state.copyWith(
        jobPostText: value,
        hasCheckedJobMatch: false,
        clearJobMatchReport: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> checkJobMatch() async {
    final selectedCv = state.selectedCv;
    if (selectedCv == null) {
      state = state.copyWith(
        errorMessage: 'Create or select a CV first before checking job match.',
      );
      return;
    }

    final jobPostText = state.jobPostText.trim();
    if (jobPostText.length < 30) {
      state = state.copyWith(
        errorMessage:
            'Paste a longer job post with role details and keywords first.',
        hasCheckedJobMatch: false,
        clearJobMatchReport: true,
      );
      return;
    }

    state = state.copyWith(isCheckingJobMatch: true, clearErrorMessage: true);

    final report = ref
        .read(atsRuleEngineProvider)
        .analyzeJobPost(profile: selectedCv, jobPostText: jobPostText);

    state = state.copyWith(
      isCheckingJobMatch: false,
      hasCheckedJobMatch: true,
      jobMatchReport: report,
      clearErrorMessage: true,
    );
  }

  void selectAiTarget(AtsAiTarget target) {
    if (target == state.aiTarget) {
      return;
    }

    state = state.copyWith(
      aiTarget: target,
      aiSuggestionText: '',
      clearErrorMessage: true,
    );
  }

  void updateAiSuggestionText(String value) {
    if (value == state.aiSuggestionText) {
      return;
    }
    state = state.copyWith(aiSuggestionText: value, clearErrorMessage: true);
  }

  Future<void> generateAiSuggestion() async {
    final selectedCv = state.selectedCv;
    if (selectedCv == null) {
      state = state.copyWith(
        errorMessage:
            'Create or select a CV first before generating suggestions.',
      );
      return;
    }

    state = state.copyWith(
      isGeneratingAiSuggestion: true,
      clearErrorMessage: true,
    );

    final aiService = ref.read(aiCareerServiceProvider);
    final result = switch (state.aiTarget) {
      AtsAiTarget.professionalSummary => aiService.generateProfessionalSummary(
        profile: selectedCv,
        language: AiOutputLanguage.english,
        tone: AiTone.professional,
        jobTitle: selectedCv.personalInfo.desiredRole,
        jobPostText: state.jobPostText.trim(),
      ),
      AtsAiTarget.careerObjective => aiService.generateCareerObjective(
        profile: selectedCv,
        language: AiOutputLanguage.english,
        tone: AiTone.professional,
        jobTitle: selectedCv.personalInfo.desiredRole,
        jobPostText: state.jobPostText.trim(),
      ),
    };

    final resolved = await result;
    resolved.when(
      success: (data) {
        state = state.copyWith(
          isGeneratingAiSuggestion: false,
          aiSuggestionText: data.suggestedText,
          clearErrorMessage: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isGeneratingAiSuggestion: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<String?> copySuggestion() async {
    final text = state.aiSuggestionText.trim();
    if (text.isEmpty) {
      return 'Generate a suggestion first.';
    }

    await Clipboard.setData(ClipboardData(text: text));
    return 'Suggestion copied.';
  }

  Future<String?> copyJobMatchSuggestions() async {
    final report = state.jobMatchReport;
    if (report == null) {
      state = state.copyWith(
        errorMessage: 'Check the job match first to copy suggestions.',
      );
      return state.errorMessage;
    }

    final buffer = StringBuffer()
      ..writeln('Job Match Score: ${report.matchPercentage}%')
      ..writeln()
      ..writeln(
        'Matched keywords: ${report.matchedKeywords.isEmpty ? 'None yet' : report.matchedKeywords.join(', ')}',
      )
      ..writeln(
        'Missing keywords: ${report.missingKeywords.isEmpty ? 'None detected' : report.missingKeywords.join(', ')}',
      );

    if (report.suggestedSectionsToImprove.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          'Suggested sections to improve: ${report.suggestedSectionsToImprove.join(', ')}',
        );
    }

    if (report.suggestedSkillsToAdd.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          'Skills supported by existing CV evidence: ${report.suggestedSkillsToAdd.join(', ')}',
        );
    }

    buffer
      ..writeln()
      ..writeln(
        'Review every suggestion before editing your CV. Only add skills and experience that are true.',
      );

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    return 'Job match suggestions copied.';
  }

  Future<String?> applyAiSuggestionToCv() async {
    final selectedCv = state.selectedCv;
    final suggestion = state.aiSuggestionText.trim();
    if (selectedCv == null) {
      state = state.copyWith(errorMessage: 'No CV selected.');
      return state.errorMessage;
    }

    if (suggestion.isEmpty) {
      state = state.copyWith(errorMessage: 'Generate a suggestion first.');
      return state.errorMessage;
    }

    final updatedCv = switch (state.aiTarget) {
      AtsAiTarget.professionalSummary => selectedCv.copyWith(
        professionalSummary: suggestion,
      ),
      AtsAiTarget.careerObjective => selectedCv.copyWith(
        careerObjective: suggestion,
      ),
    };

    return _saveUpdatedCv(
      updatedCv,
      successMessage: 'Suggestion applied to CV.',
    );
  }

  Future<String?> applyDetectedSkillsToCv() async {
    final selectedCv = state.selectedCv;
    final report = state.jobMatchReport;
    if (selectedCv == null) {
      state = state.copyWith(errorMessage: 'No CV selected.');
      return state.errorMessage;
    }

    if (report == null || report.suggestedSkillsToAdd.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No detected skills are ready to add.',
      );
      return state.errorMessage;
    }

    final existingSkills = {
      for (final skill in selectedCv.skills) skill.name.trim().toLowerCase(),
    };
    final nextSkills = List<SkillInfo>.from(selectedCv.skills);
    final idSeed = DateTime.now().microsecondsSinceEpoch;

    for (var index = 0; index < report.suggestedSkillsToAdd.length; index++) {
      final skillName = report.suggestedSkillsToAdd[index];
      final normalized = skillName.toLowerCase();
      if (existingSkills.contains(normalized)) {
        continue;
      }
      nextSkills.add(
        SkillInfo(id: '${idSeed}_$index', name: skillName, level: 'Detected'),
      );
      existingSkills.add(normalized);
    }

    final updatedCv = selectedCv.copyWith(skills: nextSkills);
    return _saveUpdatedCv(
      updatedCv,
      successMessage: 'Detected skills added to CV.',
    );
  }

  Future<String?> _saveUpdatedCv(
    CvProfile updatedCv, {
    required String successMessage,
  }) async {
    try {
      final saved = await ref.read(cvRepositoryProvider).saveCv(updatedCv);
      ref.invalidate(cvLibraryControllerProvider);
      ref.read(cvBuilderControllerProvider.notifier).syncExternalDraft(saved);

      final nextCvs = [
        for (final cv in state.availableCvs)
          if (cv.id != saved.id) cv,
        saved,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = _rebuildAnalysis(
        state.copyWith(
          availableCvs: nextCvs,
          selectedCvId: saved.id,
          clearErrorMessage: true,
        ),
      );
      return successMessage;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not update this CV. Please try again.',
      );
      return state.errorMessage;
    }
  }

  AtsCheckerState _rebuildAnalysis(AtsCheckerState currentState) {
    final selectedCv = _findCv(
      currentState.availableCvs,
      currentState.selectedCvId,
    );
    if (selectedCv == null) {
      return currentState.copyWith(
        clearReport: true,
        clearJobMatchReport: true,
      );
    }

    final ruleEngine = ref.read(atsRuleEngineProvider);
    final report = ruleEngine.analyzeCv(selectedCv);
    final shouldRebuildJobMatch =
        currentState.hasCheckedJobMatch &&
        currentState.jobPostText.trim().isNotEmpty;
    final jobMatchReport = shouldRebuildJobMatch
        ? ruleEngine.analyzeJobPost(
            profile: selectedCv,
            jobPostText: currentState.jobPostText.trim(),
          )
        : null;

    return currentState.copyWith(
      report: report,
      jobMatchReport: jobMatchReport,
    );
  }

  String? _resolveInitialCvId(
    List<CvProfile> cvs, {
    required String? preferredId,
    required String? activeCvId,
  }) {
    if (preferredId != null && _findCv(cvs, preferredId) != null) {
      return preferredId;
    }
    if (activeCvId != null && _findCv(cvs, activeCvId) != null) {
      return activeCvId;
    }
    if (cvs.isEmpty) {
      return null;
    }
    return cvs.first.id;
  }

  CvProfile? _findCv(List<CvProfile> cvs, String? id) {
    if (id == null) {
      return null;
    }

    for (final cv in cvs) {
      if (cv.id == id) {
        return cv;
      }
    }
    return null;
  }
}
