import 'dart:async';

import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three pages of the tailoring flow (Step 1/3, 2/3, 3/3).
enum TailoringPage { paste, match, result }

extension TailoringPageX on TailoringPage {
  /// 1-based step number shown in the pill and the segmented steps.
  int get step => index + 1;
}

final tailoringFlowProvider =
    NotifierProvider.autoDispose<TailoringFlowController, TailoringPage>(
      TailoringFlowController.new,
    );

/// Sequences the three tailoring pages. It holds no business logic: analyzing,
/// tailoring, saving and the AI calls all stay in [TailoringController]; this
/// only decides which page is showing and moves forward once the underlying
/// step has produced its result.
class TailoringFlowController extends Notifier<TailoringPage> {
  @override
  TailoringPage build() => TailoringPage.paste;

  /// Runs the keyword analysis and, if it produced a report, shows page 2.
  Future<void> analyze() async {
    final tailoring = ref.read(tailoringControllerProvider.notifier);
    await tailoring.analyze();
    if (ref.read(tailoringControllerProvider).hasMatchReport) {
      state = TailoringPage.match;
    }
  }

  /// Tailors the CV and, if that produced content, shows page 3.
  Future<void> tailor() async {
    final tailoring = ref.read(tailoringControllerProvider.notifier);
    await tailoring.tailor();
    final result = ref.read(tailoringControllerProvider).result;
    if (result != null && result.hasTailoredContent) {
      state = TailoringPage.result;
    }
  }

  /// Clears the job, the match and the result (the controller's `reset()`) and
  /// goes back to the first page. The selected CV is kept.
  void startOver() {
    ref.read(tailoringControllerProvider.notifier).reset();
    state = TailoringPage.paste;
  }

  /// Moves to the previous page. Returns false on the first page, where the
  /// caller should leave the screen instead.
  bool back() {
    switch (state) {
      case TailoringPage.paste:
        return false;
      case TailoringPage.match:
        state = TailoringPage.paste;
      case TailoringPage.result:
        state = TailoringPage.match;
    }
    return true;
  }

  /// Hands the job context to the cover-letter feature (company, title, post and
  /// the tailored CV) so its screen opens already aligned to this
  /// job. Generation starts straight away when a company name is known;
  /// otherwise the screen opens on its form so the user can add one.
  Future<void> prepareCoverLetter() async {
    final tailoring = ref.read(tailoringControllerProvider);
    final cv = tailoring.selectedCv;
    final letters = ref.read(coverLetterControllerProvider.notifier);

    await letters.reload();
    letters.selectCv(tailoring.cvId);
    letters.startNewDraft();

    final company = tailoring.company.trim();
    final title = tailoring.jobTitle.trim().isEmpty
        ? (cv?.displayRole ?? '')
        : tailoring.jobTitle.trim();
    letters
      ..updateTargetCompany(company)
      ..updateJobTitle(title)
      ..updateJobDetails(tailoring.jobPostText.trim());

    final summary = tailoring.result?.tailoredSummary.trim() ?? '';
    if (summary.isNotEmpty) {
      letters.updateCandidateSummary(summary);
    }

    // Write the letter from the tailored CV (with the user's edits applied), not
    // the saved one, so its summary, skills and bullets match the job.
    letters.useTailoredProfile(
      ref.read(tailoringControllerProvider.notifier).buildTailoredCv(),
    );

    if (company.isNotEmpty) {
      unawaited(letters.generateContent());
    }
  }
}

/// Keyword coverage of the tailored CV (with the user's edits applied) against
/// the job post, from the same offline ATS engine as the first analysis.
/// Null until there is a tailoring result.
final tailoredMatchPercentProvider = Provider.autoDispose<int?>((ref) {
  final state = ref.watch(tailoringControllerProvider);
  if (state.result == null) {
    return null;
  }
  final tailored = ref
      .read(tailoringControllerProvider.notifier)
      .buildTailoredCv();
  if (tailored == null) {
    return null;
  }
  return ref
      .read(atsRuleEngineProvider)
      .analyzeJobPost(profile: tailored, jobPostText: state.jobPostText.trim())
      .matchPercentage;
});
