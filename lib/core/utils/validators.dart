class Validators {
  const Validators._();

  static String? requiredText(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredMessage = requiredText(value, fieldName: 'Email');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final requiredMessage = requiredText(value, fieldName: 'Password');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value!.trim().length < minLength) {
      return 'Password must be at least $minLength characters.';
    }

    return null;
  }

  static String? confirmPassword(String? value, {required String password}) {
    final passwordMessage = password.isEmpty
        ? 'Password is required.'
        : Validators.password(password);
    if (passwordMessage != null) {
      return passwordMessage;
    }

    final requiredMessage = requiredText(value, fieldName: 'Confirm password');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value!.trim() != password.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  /// A phone number from any country (E.164-style): an optional leading `+`,
  /// then 7 to 15 digits. Spaces, dashes, dots and brackets may separate them,
  /// so `+880 1712-345678`, `01712345678` and `+971 50 123 4567` all pass.
  static String? phone(String? value) {
    final requiredMessage = requiredText(value, fieldName: 'Phone number');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final trimmed = value!.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    final onlyPhoneCharacters = RegExp(r'^\+?[\d\s\-.()]+$').hasMatch(trimmed);

    if (!onlyPhoneCharacters || digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number, e.g. +880 1712 345678.';
    }

    return null;
  }

  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final urlPattern = RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$');
    if (!urlPattern.hasMatch(value.trim())) {
      return 'Enter a valid URL.';
    }

    return null;
  }
}
