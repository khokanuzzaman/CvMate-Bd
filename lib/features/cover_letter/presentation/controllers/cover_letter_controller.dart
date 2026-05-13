import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_state.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final coverLetterControllerProvider =
    NotifierProvider<CoverLetterController, CoverLetterState>(
      CoverLetterController.new,
    );

class CoverLetterController extends Notifier<CoverLetterState> {
  @override
  CoverLetterState build() => CoverLetterState.initial();

  Future<void> initialize({bool force = false}) async {
    if (state.hasInitialized && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final drafts = await ref
          .read(coverLetterRepositoryProvider)
          .getAllDrafts();
      final activeBuilderState = ref.read(cvBuilderControllerProvider);
      final activeCvId = activeBuilderState.hasActiveDraft
          ? activeBuilderState.draft.id
          : null;

      final nextSelectedCvId = _resolveSelectedCvId(
        cvs: cvs,
        preferredCvId: state.selectedCvId,
        activeBuilderCvId: activeCvId,
      );
      final nextSelectedCv = _findCv(cvs, nextSelectedCvId);
      final nextCandidateSummary = state.candidateSummary.trim().isEmpty
          ? _defaultCandidateSummary(nextSelectedCv)
          : state.candidateSummary;

      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        availableCvs: cvs,
        recentDrafts: drafts,
        selectedCvId: nextSelectedCvId,
        candidateSummary: nextCandidateSummary,
      );
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        errorMessage: 'Could not load cover letter drafts. Please try again.',
      );
    }
  }

  Future<void> reload() => initialize(force: true);

  void startNewDraft() {
    final selectedCv = state.selectedCv;
    state = state.copyWith(
      activeDraftId: null,
      activeDraftCreatedAt: null,
      outputType: CoverLetterOutputType.formalCoverLetter,
      language: AiOutputLanguage.english,
      tone: AiTone.formal,
      targetCompany: '',
      jobTitle: '',
      jobDetails: '',
      hiringManagerName: '',
      candidateSummary: _defaultCandidateSummary(selectedCv),
      subjectLine: '',
      generatedContent: '',
      clearErrorMessage: true,
    );
  }

  void selectCv(String? cvId) {
    if (cvId == state.selectedCvId) {
      return;
    }

    final nextCv = _findCv(state.availableCvs, cvId);
    state = state.copyWith(
      selectedCvId: cvId,
      candidateSummary: state.candidateSummary.trim().isEmpty
          ? _defaultCandidateSummary(nextCv)
          : state.candidateSummary,
      clearErrorMessage: true,
    );
  }

  void loadDraft(String draftId) {
    CoverLetterDraft? draft;
    for (final item in state.recentDrafts) {
      if (item.id == draftId) {
        draft = item;
        break;
      }
    }

    if (draft == null) {
      state = state.copyWith(
        errorMessage: 'Could not open this draft. Please try again.',
      );
      return;
    }

    final selectedCvId = _findCv(state.availableCvs, draft.cvId)?.id;
    state = state.copyWith(
      activeDraftId: draft.id,
      activeDraftCreatedAt: draft.createdAt,
      selectedCvId: selectedCvId,
      outputType: draft.outputType,
      language: draft.language,
      tone: draft.tone,
      targetCompany: draft.targetCompany,
      jobTitle: draft.jobTitle,
      jobDetails: draft.jobDetails,
      hiringManagerName: draft.hiringManagerName,
      candidateSummary: draft.candidateSummary,
      subjectLine: draft.subjectLine,
      generatedContent: draft.content,
      clearErrorMessage: true,
    );
  }

  void selectOutputType(CoverLetterOutputType type) {
    if (type == state.outputType) {
      return;
    }

    state = state.copyWith(
      outputType: type,
      subjectLine: type.showsSubjectLine ? state.subjectLine : '',
      clearErrorMessage: true,
    );
  }

  void selectLanguage(AiOutputLanguage language) {
    if (language == state.language) {
      return;
    }

    state = state.copyWith(language: language, clearErrorMessage: true);
  }

  void selectTone(AiTone tone) {
    if (tone == state.tone) {
      return;
    }

    state = state.copyWith(tone: tone, clearErrorMessage: true);
  }

  void updateTargetCompany(String value) {
    if (value == state.targetCompany) {
      return;
    }

    state = state.copyWith(targetCompany: value, clearErrorMessage: true);
  }

  void updateJobTitle(String value) {
    if (value == state.jobTitle) {
      return;
    }

    state = state.copyWith(jobTitle: value, clearErrorMessage: true);
  }

  void updateJobDetails(String value) {
    if (value == state.jobDetails) {
      return;
    }

    state = state.copyWith(jobDetails: value, clearErrorMessage: true);
  }

  void updateHiringManagerName(String value) {
    if (value == state.hiringManagerName) {
      return;
    }

    state = state.copyWith(hiringManagerName: value, clearErrorMessage: true);
  }

  void updateCandidateSummary(String value) {
    if (value == state.candidateSummary) {
      return;
    }

    state = state.copyWith(candidateSummary: value, clearErrorMessage: true);
  }

  void updateSubjectLine(String value) {
    if (value == state.subjectLine) {
      return;
    }

    state = state.copyWith(subjectLine: value, clearErrorMessage: true);
  }

  void updateGeneratedContent(String value) {
    if (value == state.generatedContent) {
      return;
    }

    state = state.copyWith(generatedContent: value, clearErrorMessage: true);
  }

  Future<void> generateContent() async {
    final validationError = _validateGenerationRequest();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    state = state.copyWith(isGenerating: true, clearErrorMessage: true);
    final aiService = ref.read(aiCareerServiceProvider);
    final profile = _buildGenerationProfile();

    final result = await switch (state.outputType) {
      CoverLetterOutputType.formalCoverLetter => aiService.generateCoverLetter(
        profile: profile,
        companyName: state.targetCompany.trim(),
        jobTitle: state.jobTitle.trim(),
        jobPostText: state.jobDetails.trim(),
        hiringManagerName: state.hiringManagerName.trim(),
        candidateSummary: _effectiveCandidateSummary(),
        isShortVersion: false,
        language: state.language,
        tone: state.tone,
      ),
      CoverLetterOutputType.shortCoverLetter => aiService.generateCoverLetter(
        profile: profile,
        companyName: state.targetCompany.trim(),
        jobTitle: state.jobTitle.trim(),
        jobPostText: state.jobDetails.trim(),
        hiringManagerName: state.hiringManagerName.trim(),
        candidateSummary: _effectiveCandidateSummary(),
        isShortVersion: true,
        language: state.language,
        tone: state.tone,
      ),
      CoverLetterOutputType.jobApplicationEmail =>
        aiService.generateJobApplicationEmail(
          profile: profile,
          companyName: state.targetCompany.trim(),
          jobTitle: state.jobTitle.trim(),
          jobPostText: state.jobDetails.trim(),
          hiringManagerName: state.hiringManagerName.trim(),
          candidateSummary: _effectiveCandidateSummary(),
          language: state.language,
          tone: state.tone,
        ),
      CoverLetterOutputType.linkedInMessage =>
        aiService.generateLinkedInMessage(
          profile: profile,
          companyName: state.targetCompany.trim(),
          jobTitle: state.jobTitle.trim(),
          jobPostText: state.jobDetails.trim(),
          hiringManagerName: state.hiringManagerName.trim(),
          candidateSummary: _effectiveCandidateSummary(),
          language: state.language,
          tone: state.tone,
        ),
    };

    result.when(
      success: (data) {
        state = state.copyWith(
          isGenerating: false,
          subjectLine: data.subjectLine,
          generatedContent: data.body,
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

  Future<String?> copyOutput() async {
    final text = _shareableText();
    if (text == null) {
      state = state.copyWith(errorMessage: 'Generate content first.');
      return state.errorMessage;
    }

    await Clipboard.setData(ClipboardData(text: text));
    return 'Copied to clipboard.';
  }

  Future<String?> shareOutput() async {
    final text = _shareableText();
    if (text == null) {
      state = state.copyWith(errorMessage: 'Generate content first.');
      return state.errorMessage;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: state.subjectLine.trim().isEmpty
              ? state.outputType.label
              : state.subjectLine.trim(),
        ),
      );
      return 'Share sheet opened.';
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not open the share sheet.');
      return state.errorMessage;
    }
  }

  Future<String?> saveDraft() async {
    if (_shareableText() == null) {
      state = state.copyWith(
        errorMessage: 'Generate or write your cover letter content first.',
      );
      return state.errorMessage;
    }

    final now = DateTime.now();
    final isUpdating = state.activeDraftId != null;
    final draft = CoverLetterDraft(
      id: state.activeDraftId ?? now.microsecondsSinceEpoch.toString(),
      userId: null,
      cvId: state.selectedCv?.id,
      targetCompany: state.targetCompany.trim(),
      jobTitle: state.jobTitle.trim(),
      jobDetails: state.jobDetails.trim(),
      hiringManagerName: state.hiringManagerName.trim(),
      candidateSummary: state.candidateSummary.trim(),
      outputType: state.outputType,
      language: state.language,
      tone: state.tone,
      subjectLine: state.subjectLine.trim(),
      content: state.generatedContent.trim(),
      createdAt: state.activeDraftCreatedAt ?? now,
      updatedAt: now,
    );

    try {
      final saved = await ref
          .read(coverLetterRepositoryProvider)
          .saveDraft(draft);
      final refreshedDrafts = _replaceDraft(state.recentDrafts, saved)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        activeDraftId: saved.id,
        activeDraftCreatedAt: saved.createdAt,
        recentDrafts: refreshedDrafts,
        clearErrorMessage: true,
      );
      return isUpdating ? 'Draft updated.' : 'Draft saved.';
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Draft save failed. Please try again.',
      );
      return state.errorMessage;
    }
  }

  Future<String?> deleteDraft(String id) async {
    try {
      await ref.read(coverLetterRepositoryProvider).deleteDraft(id);
      final refreshedDrafts = [
        for (final draft in state.recentDrafts)
          if (draft.id != id) draft,
      ];
      final isActive = state.activeDraftId == id;
      state = state.copyWith(
        recentDrafts: refreshedDrafts,
        activeDraftId: isActive ? null : state.activeDraftId,
        activeDraftCreatedAt: isActive ? null : state.activeDraftCreatedAt,
        clearErrorMessage: true,
      );
      return 'Draft deleted.';
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not delete this cover letter draft.',
      );
      return state.errorMessage;
    }
  }

  String? _validateGenerationRequest() {
    if (state.targetCompany.trim().isEmpty) {
      return 'Target company name is required.';
    }
    if (state.jobTitle.trim().isEmpty) {
      return 'Job title is required.';
    }
    if (state.jobDetails.trim().isEmpty) {
      return 'Job post or job details are required.';
    }
    if (state.selectedCv == null && _effectiveCandidateSummary().isEmpty) {
      return 'Select a CV or enter a candidate summary first.';
    }

    return null;
  }

  CvProfile _buildGenerationProfile() {
    final selectedCv = state.selectedCv;
    if (selectedCv != null) {
      return selectedCv;
    }

    return CvProfile.empty().copyWith(
      title: 'Manual Cover Letter Profile',
      personalInfo: PersonalInfo(
        fullName: '',
        desiredRole: state.jobTitle.trim(),
      ),
      professionalSummary: _effectiveCandidateSummary(),
    );
  }

  String _effectiveCandidateSummary() {
    final manual = state.candidateSummary.trim();
    if (manual.isNotEmpty) {
      return manual;
    }

    return _defaultCandidateSummary(state.selectedCv);
  }

  String _defaultCandidateSummary(CvProfile? profile) {
    if (profile == null) {
      return '';
    }

    if (profile.professionalSummary.trim().isNotEmpty) {
      return profile.professionalSummary.trim();
    }
    if (profile.careerObjective.trim().isNotEmpty) {
      return profile.careerObjective.trim();
    }
    if (profile.displayRole.trim().isNotEmpty) {
      return profile.displayRole.trim();
    }

    return '';
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

  String? _resolveSelectedCvId({
    required List<CvProfile> cvs,
    required String? preferredCvId,
    required String? activeBuilderCvId,
  }) {
    if (preferredCvId != null && _findCv(cvs, preferredCvId) != null) {
      return preferredCvId;
    }

    if (state.hasInitialized && preferredCvId == null) {
      return null;
    }

    if (activeBuilderCvId != null && _findCv(cvs, activeBuilderCvId) != null) {
      return activeBuilderCvId;
    }

    if (cvs.isNotEmpty) {
      return cvs.first.id;
    }

    return null;
  }

  String? _shareableText() {
    final body = state.generatedContent.trim();
    if (body.isEmpty) {
      return null;
    }

    final subject = state.subjectLine.trim();
    if (subject.isEmpty) {
      return body;
    }

    return 'Subject: $subject\n\n$body';
  }

  List<CoverLetterDraft> _replaceDraft(
    List<CoverLetterDraft> current,
    CoverLetterDraft updated,
  ) {
    final drafts = [
      for (final draft in current)
        if (draft.id != updated.id) draft,
    ];
    drafts.add(updated);
    return drafts;
  }
}
