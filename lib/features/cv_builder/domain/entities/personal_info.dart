class PersonalInfo {
  const PersonalInfo({
    this.fullName = '',
    this.desiredRole = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.linkedInUrl = '',
    this.portfolioUrl = '',
  });

  final String fullName;
  final String desiredRole;
  final String email;
  final String phone;
  final String address;
  final String linkedInUrl;
  final String portfolioUrl;

  factory PersonalInfo.empty() => const PersonalInfo();

  PersonalInfo copyWith({
    String? fullName,
    String? desiredRole,
    String? email,
    String? phone,
    String? address,
    String? linkedInUrl,
    String? portfolioUrl,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      desiredRole: desiredRole ?? this.desiredRole,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
    );
  }

  bool get isEmpty =>
      fullName.trim().isEmpty &&
      desiredRole.trim().isEmpty &&
      email.trim().isEmpty &&
      phone.trim().isEmpty &&
      address.trim().isEmpty &&
      linkedInUrl.trim().isEmpty &&
      portfolioUrl.trim().isEmpty;
}
