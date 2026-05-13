enum JobApplicationStatus {
  draft,
  applied,
  shortlisted,
  interview,
  offered,
  rejected,
  archived,
}

extension JobApplicationStatusX on JobApplicationStatus {
  String get label => switch (this) {
    JobApplicationStatus.draft => 'Draft',
    JobApplicationStatus.applied => 'Applied',
    JobApplicationStatus.shortlisted => 'Shortlisted',
    JobApplicationStatus.interview => 'Interview',
    JobApplicationStatus.offered => 'Offered',
    JobApplicationStatus.rejected => 'Rejected',
    JobApplicationStatus.archived => 'Archived',
  };

  bool get isFinal => switch (this) {
    JobApplicationStatus.offered => true,
    JobApplicationStatus.rejected => true,
    JobApplicationStatus.archived => true,
    _ => false,
  };
}
