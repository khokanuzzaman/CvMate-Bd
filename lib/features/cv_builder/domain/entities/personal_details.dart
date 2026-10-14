import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';

/// A user-added "label: value" row, with its own visibility.
class DetailRow {
  const DetailRow({
    required this.id,
    this.label = '',
    this.value = '',
    this.visible = true,
  });

  factory DetailRow.empty() =>
      DetailRow(id: DateTime.now().microsecondsSinceEpoch.toString());

  final String id;
  final String label;
  final String value;
  final bool visible;

  bool get isEmpty => label.trim().isEmpty && value.trim().isEmpty;

  DetailRow copyWith({String? label, String? value, bool? visible}) =>
      DetailRow(
        id: id,
        label: label ?? this.label,
        value: value ?? this.value,
        visible: visible ?? this.visible,
      );
}

/// One printed "label: value" line.
class DetailEntry {
  const DetailEntry(this.label, this.value);
  final String label;
  final String value;
}

/// The optional personal details some markets expect. Kept apart from
/// `PersonalInfo` on purpose: nothing here is ever sent to the AI or read by the
/// ATS checker. Whether each one is printed is decided by `CvProfile.shownFields`
/// (and [DetailRow.visible] for custom rows).
class PersonalDetails {
  const PersonalDetails({
    this.dateOfBirth = '',
    this.nationality = '',
    this.passportNumber = '',
    this.passportExpiry = '',
    this.visaStatus = '',
    this.drivingLicence = '',
    this.maritalStatus = '',
    this.religion = '',
    this.gender = '',
    this.customRows = const [],
  });

  final String dateOfBirth;
  final String nationality;
  final String passportNumber;
  final String passportExpiry;
  final String visaStatus;
  final String drivingLicence;
  final String maritalStatus;
  final String religion;
  final String gender;
  final List<DetailRow> customRows;

  bool get isEmpty =>
      dateOfBirth.isEmpty &&
      nationality.isEmpty &&
      passportNumber.isEmpty &&
      passportExpiry.isEmpty &&
      visaStatus.isEmpty &&
      drivingLicence.isEmpty &&
      maritalStatus.isEmpty &&
      religion.isEmpty &&
      gender.isEmpty &&
      customRows.isEmpty;

  PersonalDetails copyWith({
    String? dateOfBirth,
    String? nationality,
    String? passportNumber,
    String? passportExpiry,
    String? visaStatus,
    String? drivingLicence,
    String? maritalStatus,
    String? religion,
    String? gender,
    List<DetailRow>? customRows,
  }) {
    return PersonalDetails(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      visaStatus: visaStatus ?? this.visaStatus,
      drivingLicence: drivingLicence ?? this.drivingLicence,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      religion: religion ?? this.religion,
      gender: gender ?? this.gender,
      customRows: customRows ?? this.customRows,
    );
  }

  /// What is stored for [field] ("number · expiry" for the passport). Empty for
  /// fields that are not a text value (photo, declaration, signature).
  String valueOf(PersonalField field) => switch (field) {
    PersonalField.dateOfBirth => dateOfBirth.trim(),
    PersonalField.nationality => nationality.trim(),
    PersonalField.passport => [
      passportNumber.trim(),
      passportExpiry.trim(),
    ].where((part) => part.isNotEmpty).join(' · '),
    PersonalField.visaStatus => visaStatus.trim(),
    PersonalField.drivingLicence => drivingLicence.trim(),
    PersonalField.maritalStatus => maritalStatus.trim(),
    PersonalField.religion => religion.trim(),
    PersonalField.gender => gender.trim(),
    _ => '',
  };

  static const List<PersonalField> _textFields = [
    PersonalField.dateOfBirth,
    PersonalField.nationality,
    PersonalField.passport,
    PersonalField.visaStatus,
    PersonalField.drivingLicence,
    PersonalField.maritalStatus,
    PersonalField.religion,
    PersonalField.gender,
  ];

  /// The lines to print: every shown, non-empty field in a fixed order, then the
  /// visible custom rows that have both a label and a value. [labelOf] gives the
  /// renderer's wording for a built-in field.
  List<DetailEntry> entries(
    Set<PersonalField> shown,
    String Function(PersonalField field) labelOf,
  ) {
    return [
      for (final field in _textFields)
        if (shown.contains(field) && valueOf(field).isNotEmpty)
          DetailEntry(labelOf(field), valueOf(field)),
      for (final row in customRows)
        if (row.visible &&
            row.label.trim().isNotEmpty &&
            row.value.trim().isNotEmpty)
          DetailEntry(row.label.trim(), row.value.trim()),
    ];
  }
}
