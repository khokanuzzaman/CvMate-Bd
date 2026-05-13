enum JobSource {
  bdjobs,
  linkedIn,
  facebookGroup,
  companyWebsite,
  email,
  reference,
  other,
}

extension JobSourceX on JobSource {
  String get label => switch (this) {
    JobSource.bdjobs => 'Bdjobs',
    JobSource.linkedIn => 'LinkedIn',
    JobSource.facebookGroup => 'Facebook Group',
    JobSource.companyWebsite => 'Company Website',
    JobSource.email => 'Email',
    JobSource.reference => 'Reference',
    JobSource.other => 'Other',
  };
}
