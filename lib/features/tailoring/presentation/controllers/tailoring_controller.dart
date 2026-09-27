import 'dart:async';

import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:careermatebd/features/tailoring/domain/entities/tailoring_result.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_stage.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_state.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tailoringControllerProvider =
    NotifierProvider<TailoringController, TailoringState>(
      TailoringController.new,
    );

/// Orchestrates the "Tailor to a job" core loop by reusing existing services:
/// the offline [AtsRuleEngine] for the keyword gap, [AiCareerService] for the
/// combined tailoring call and the cover letter, and the CV repository to save
/// the result as a NEW CV (the source CV is never mutated).
class TailoringController extends Notifier<TailoringState> {
  @override
  TailoringState build() => TailoringState.initial();

  Future<void> initialize({bool force = false}) async {
    if (state.hasInitialized && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final builderState = ref.read(cvBuilderControllerProvider);
      final activeCvId = builderState.hasActiveDraft
          ? builderState.draft.id
          : null;
      final selectedCvId = _resolveInitialCvId(
        cvs,
        preferredId: state.cvId,
        activeCvId: activeCvId,
      );

      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        availableCvs: cvs,
        cvId: selectedCvId,
        clearFailure: true,
      );
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        failure: const Failure('Could not load saved CVs. Please try again.'),
      );
    }
  }

  Future<void> reload() => initialize(force: true);

  void selectCv(String id) {
    if (id == state.cvId) {
      return;
    }

    state = state.copyWith(
      cvId: id,
      stage: TailoringStage.idle,
      clearMatchReport: true,
      clearResult: true,
      clearSavedCvId: true,
      clearFailure: true,
    );
  }

  void useActiveCv() {
    final builderState = ref.read(cvBuilderControllerProvider);
    if (!builderState.hasActiveDraft) {
      return;
    }

    final activeId = builderState.draft.id;
    if (_findCv(state.availableCvs, activeId) != null) {
      selectCv(activeId);
    }
  }

  void updateJobPost({String? jobPostText, String? jobTitle, String? company}) {
    final nextJobPost = jobPostText ?? state.jobPostText;
    final jobPostChanged = nextJobPost != state.jobPostText;

    state = state.copyWith(
      jobPostText: nextJobPost,
      jobTitle: jobTitle ?? state.jobTitle,
      company: company ?? state.company,
      stage: jobPostChanged ? TailoringStage.idle : state.stage,
      clearMatchReport: jobPostChanged,
      clearResult: jobPostChanged,
      clearSavedCvId: jobPostChanged,
      clearFailure: true,
    );
  }

  Future<void> analyze() async {
    final cv = state.selectedCv;
    if (cv == null) {
      _fail('Create or select a CV first before analyzing.');
      return;
    }
    if (!state.hasJobPost) {
      _fail('Paste a longer job post with role details and keywords first.');
      return;
    }

    state = state.copyWith(stage: TailoringStage.analyzing, clearFailure: true);

    final report = ref
        .read(atsRuleEngineProvider)
        .analyzeJobPost(profile: cv, jobPostText: state.jobPostText.trim());

    state = state.copyWith(
      stage: TailoringStage.ready,
      matchReport: report,
      clearFailure: true,
    );
  }

  Future<void> tailor() async {
    final cv = state.selectedCv;
    if (cv == null) {
      _fail('Create or select a CV first before tailoring.');
      return;
    }
    if (!state.hasJobPost) {
      _fail('Paste a longer job post with role details and keywords first.');
      return;
    }

    final jobPost = state.jobPostText.trim();
    final report =
        state.matchReport ??
        ref
            .read(atsRuleEngineProvider)
            .analyzeJobPost(profile: cv, jobPostText: jobPost);

    state = state.copyWith(
      stage: TailoringStage.tailoring,
      matchReport: report,
      clearFailure: true,
    );
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(analytics.logEvent(AnalyticsEvents.tailoringStarted));

    final result = await ref
        .read(aiCareerServiceProvider)
        .tailorCvForJob(
          profile: cv,
          jobPostText: jobPost,
          jobTitle: state.jobTitle.trim(),
          companyName: state.company.trim(),
          targetKeywords: report.extractedKeywords,
          language: AiOutputLanguage.english,
          tone: AiTone.professional,
        );

    result.when(
      success: (data) {
        final tailoring = (state.result ?? TailoringResult.empty()).copyWith(
          tailoredSummary: data.tailoredSummary,
          emphasizedSkills: data.emphasizedSkills,
          rewrittenBullets: [
            for (final bullet in data.rewrittenBullets)
              TailoredBullet(
                experienceId: bullet.experienceId,
                original: bullet.original,
                suggested: bullet.suggested,
              ),
          ],
        );
        state = state.copyWith(
          stage: TailoringStage.ready,
          result: tailoring,
          clearSavedCvId: true,
          clearFailure: true,
        );
        unawaited(
          analytics.logEvent(
            AnalyticsEvents.aiActionUsed,
            params: {AnalyticsEvents.paramAction: 'tailor_cv'},
          ),
        );
        unawaited(analytics.logEvent(AnalyticsEvents.tailoringCompleted));
      },
      failure: (failure) {
        state = state.copyWith(stage: TailoringStage.error, failure: failure);
      },
    );
  }

  Future<void> generateCoverLetter() async {
    final cv = state.selectedCv;
    if (cv == null) {
      _fail('Create or select a CV first before generating a cover letter.');
      return;
    }
    if (state.company.trim().isEmpty) {
      _fail('Add the target company name first.');
      return;
    }

    final jobTitle = state.jobTitle.trim().isEmpty
        ? cv.displayRole
        : state.jobTitle.trim();
    final tailoredSummary = state.result?.tailoredSummary.trim() ?? '';
    final candidateSummary = tailoredSummary.isNotEmpty
        ? tailoredSummary
        : cv.professionalSummary.trim();

    state = state.copyWith(
      stage: TailoringStage.generatingCoverLetter,
      clearFailure: true,
    );

    final result = await ref
        .read(aiCareerServiceProvider)
        .generateCoverLetter(
          profile: cv,
          companyName: state.company.trim(),
          jobTitle: jobTitle,
          jobPostText: state.jobPostText.trim(),
          candidateSummary: candidateSummary,
          language: AiOutputLanguage.english,
          tone: AiTone.formal,
        );

    result.when(
      success: (document) {
        final tailoring = (state.result ?? TailoringResult.empty()).copyWith(
          coverLetter: document.body,
        );
        state = state.copyWith(
          stage: TailoringStage.ready,
          result: tailoring,
          clearFailure: true,
        );
        unawaited(
          ref.read(analyticsServiceProvider).logEvent(
            AnalyticsEvents.aiActionUsed,
            params: {AnalyticsEvents.paramAction: 'cover_letter'},
          ),
        );
      },
      failure: (failure) {
        state = state.copyWith(stage: TailoringStage.error, failure: failure);
      },
    );
  }

  void updateTailoredSummary(String value) {
    final result = state.result;
    if (result == null) {
      return;
    }
    state = state.copyWith(
      result: result.copyWith(tailoredSummary: value),
      clearSavedCvId: true,
    );
  }

  void updateEmphasizedSkillsText(String value) {
    final result = state.result;
    if (result == null) {
      return;
    }
    final skills = value
        .split(RegExp(r'[\n,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    state = state.copyWith(
      result: result.copyWith(emphasizedSkills: skills),
      clearSavedCvId: true,
    );
  }

  void updateBulletSuggestion(int index, String value) {
    final result = state.result;
    if (result == null ||
        index < 0 ||
        index >= result.rewrittenBullets.length) {
      return;
    }

    final bullets = [
      for (var i = 0; i < result.rewrittenBullets.length; i++)
        if (i == index)
          result.rewrittenBullets[i].copyWith(suggested: value)
        else
          result.rewrittenBullets[i],
    ];
    state = state.copyWith(
      result: result.copyWith(rewrittenBullets: bullets),
      clearSavedCvId: true,
    );
  }

  void updateCoverLetter(String value) {
    final result = state.result ?? TailoringResult.empty();
    state = state.copyWith(result: result.copyWith(coverLetter: value));
  }

  /// Builds a preview CV with the tailored content applied, WITHOUT persisting
  /// and WITHOUT mutating the source CV. Returns the plain selected CV when no
  /// tailoring result exists, or null when no CV is selected.
  CvProfile? buildTailoredCv() {
    final cv = state.selectedCv;
    if (cv == null) {
      return null;
    }
    final result = state.result;
    if (result == null) {
      return cv;
    }
    return _applyTailoring(cv, result);
  }

  Future<CvProfile?> saveAsTailoredCopy() async {
    final cv = state.selectedCv;
    if (cv == null) {
      _fail('No CV selected.');
      return null;
    }

    final result = state.result;
    if (result == null || !result.hasTailoredContent) {
      _fail('Tailor the CV first before saving a copy.');
      return null;
    }

    final now = DateTime.now();
    final copy = _applyTailoring(cv, result).copyWith(
      id: now.microsecondsSinceEpoch.toString(),
      title: _tailoredTitle(cv),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final saved = await ref.read(cvRepositoryProvider).saveCv(copy);
      ref.invalidate(cvLibraryControllerProvider);

      final nextCvs = [
        for (final item in state.availableCvs)
          if (item.id != saved.id) item,
        saved,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        availableCvs: nextCvs,
        savedCvId: saved.id,
        clearFailure: true,
      );
      return saved;
    } catch (_) {
      _fail('Could not save the tailored CV. Please try again.');
      return null;
    }
  }

  void reset() {
    state = state.copyWith(
      stage: TailoringStage.idle,
      jobTitle: '',
      company: '',
      jobPostText: '',
      clearMatchReport: true,
      clearResult: true,
      clearSavedCvId: true,
      clearFailure: true,
    );
  }

  void _fail(String message) {
    state = state.copyWith(failure: Failure(message));
  }

  CvProfile _applyTailoring(CvProfile cv, TailoringResult result) {
    final summary = result.tailoredSummary.trim().isEmpty
        ? cv.professionalSummary
        : result.tailoredSummary.trim();

    return cv.copyWith(
      professionalSummary: summary,
      skills: _mergeSkills(cv.skills, result.emphasizedSkills),
      experiences: _applyBullets(cv.experiences, result.rewrittenBullets),
    );
  }

  List<SkillInfo> _mergeSkills(
    List<SkillInfo> existing,
    List<String> emphasized,
  ) {
    if (emphasized.isEmpty) {
      return existing;
    }

    final byLowerName = {
      for (final skill in existing) skill.name.trim().toLowerCase(): skill,
    };
    final ordered = <SkillInfo>[];
    final used = <String>{};
    final seed = DateTime.now().microsecondsSinceEpoch;

    for (final name in emphasized) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty || used.contains(key)) {
        continue;
      }
      used.add(key);
      final existingSkill = byLowerName[key];
      if (existingSkill != null) {
        ordered.add(existingSkill);
      } else {
        ordered.add(
          SkillInfo(id: '${seed}_$key', name: name.trim(), level: 'Tailored'),
        );
      }
    }

    for (final skill in existing) {
      final key = skill.name.trim().toLowerCase();
      if (!used.contains(key)) {
        used.add(key);
        ordered.add(skill);
      }
    }

    return ordered;
  }

  List<ExperienceInfo> _applyBullets(
    List<ExperienceInfo> experiences,
    List<TailoredBullet> bullets,
  ) {
    if (bullets.isEmpty) {
      return experiences;
    }

    final rewritesByExperience = <String, Map<String, String>>{};
    for (final bullet in bullets) {
      final suggested = bullet.suggested.trim();
      if (suggested.isEmpty) {
        continue;
      }
      (rewritesByExperience[bullet.experienceId] ??= {})[bullet.original
          .trim()] = suggested;
    }

    return [
      for (final experience in experiences)
        if (!rewritesByExperience.containsKey(experience.id))
          experience
        else
          experience.copyWith(
            highlights: [
              for (final highlight in experience.highlights)
                rewritesByExperience[experience.id]![highlight.trim()] ??
                    highlight,
            ],
          ),
    ];
  }

  String _tailoredTitle(CvProfile cv) {
    final company = state.company.trim();
    final base = cv.displayTitle;
    if (company.isEmpty) {
      return '$base — Tailored';
    }
    return '$base — Tailored for $company';
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
