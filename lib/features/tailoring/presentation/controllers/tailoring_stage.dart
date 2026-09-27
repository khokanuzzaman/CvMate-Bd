/// The current stage of the "Tailor to a job" flow.
enum TailoringStage {
  idle,
  analyzing,
  tailoring,
  generatingCoverLetter,
  ready,
  error,
}

extension TailoringStageX on TailoringStage {
  bool get isBusy =>
      this == TailoringStage.analyzing ||
      this == TailoringStage.tailoring ||
      this == TailoringStage.generatingCoverLetter;

  String get label => switch (this) {
    TailoringStage.idle => 'Ready to start',
    TailoringStage.analyzing => 'Analyzing job post...',
    TailoringStage.tailoring => 'Tailoring your CV...',
    TailoringStage.generatingCoverLetter => 'Writing cover letter...',
    TailoringStage.ready => 'Ready',
    TailoringStage.error => 'Something went wrong',
  };
}
