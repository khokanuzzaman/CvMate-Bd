import 'dart:convert';
import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';

/// The market-style part of a stored CV (schema 3): style, paper size, which
/// personal fields are shown, the details, declaration, photo and signature.
///
/// Reading never throws: anything missing or mistyped falls back to the old-CV
/// defaults (international, A4, nothing shown), which is also exactly what a
/// CV saved before schema 3 gets.
abstract final class CvMarketDto {
  static Map<String, dynamic> toMap(CvProfile profile) {
    return {
      'style': profile.style.name,
      'paperSize': profile.paperSize.name,
      'shownFields': [for (final field in profile.shownFields) field.name],
      if (!profile.details.isEmpty)
        'personalDetails': _detailsToMap(profile.details),
      'declaration': {
        'text': profile.declaration.text,
        'language': profile.declaration.language.name,
        'place': profile.declaration.place,
        'date': profile.declaration.date,
      },
      // Images travel inside the document (Hive JSON and Firestore share it);
      // they are a few tens of KB after cropping.
      if (profile.photo != null) 'photo': base64Encode(profile.photo!),
      if (profile.signature != null)
        'signature': base64Encode(profile.signature!),
    };
  }

  static CvProfile apply(CvProfile base, Map<String, dynamic> map) {
    final declaration = _map(map['declaration']);
    return CvProfile(
      id: base.id,
      title: base.title,
      personalInfo: base.personalInfo,
      professionalSummary: base.professionalSummary,
      careerObjective: base.careerObjective,
      education: base.education,
      experiences: base.experiences,
      skills: base.skills,
      projects: base.projects,
      trainings: base.trainings,
      languages: base.languages,
      template: base.template,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      sectionLayout: base.sectionLayout,
      customSections: base.customSections,
      style: CvStyle.tryParse(map['style']) ?? CvStyle.international,
      paperSize: PaperSize.tryParse(map['paperSize']) ?? PaperSize.a4,
      shownFields: _fields(map['shownFields']),
      details: _detailsFromMap(_map(map['personalDetails'])),
      declaration: CvDeclaration(
        text: _string(declaration?['text']),
        language:
            DeclarationLanguage.tryParse(declaration?['language']) ??
            DeclarationLanguage.english,
        place: _string(declaration?['place']),
        date: _string(declaration?['date']),
      ),
      photo: _bytes(map['photo']),
      signature: _bytes(map['signature']),
    );
  }

  static Map<String, dynamic> _detailsToMap(PersonalDetails details) => {
    'dateOfBirth': details.dateOfBirth,
    'nationality': details.nationality,
    'passportNumber': details.passportNumber,
    'passportExpiry': details.passportExpiry,
    'visaStatus': details.visaStatus,
    'drivingLicence': details.drivingLicence,
    'maritalStatus': details.maritalStatus,
    'religion': details.religion,
    'gender': details.gender,
    'customRows': [
      for (final row in details.customRows)
        {
          'id': row.id,
          'label': row.label,
          'value': row.value,
          'visible': row.visible,
        },
    ],
  };

  static PersonalDetails _detailsFromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PersonalDetails();
    }
    final rows = <DetailRow>[];
    final raw = map['customRows'];
    if (raw is List) {
      for (final (index, entry) in raw.indexed) {
        final row = _map(entry);
        if (row == null) {
          continue;
        }
        final id = _string(row['id']);
        rows.add(
          DetailRow(
            id: id.isEmpty ? 'row-$index' : id,
            label: _string(row['label']),
            value: _string(row['value']),
            visible: row['visible'] is bool ? row['visible'] as bool : true,
          ),
        );
      }
    }
    return PersonalDetails(
      dateOfBirth: _string(map['dateOfBirth']),
      nationality: _string(map['nationality']),
      passportNumber: _string(map['passportNumber']),
      passportExpiry: _string(map['passportExpiry']),
      visaStatus: _string(map['visaStatus']),
      drivingLicence: _string(map['drivingLicence']),
      maritalStatus: _string(map['maritalStatus']),
      religion: _string(map['religion']),
      gender: _string(map['gender']),
      customRows: rows,
    );
  }

  static Set<PersonalField> _fields(Object? raw) {
    if (raw is! List) {
      return const {};
    }
    return {for (final entry in raw) ?PersonalField.tryParse(entry)};
  }

  static String _string(Object? value) => value is String ? value : '';

  static Uint8List? _bytes(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  /// Firestore can hand nested maps back with looser key types.
  static Map<String, dynamic>? _map(Object? value) {
    if (value is! Map) {
      return null;
    }
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }
}
