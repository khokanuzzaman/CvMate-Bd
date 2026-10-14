/// Which market a CV is written for. Choosing one only sets which personal
/// fields are shown by default (see [defaultFields]); it never deletes data, and
/// every field can still be toggled afterwards.
enum CvStyle {
  international,
  gulf,
  southAsia;

  static CvStyle? tryParse(Object? raw) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  /// International stays ATS-safe: no photo, no personal details, no
  /// declaration or signature.
  Set<PersonalField> get defaultFields => switch (this) {
    CvStyle.international => const {},
    CvStyle.gulf => const {
      PersonalField.photo,
      PersonalField.dateOfBirth,
      PersonalField.nationality,
      PersonalField.passport,
      PersonalField.visaStatus,
      PersonalField.drivingLicence,
    },
    CvStyle.southAsia => const {
      PersonalField.photo,
      PersonalField.dateOfBirth,
      PersonalField.nationality,
      PersonalField.maritalStatus,
      PersonalField.declaration,
      PersonalField.signature,
    },
  };
}

enum PaperSize {
  a4,
  letter;

  static PaperSize? tryParse(Object? raw) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

/// A personal detail (or block) with its own "show on CV" switch.
enum PersonalField {
  photo,
  dateOfBirth,
  nationality,
  passport,
  visaStatus,
  drivingLicence,
  maritalStatus,
  religion,
  gender,
  declaration,
  signature;

  static PersonalField? tryParse(Object? raw) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
