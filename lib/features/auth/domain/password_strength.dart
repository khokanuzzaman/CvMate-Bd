/// Coarse password strength for the register meter. UI feedback only — it never
/// gates sign-up (length is enforced by the form validator).
enum PasswordStrength {
  empty(0),
  weak(1),
  fair(2),
  strong(3);

  const PasswordStrength(this.score);

  /// Number of meter segments to fill (0–3).
  final int score;

  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _upperOrSymbol = RegExp(r'[A-Z]|[^A-Za-z0-9]');

  /// - empty: nothing typed
  /// - weak: shorter than 8 characters
  /// - fair: 8+ characters
  /// - strong: 8+ characters with a letter, a digit, and an uppercase letter
  ///   or symbol
  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    final isMixed =
        _letter.hasMatch(password) &&
        _digit.hasMatch(password) &&
        _upperOrSymbol.hasMatch(password);
    return isMixed ? PasswordStrength.strong : PasswordStrength.fair;
  }
}
