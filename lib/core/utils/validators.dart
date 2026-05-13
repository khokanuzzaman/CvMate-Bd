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

  static String? bangladeshPhone(String? value) {
    final requiredMessage = requiredText(value, fieldName: 'Phone number');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final normalized = value!.replaceAll(RegExp(r'\s+'), '');
    final pattern = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$');

    if (!pattern.hasMatch(normalized)) {
      return 'Use a valid Bangladesh phone number.';
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
