class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  final String uid;

  /// Empty for anonymous (guest) users, who have no email address.
  final String email;
  final String? displayName;

  /// True while the user is a guest who has not yet linked a real account.
  final bool isAnonymous;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (email.trim().isNotEmpty) {
      return email;
    }
    return 'Guest';
  }
}
